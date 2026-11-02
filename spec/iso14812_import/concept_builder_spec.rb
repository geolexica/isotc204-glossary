# frozen_string_literal: true

require "spec_helper"

RSpec.describe Iso14812Import::ConceptBuilder do
  let(:edition) do
    Iso14812Import::Edition.new(
      { id: "isotc204-ed3", urn: "urn:iso:std:iso:14812:ed3", year: 2026,
        ref: "ISO 14812", status: "current", owner: "ISO/TC 204",
        date_accepted: "2026-06-01" },
    )
  end

  def document(clause, name, relationships: [], specializations: [])
    Iso14812Import::Document.new(
      edition: edition, clause: clause, name: name, alt_names: [],
      definition_markdown: nil, examples: [], notes: [], sources: [],
      relationships: relationships, specializations: specializations,
      figures: [], breadcrumb_sections: [], history_notes: [],
    )
  end

  let(:entity) { document("3.1.1.1", "entity") }
  let(:vehicle) { document("3.7.3.1", "vehicle") }
  let(:material_entity) do
    document(
      "3.1.1.3", "material entity",
      relationships: [
        Iso14812Import::RawRelationship.new(predicate: "subClassOf", target_name: "entity", constraint: "entity"),
        Iso14812Import::RawRelationship.new(predicate: "involves", target_name: "owl::Thing", constraint: "min 2 owl::Thing"),
      ],
      specializations: [
        Iso14812Import::Specialization.new(target_name: "vehicle", description: "a vehicle"),
        Iso14812Import::Specialization.new(target_name: "vehicle", description: "a vehicle"),
      ],
    )
  end

  let(:index) { Iso14812Import::SourceIndex.build(edition, [entity, vehicle, material_entity]) }
  let(:figure_registry) { Iso14812Import::FigureRegistry.new(edition: edition) }
  let(:builder) do
    described_class.new(
      edition: edition,
      content_converter: Iso14812Import::ContentConverter.new(
        edition: edition, source_index: index, figure_registry: figure_registry,
      ),
      figure_registry: figure_registry,
      source_index: index,
    )
  end

  let(:related) { builder.build(material_entity).related }

  it "points relationships and specializations at clause ids" do
    ids = related.to_h { |r| [r.type, r.ref.id] }
    expect(ids).to include("broader" => "3.1.1.1", "narrower" => "3.7.3.1")
  end

  it "leaves a target with no concept without an id" do
    involves = related.find { |r| r.type == "related_concept" }
    expect(involves.ref.id).to be_nil
  end

  it "drops a specialization listed twice" do
    expect(related.count { |r| r.type == "narrower" }).to eq(1)
  end
end
