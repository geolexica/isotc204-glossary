# frozen_string_literal: true

require "fileutils"
require "open3"

module Iso14812Import
  class Pipeline
    attr_reader :edition, :previous_edition, :output_root

    def initialize(edition_config_path:, output_root: "datasets",
                   previous_edition_config_path: nil, config_root: default_config_root)
      @edition = Edition.load(edition_config_path)
      @config_root = config_root
      @previous_edition = resolve_previous(previous_edition_config_path)
      @output_root = output_root
    end

    def run
      RelationshipMapper.validate!
      documents = parse_pass
      index = SourceIndex.build(edition, documents)
      figure_registry = FigureRegistry.new(edition: edition)
      content_converter = ContentConverter.new(
        edition: edition, source_index: index, figure_registry: figure_registry,
      )
      builder = ConceptBuilder.new(
        edition: edition,
        content_converter: content_converter,
        figure_registry: figure_registry,
      )
      bibliography = BibliographyBuilder.new

      concepts = documents.map do |doc|
        register_bibliography(bibliography, doc)
        builder.build(doc)
      end

      supersedes_summary = previous_edition ? derive_supersedes(concepts) : nil

      writer = Writer.new(edition: edition, output_root: output_root)
      writer.write_register
      written = writer.write_concepts(concepts)
      figs = writer.write_figures(figure_registry)
      bib = writer.write_bibliography(bibliography.each_entry.to_a)

      validation = run_validation

      PipelineSummary.new(
        edition_id: edition.id,
        previous_edition_id: previous_edition&.id,
        concepts_written: written,
        figures_written: figs,
        bibliography_written: bib,
        supersedes_edges: supersedes_summary&.fetch(:forward_edges),
        withdrawn_marked: supersedes_summary&.fetch(:withdrawn_marked),
        validation_passed: validation[:passed],
        validation_output: validation[:output],
      )
    end

    private

    def parse_pass
      parser_for(edition).documents
    end

    def parser_for(an_edition)
      case an_edition.parser_kind
      when "xml"
        path = resolve_xml_source(an_edition)
        Parsers::XmlParser.new(edition: an_edition, io_or_path: path)
      when "markdown"
        path = resolve_markdown_source(an_edition)
        Parsers::MarkdownParser.new(edition: an_edition, terms_dir: path)
      when "yaml_dir"
        Parsers::YamlDirParser.new(edition: an_edition,
                                    dataset_path: File.join(output_root, an_edition.id))
      when "none", nil
        raise ArgumentError, "Edition #{an_edition.id} has no parser configured"
      else
        raise ArgumentError, "Unknown parser kind: #{an_edition.parser_kind}"
      end
    end

    def resolve_xml_source(an_edition)
      override = an_edition.source[:local_override] || an_edition.source["local_override"]
      return override if override && File.exist?(override)

      extracted = GitSource.extract(
        repo: an_edition.source_repo_path,
        ref: an_edition.source_ref,
        path: an_edition.vocabulary_path,
      )
      extracted || File.join(an_edition.source_repo_path.to_s, an_edition.vocabulary_path.to_s)
    end

    def resolve_markdown_source(an_edition)
      base = an_edition.source_repo_path || "."
      sub = an_edition.terms_dir || "docs/terms"
      File.join(base, sub)
    end

    def resolve_previous(path)
      return nil unless path
      Edition.load(path)
    end

    def derive_supersedes(newer_concepts)
      older_documents = parse_previous_documents(previous_edition)
      older_index = SourceIndex.build(previous_edition, older_documents)

      older_builder = make_builder(previous_edition, older_index)
      older_concepts = older_documents.map { |d| older_builder.build(d) }

      deriver = SupersedesDeriver.new(
        newer_edition: edition, older_edition: previous_edition,
        newer_concepts: newer_concepts, older_concepts: older_concepts,
      )
      deriver.derive!
    end

    def parse_previous_documents(prev_edition)
      parser_for(prev_edition).documents
    end

    def make_builder(an_edition, index)
      fig_reg = FigureRegistry.new(edition: an_edition)
      conv = ContentConverter.new(
        edition: an_edition, source_index: index, figure_registry: fig_reg,
      )
      ConceptBuilder.new(edition: an_edition, content_converter: conv, figure_registry: fig_reg)
    end

    def register_bibliography(bib, doc)
      (doc.sources || []).each { |s| bib.register(s.raw_text) }
    end

    def run_validation
      dataset_path = File.join(output_root, edition.id)
      return { passed: true, output: "" } unless File.directory?(dataset_path)

      out, status = Open3.capture2e("glossarist", "validate", dataset_path)
      { passed: status.success?, output: out }
    rescue StandardError => e
      { passed: false, output: e.message }
    end

    def default_config_root
      File.expand_path("../config/editions", __dir__)
    end
  end

  module GitSource
    def self.extract(repo:, ref:, path:)
      return nil if repo.nil? || ref.nil? || path.nil?
      return nil unless File.directory?(repo)

      out, status = Open3.capture2e("git", "-C", repo, "show", "#{ref}:#{path}")
      return nil unless status.success?

      tmp = Tempfile.create(File.basename(path))
      tmp.write(out)
      tmp.close
      tmp.path
    rescue StandardError
      nil
    end
  end
end
