# frozen_string_literal: true

module Iso14812Import
  module Parsers
    class MarkdownParser < Base
      def initialize(edition:, terms_dir:)
        @edition = edition
        @terms_dir = terms_dir
      end

      def each_document
        return enum_for(:each_document) unless block_given?

        term_files.each do |path|
          doc = MarkdownFileParser.new(edition: @edition, path: path).parse
          yield doc if doc
        end
      end

      private

      def term_files = Dir[File.join(@terms_dir, "*.md")].sort
    end

    class MarkdownFileParser
      CLAUSE_RE       = /^Clause:\s*(.+)$/.freeze
      ALT_TERM_RE     = /^Alternative preferred term:\s*(.+)$/.freeze
      NOTE_RE         = /^Note\s+\d+\s+to entry:\s*(.+)$/.freeze
      EXAMPLE_RE      = /^EXAMPLE:\s*(.+)$/.freeze
      HISTORY_RE      = /^History note:\s*(.+)$/.freeze
      SECTION_H1_RE   = /^#\s+(.+)$/.freeze
      SPEC_HEAD_RE    = /^##\s+Specializations of /.freeze
      REL_HEAD_RE     = /^##\s+Relationships for /.freeze
      REFS_HEAD_RE    = /^##\s+References to /.freeze
      OBJECT_OPEN_RE  = /^<object\b/.freeze
      OBJECT_CLOSE_RE = %r{</object>}.freeze
      HR_RE           = /^---\s*$/.freeze

      attr_reader :edition, :path

      def initialize(edition:, path:)
        @edition = edition
        @path = path
      end

      def parse
        lines = File.readlines(path, chomp: true)
        body = strip_breadcrumb_and_footer(lines)
        # Trigger autoload of Document (which also defines HistoryNote,
        # Specialization, RawRelationship, SourceCitation).
        Iso14812Import::Document
        build_document(body)
      end

      private

      def strip_breadcrumb_and_footer(lines)
        return [] if lines.empty?

        body = lines[1..] || []
        body = body[0..-2] while body.last&.start_with?("[Comment on this page]")
        body = body[0..-2] while body.last&.match?(HR_RE)
        body = body[0..-2] while body.last&.strip&.empty?
        body
      end

      def build_document(body)
        s = Splitter.new(body)
        # Files without a Clause line (e.g. concept_registry.md) are not
        # term definitions — return nil so each_document skips them.
        return nil unless s.clause

        Document.new(
          edition: edition,
          clause: s.clause,
          guid: nil,
          name: s.title,
          alt_names: s.alt_names,
          definition_html: nil,
          definition_markdown: s.definition,
          examples: s.examples,
          notes: s.notes,
          sources: [],
          relationships: s.relationships,
          specializations: s.specializations,
          figures: s.figures,
          breadcrumb_sections: [],
          history_notes: s.history_notes,
        )
      end

      # Single-pass state machine over body lines. Owns its own state,
      # produces all extracted fields as attrs.
      #
      # Recognized line shapes (in any reasonable order):
      #   # Title                         -> title
      #   <object ...> ... </object>      -> figure reference (multi-line block)
      #   Clause: 3.1.1.1                 -> clause
      #   Alternative preferred term: X   -> alt_names
      #   Note N to entry: text           -> notes
      #   EXAMPLE: text                   -> examples
      #   History note: text              -> history_notes
      #   ## Specializations of X + table -> specializations
      #   ## Relationships for X + table  -> relationships
      #   anything else (in body)         -> definition prose
      class Splitter
        attr_reader :title, :clause, :alt_names, :examples,
                    :notes, :history_notes, :relationships, :specializations,
                    :figures

        def initialize(body)
          @state = :prologue
          @title = nil
          @clause = nil
          @alt_names = []
          @definition_lines = []
          @examples = []
          @notes = []
          @history_notes = []
          @relationships = []
          @specializations = []
          @figures = []
          @table_buffer = nil
          @table_kind = nil
          @in_object_block = false
          @object_buffer = nil
          run(body)
        end

        def definition
          @definition_lines.join("\n").strip
        end

        private

        def run(body)
          body.each { |line| process(line.strip, line) }
          flush_table if @table_buffer
          # An unterminated <object> block at EOF is malformed; drop it.
          @object_buffer = nil
        end

        def process(stripped, _original)
          if @in_object_block
            handle_object_block_state(stripped)
            return
          end

          if (m = stripped.match(SECTION_H1_RE)) && @state == :prologue
            @title = m[1].strip
            @state = :body
            return
          end

          return if stripped.empty? && !@table_buffer

          if @table_buffer
            handle_table_line(stripped)
            return
          end

          return if handle_object_open(stripped)

          if (m = stripped.match(CLAUSE_RE))
            @clause = m[1].strip
            return
          end

          if (m = stripped.match(ALT_TERM_RE))
            @alt_names.concat(split_alt_terms(m[1]))
            return
          end

          if (m = stripped.match(NOTE_RE))
            @notes << m[1].strip
            return
          end

          if (m = stripped.match(EXAMPLE_RE))
            @examples << m[1].strip
            return
          end

          if (m = stripped.match(HISTORY_RE))
            @history_notes << parse_history_note(m[1].strip)
            return
          end

          if SPEC_HEAD_RE.match?(stripped)
            start_table(:specialization)
            return
          end

          if REL_HEAD_RE.match?(stripped)
            start_table(:relationship)
            return
          end

          # "## References to X" is a reverse-relationship table — concepts
          # that point at the current concept. We skip it because the data
          # is derivable from forward relationships in those other concepts,
          # and the v3 model has no native "referenced-by" authoring.
          if REFS_HEAD_RE.match?(stripped)
            start_table(:skip)
            return
          end

          return if stripped.empty?
          return if hr_or_footer?(stripped)
          return unless definition_captureable?(stripped)

          @definition_lines << stripped
        end

        def handle_object_open(stripped)
          return false unless OBJECT_OPEN_RE.match?(stripped)

          @in_object_block = true
          @object_buffer = [stripped]
          # If the open tag line also contains the close tag, terminate
          # the block immediately (single-line <object ...></object>).
          finish_object_block if OBJECT_CLOSE_RE.match?(stripped)
          true
        end

        def handle_object_block_state(stripped)
          @object_buffer << stripped
          finish_object_block if OBJECT_CLOSE_RE.match?(stripped)
        end

        def finish_object_block
          @figures << Iso14812Import::FigureRef.new(
            src: extract_object_src(@object_buffer),
            alt: extract_object_alt(@object_buffer),
            caption: nil,
          )
          @in_object_block = false
          @object_buffer = nil
        end

        def extract_object_src(lines)
          lines.flat_map { |l| l.scan(/src=["']([^"']+)["']/) }.flatten.first
        end

        def extract_object_alt(lines)
          lines.flat_map { |l| l.scan(/alt=["']([^"']+)["']/) }.flatten.first
        end

        def handle_table_line(stripped)
          if stripped.empty?
            # blank line inside a table region — keep collecting
            return
          end

          if stripped.start_with?("|")
            @table_buffer << stripped
          else
            flush_table
            process(stripped, stripped)
          end
        end

        def start_table(kind)
          @table_buffer = []
          @table_kind = kind
        end

        def flush_table
          return unless @table_buffer

          rows = parse_markdown_table(@table_buffer)
          case @table_kind
          when :specialization
            rows.each { |row| @specializations << Iso14812Import::Specialization.new(target_name: row[0], description: row[1]) }
          when :relationship
            rows.each { |row| @relationships << Iso14812Import::RawRelationship.new(predicate: row[0], target_name: nil, constraint: row[1], description: nil) }
          when :skip
            # "## References to X" table — reverse relationships; data is
            # derivable from forward relationships in other concepts.
          end
          @table_buffer = nil
          @table_kind = nil
        end

        def definition_captureable?(stripped)
          return false if stripped.match?(CLAUSE_RE)
          return false if stripped.match?(ALT_TERM_RE)
          return false if stripped.match?(NOTE_RE)
          return false if stripped.match?(EXAMPLE_RE)
          return false if stripped.match?(HISTORY_RE)
          return false if stripped.start_with?("Note ")
          return false if stripped.start_with?("EXAMPLE:")
          return false if stripped.start_with?("History note:")
          return false if stripped.start_with?("<object")
          return false if OBJECT_CLOSE_RE.match?(stripped)
          return false if stripped.start_with?("#")
          return false if SPEC_HEAD_RE.match?(stripped)
          return false if REL_HEAD_RE.match?(stripped)
          true
        end

        def hr_or_footer?(stripped)
          return true if stripped.match?(HR_RE)
          return true if stripped.start_with?("[Comment on this page]")
          false
        end

        def split_alt_terms(text)
          text.split(/,|;|\bor\b/i).map(&:strip).reject(&:empty?)
        end

        def parse_markdown_table(rows)
          return [] if rows.length < 2

          rows[2..].filter_map do |row|
            cells = row.split("|").map(&:strip).reject(&:empty?)
            cells.empty? ? nil : cells
          end
        end

        def parse_history_note(text)
          if (m = text.match(/^(\d{4}):\s*(.+)$/))
            year = m[1].to_i
            body = m[2]
            kind = classify_history(body)
            Iso14812Import::HistoryNote.new(year: year, kind: kind, text: text)
          else
            kind = classify_history(text)
            Iso14812Import::HistoryNote.new(year: nil, kind: kind, text: text)
          end
        end

        def classify_history(body)
          case body.downcase
          when /^introduced/, /introduced in/i then :introduced
          when /^revised/, /^modified/, /^updated/ then :revised
          when /^withdrawn/, /^removed/, /^deleted/ then :withdrawn
          else :other
          end
        end
      end
    end
  end
end
