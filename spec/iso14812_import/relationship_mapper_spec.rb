# frozen_string_literal: true

require "spec_helper"

RSpec.describe Iso14812Import::RelationshipMapper do
  let(:edition_urn) { "urn:iso:std:iso:14812:2025" }
  let(:target_clause) { "3.1.1.5" }

  describe ".map" do
    it "maps subClassOf to broader" do
      result = described_class.map("subClassOf", target_clause: target_clause, edition_urn: edition_urn)
      expect(result[:type]).to eq("broader")
      expect(result[:ref]).to eq(source: edition_urn, id: target_clause)
    end

    it "preserves unknown predicate as content on related_concept" do
      result = described_class.map("canControl", target_clause: target_clause, edition_urn: edition_urn)
      expect(result[:type]).to eq("related_concept")
      expect(result[:content]).to include("canControl")
    end

    it "includes description in content when provided" do
      result = described_class.map(
        "performsAllOf", target_clause: target_clause, edition_urn: edition_urn,
        description: "completes the entire DDT",
      )
      expect(result[:content]).to include("completes the entire DDT")
    end

    it "includes constraint in content when provided" do
      result = described_class.map(
        "involves", target_clause: target_clause, edition_urn: edition_urn,
        constraint: "min 2",
      )
      expect(result[:content]).to include("[min 2]")
    end
  end

  describe ".validate!" do
    it "passes when all PREDICATE_MAP types are valid v3 types" do
      expect { described_class.validate! }.not_to raise_error
    end
  end
end
