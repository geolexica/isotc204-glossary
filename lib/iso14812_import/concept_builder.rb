# frozen_string_literal: true

module Iso14812Import
  class ConceptBuilder
    LANGUAGE_ENG = "eng"

    # Use the V3 class hierarchy — the glossarist gem's validator loads
    # concepts via V3::ConceptDocument, which produces V3::ManagedConcept
    # instances. Building with the top-level (legacy) classes produces
    # files that lose UUID-vs-identifier distinction on round-trip.
    V3 = Glossarist::V3

    attr_reader :edition, :content_converter, :figure_registry

    def initialize(edition:, content_converter:, figure_registry:)
      @edition = edition
      @content_converter = content_converter
      @figure_registry = figure_registry
    end

    def build(document)
      localized = build_localized(document)
      managed_data = V3::ManagedConceptData.new(
        id: document.clause,
        localized_concepts: { LANGUAGE_ENG => localized.uuid },
        domains: domain_refs(document),
        sources: [],
      )
      managed_data.localizations.store(LANGUAGE_ENG, localized)

      V3::ManagedConcept.new(
        data: managed_data,
        status: "valid",
        schema_version: edition.schema_version,
        related: build_related(document),
        uuid: deterministic_uuid(document.clause),
        date_accepted: date_accepted_for(document),
      )
    end

    private

    def build_localized(document)
      concept_data = V3::ConceptData.new(
        language_code: LANGUAGE_ENG,
        entry_status: "valid",
        terms: build_designations(document),
        definition: build_definition(document),
        examples: build_detailed(document.examples, document),
        notes: build_detailed(document.notes, document),
        sources: build_sources(document),
      )

      V3::LocalizedConcept.new(
        data: concept_data,
        language_code: LANGUAGE_ENG,
        entry_status: "valid",
        uuid: deterministic_uuid("#{document.clause}-eng"),
      )
    end

    def build_designations(document)
      preferred = [Glossarist::Designation::Expression.new(
        designation: document.name,
        normative_status: "preferred",
        type: "expression",
      )]
      admitted = Array(document.alt_names).map do |alt|
        Glossarist::Designation::Expression.new(
          designation: alt,
          normative_status: "admitted",
          type: "expression",
        )
      end
      preferred + admitted
    end

    def build_definition(document)
      return [] unless document.has_definition?

      content = if document.definition_html
                   content_converter.from_html(document.definition_html)
                 else
                   content_converter.from_markdown(document.definition_markdown)
                 end
      [V3::DetailedDefinition.new(content: content)]
    end

    def build_detailed(items, document)
      Array(items).map do |text|
        V3::DetailedDefinition.new(content: convert_text(text, document))
      end
    end

    def convert_text(text, document)
      return text if text.nil? || text.strip.empty?

      document.definition_html ? content_converter.from_html(text)
                                : content_converter.from_markdown(text)
    end

    def build_sources(document)
      Array(document.sources).filter_map do |raw|
        parsed = SourceParser.parse(raw.raw_text)
        next nil if parsed.nil?

        V3::ConceptSource.new(
          type: parsed[:type],
          status: parsed[:status],
          origin: build_citation(parsed[:origin]),
          modification: parsed[:modification],
        )
      end
    end

    def build_citation(origin_attrs)
      return nil if origin_attrs.nil?

      ref_attrs = origin_attrs[:ref]
      ref = ref_attrs ? V3::Citation::Ref.new(source: ref_attrs[:source]) : nil
      locality_attrs = origin_attrs[:locality]
      locality = locality_attrs ? Glossarist::Locality.new(
        type: locality_attrs[:type] || "clause",
        reference_from: locality_attrs[:reference_from],
      ) : nil

      V3::Citation.new(ref: ref, locality: locality)
    end

    def build_related(document)
      rels = Array(document.relationships).map do |raw|
        attrs = RelationshipMapper.map(
          raw.predicate,
          target_clause: raw.target_name,
          edition_urn: edition.urn,
          description: raw.description,
          constraint: raw.constraint,
        )
        ref_hash = attrs.delete(:ref) || {}
        attrs[:ref] = Glossarist::V3::ConceptRef.new(source: ref_hash[:source], id: ref_hash[:id])
        V3::RelatedConcept.new(**attrs)
      end

      specs = Array(document.specializations).map do |spec|
        V3::RelatedConcept.new(
          type: "narrower",
          ref: Glossarist::V3::ConceptRef.new(source: edition.urn, id: spec.target_name),
          content: spec.description,
        )
      end

      rels + specs
    end

    def domain_refs(document)
      leaf = Array(document.breadcrumb_sections).last
      return [] unless leaf

      [Glossarist::ConceptReference.section(leaf).tap { |r| r.source = edition.urn }]
    end

    def date_accepted_for(_document)
      date_str = edition.date_accepted || Date.today.iso8601
      date = begin
               Date.parse(date_str.to_s)
             rescue Date::Error
               Date.today
             end
      V3::ConceptDate.new(date: date, type: "accepted")
    end

    def deterministic_uuid(name)
      DeterministicUuid.for_edition_and_name(edition.urn, name)
    end
  end
end
