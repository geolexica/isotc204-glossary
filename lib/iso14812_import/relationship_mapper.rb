# frozen_string_literal: true

module Iso14812Import
  class RelationshipMapper
    PREDICATE_MAP = {
      "subClassOf"         => { type: "broader" },
      "superClassOf"       => { type: "narrower" },
      "partOf"             => { type: "is_part_of" },
      "hasPart"            => { type: "has_part" },
      "hasInstance"        => { type: "has_instance" },
      "instanceOf"         => { type: "instance_of" },
      "references"         => { type: "references" },
      "replaces"           => { type: "replaces" },
      "replacedBy"         => { type: "replaced_by" },
      "see"                => { type: "see" },
      "compare"            => { type: "compare" },
      "contrast"           => { type: "contrast" },
      "relatedConcept"     => { type: "related_concept" },
      "broaderGeneric"     => { type: "broader_generic" },
      "narrowerGeneric"    => { type: "narrower_generic" },
      "broaderPartitive"   => { type: "broader_partitive" },
      "narrowerPartitive"  => { type: "narrower_partitive" },
      "broaderInstantial"  => { type: "broader_instantial" },
      "narrowerInstantial" => { type: "narrower_instantial" },
    }.freeze

    FALLBACK_TYPE = "related_concept"

    def self.map(raw_predicate, target_clause:, edition_urn:, description: nil, constraint: nil)
      mapped = PREDICATE_MAP.fetch(normalize_predicate(raw_predicate)) do
        { type: FALLBACK_TYPE }
      end

      hash = {
        type: mapped.fetch(:type),
        ref: { source: edition_urn, id: target_clause },
      }
      content = compose_content(raw_predicate, description, constraint)
      hash[:content] = content if content
      hash
    end

    def self.validate!
      return if @validated

      allowed = Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES
      bad = PREDICATE_MAP.values.map { |h| h[:type] }.uniq - allowed
      raise "PREDICATE_MAP has invalid v3 types: #{bad.inspect}" unless bad.empty?

      @validated = true
    end

    class << self
      private

      def normalize_predicate(p)
        p.to_s.strip
      end

      def compose_content(raw_predicate, description, constraint)
        parts = []
        parts << raw_predicate.to_s
        parts << "[#{constraint}]" if constraint && !constraint.strip.empty?
        parts << description if description && !description.strip.empty?
        parts.empty? ? nil : parts.join(" ")
      end
    end
  end
end
