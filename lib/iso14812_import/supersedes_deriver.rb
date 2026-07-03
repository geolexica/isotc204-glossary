# frozen_string_literal: true

require "set"

module Iso14812Import
  class SupersedesDeriver
    V3 = Glossarist::V3

    attr_reader :newer_edition, :older_edition, :newer_concepts, :older_concepts

    def initialize(newer_edition:, older_edition:, newer_concepts:, older_concepts:)
      @newer_edition = newer_edition
      @older_edition = older_edition
      @newer_concepts = newer_concepts
      @older_concepts = older_concepts
      @older_clauses_seen = Set.new
    end

    def derive!
      derive_forward_edges
      mark_withdrawn_older_concepts
      summary
    end

    private

    def derive_forward_edges
      newer_concepts.each do |newer|
        clause = newer.data.id
        older = older_by_clause[clause]
        next unless older

        newer.related << supersedes_edge(clause)
        set_similarity(newer, older)
        @older_clauses_seen << clause
      end
    end

    def mark_withdrawn_older_concepts
      older_concepts.each do |older|
        clause = older.data.id
        next if @older_clauses_seen.include?(clause)
        next if older.status == "superseded"

        older.status = "superseded"
      end
    end

    def supersedes_edge(clause)
      V3::RelatedConcept.new(
        type: "supersedes",
        ref: Glossarist::V3::ConceptRef.new(source: older_edition.urn, id: clause),
      )
    end

    def set_similarity(newer, older)
      return unless comparator_available?

      similarity = begin
                     comparison = comparator.compare(older, newer)
                     similarity_from(comparison)
                   rescue StandardError
                     nil
                   end
      return if similarity.nil?

      newer.data.localizations["eng"]&.data&.lineage_source_similarity = similarity
    end

    def comparator_available?
      Glossarist.const_defined?(:ConceptComparator)
    end

    def comparator
      @comparator ||= Glossarist::ConceptComparator.new
    end

    def similarity_from(comparison)
      return comparison.similarity if comparison.is_a?(Glossarist::ComparisonResult) && comparison.respond_to?(:similarity)
      return comparison[:similarity] if comparison.is_a?(Hash) && comparison.key?(:similarity)
      nil
    end

    def older_by_clause
      @older_by_clause ||= older_concepts.each_with_object({}) do |c, h|
        h[c.data.id] = c
      end
    end

    def summary
      {
        forward_edges: @older_clauses_seen.size,
        withdrawn_marked: older_concepts.count { |c| c.status == "superseded" },
      }
    end
  end
end
