# frozen_string_literal: true

require "yaml"

module Iso14812Import
  module Parsers
    # Reads already-generated concept files from disk. Used for editions that
    # have no upstream parser (e.g. E1, which was imported manually and lives
    # on disk as YAML). Produces Document IRs with just enough fields
    # (clause, name) for cross-edition index lookups.
    class YamlDirParser < Base
      def initialize(edition:, dataset_path:)
        @edition = edition
        @dataset_path = dataset_path
      end

      def each_document
        return enum_for(:each_document) unless block_given?

        concept_files.each do |path|
          doc = parse_one(path)
          yield doc if doc
        end
      end

      private

      def concept_files
        Dir[File.join(@dataset_path, "concepts", "*.yaml")].sort
      end

      def parse_one(path)
        text = File.read(path)
        docs = YAML.load_stream(text)
        managed = docs.find { |d| d.is_a?(Hash) && d["data"] }
        return nil unless managed

        data = managed["data"] || {}
        localized_id = (data["localized_concepts"] || {})["eng"]
        localized = docs.find { |d| d.is_a?(Hash) && d["id"] == localized_id }

        Document.new(
          edition: @edition,
          clause: data["identifier"],
          guid: nil,
          name: term_designation(localized),
          alt_names: [],
          definition_html: nil,
          definition_markdown: nil,
          examples: [],
          notes: [],
          sources: [],
          relationships: [],
          specializations: [],
          figures: [],
          breadcrumb_sections: domain_clauses(data),
          history_notes: [],
        )
      end

      def term_designation(localized)
        terms = localized && localized["data"] && localized["data"]["terms"]
        preferred = Array(terms).find { |t| t["normative_status"] == "preferred" }
        preferred && preferred["designation"]
      end

      def domain_clauses(data)
        Array(data["domains"]).map { |d| d["concept_id"] if d["ref_type"] == "section" }.compact
      end
    end
  end
end
