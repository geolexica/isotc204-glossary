# frozen_string_literal: true

require "nokogiri"

module Iso14812Import
  module Parsers
    class XmlParser < Base
      def initialize(edition:, io_or_path:)
        @edition = edition
        @io_or_path = io_or_path
      end

      def each_document
        return enum_for(:each_document) unless block_given?

        XmlWalker.new(edition: @edition, io_or_path: @io_or_path).walk do |doc|
          yield doc
        end
      end
    end

    class XmlWalker
      FIGURE_SRC_RE = /src=["']([^"']+)["']/.freeze
      FIGURE_ALT_RE = /alt=["']([^"']+)["']/.freeze

      attr_reader :edition, :io_or_path

      def initialize(edition:, io_or_path:)
        @edition = edition
        @io_or_path = io_or_path
      end

      def walk(&block)
        # Trigger autoload of Document (which also defines FigureRef,
        # SourceCitation, etc.) before walking begins.
        Iso14812Import::Document
        doc = Nokogiri::XML(read_source) { |config| config.strict }
        walk_packages(doc.root, breadcrumbs: [], figures: [], &block) if doc.root
      end

      private

      def read_source
        return @io_or_path.read if @io_or_path.respond_to?(:read)

        File.read(@io_or_path, encoding: "utf-8")
      end

      # Figures accumulate as we descend through packages. Each <figure>
      # element inside a <package> is collected and attached to every
      # <term> in that package (and sub-packages, via propagation through
      # the figures argument).
      def walk_packages(element, breadcrumbs:, figures:, &block)
        section = section_from(element, breadcrumbs)
        new_breadcrumbs = section ? breadcrumbs + [section.clause] : breadcrumbs
        new_figures = figures + collect_figures(element)

        element.children.each do |child|
          local_name = local_name(child)
          case local_name
          when "package"
            walk_packages(child, breadcrumbs: new_breadcrumbs,
                                 figures: new_figures, &block)
          when "term"
            build_and_yield(child, new_breadcrumbs, new_figures, &block)
          end
        end
      end

      def collect_figures(package_element)
        package_element.children
          .select { |c| local_name(c) == "figure" }
          .filter_map { |f| build_figure_ref(f) }
      end

      def build_figure_ref(figure_element)
        img_html = cdata_of(figure_element, "img") ||
          text_of(figure_element, "img")
        return nil unless img_html

        src = img_html[FIGURE_SRC_RE, 1]
        return nil unless src

        Iso14812Import::FigureRef.new(
          src: src,
          alt: img_html[FIGURE_ALT_RE, 1],
          caption: text_of(figure_element, "name"),
        )
      end

      def build_and_yield(term_element, breadcrumbs, figures)
        document = build_document(term_element, breadcrumbs, figures)
        yield document if document.valid?
      end

      def build_document(term_element, breadcrumbs, figures)
        Document.new(
          edition: edition,
          clause: text_of(term_element, "clause"),
          guid: text_of(term_element, "guid"),
          name: text_of(term_element, "name"),
          alt_names: [],
          definition_html: cdata_of(term_element, "definition"),
          definition_markdown: nil,
          examples: texts_of(term_element, "example"),
          notes: texts_of(term_element, "note"),
          sources: source_texts_of(term_element).map { |s| SourceCitation.new(raw_text: s) },
          relationships: [],
          specializations: [],
          figures: figures,
          breadcrumb_sections: breadcrumbs,
          history_notes: [],
        )
      end

      def section_from(element, parent_breadcrumbs)
        clause = text_of(element, "clause")
        return nil unless clause

        DocumentSection.new(
          clause: clause,
          name: text_of(element, "name"),
          parent_clause: parent_breadcrumbs.last,
        )
      end

      def local_name(node)
        node.name.split(":", 2).last
      end

      def text_of(parent, child_name)
        child = parent.children.find { |c| local_name(c) == child_name }
        child&.content&.strip
      end

      def cdata_of(parent, child_name)
        child = parent.children.find { |c| local_name(c) == child_name }
        return nil unless child

        child.content.strip
      end

      def texts_of(parent, child_name)
        parent.children.select { |c| local_name(c) == child_name }
               .map { |c| c.content.strip }
      end

      def source_texts_of(term_element)
        texts_of(term_element, "source")
      end
    end
  end
end
