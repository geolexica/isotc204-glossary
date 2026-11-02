# frozen_string_literal: true

require "spec_helper"

RSpec.describe Iso14812Import::SourceIndex do
  let(:edition) { instance_double("Iso14812Import::Edition", id: "test") }

  let(:docs) do
    [
      Iso14812Import::Document.new(
        edition: edition, clause: "3.1.1.5", guid: "GUID1", name: "Entity",
        alt_names: [], definition_html: nil, definition_markdown: "def",
        examples: [], notes: [], sources: [], relationships: [],
        specializations: [], figures: [], breadcrumb_sections: [],
        history_notes: [],
      ),
      Iso14812Import::Document.new(
        edition: edition, clause: "3.1.1.1", guid: "GUID2", name: "Other",
        alt_names: [], definition_html: nil, definition_markdown: "def",
        examples: [], notes: [], sources: [], relationships: [],
        specializations: [], figures: [], breadcrumb_sections: [],
        history_notes: [],
      ),
    ]
  end

  let(:index) { described_class.build(edition, docs) }

  describe ".build" do
    it "builds by_clause, by_name, by_guid maps" do
      expect(index.by_clause.keys).to contain_exactly("3.1.1.5", "3.1.1.1")
      expect(index.by_name.keys).to contain_exactly("entity", "other")
      expect(index.by_guid.keys).to contain_exactly("GUID1", "GUID2")
    end
  end

  describe "#lookup" do
    it "finds by clause" do
      expect(index.lookup(clause: "3.1.1.5").name).to eq("Entity")
    end

    it "finds by name (case-insensitive)" do
      expect(index.lookup(name: "ENTITY").name).to eq("Entity")
    end

    it "finds by guid" do
      expect(index.lookup(guid: "GUID1").clause).to eq("3.1.1.5")
    end

    it "returns nil when nothing matches" do
      expect(index.lookup(clause: "999")).to be_nil
    end

    it "returns nil when called with no args" do
      expect(index.lookup).to be_nil
    end
  end

  describe "#clause_for" do
    let(:docs) do
      [
        Iso14812Import::Document.new(
          edition: edition, clause: "3.1.1.3", name: "material entity",
          alt_names: [], examples: [], notes: [], sources: [], relationships: [],
          specializations: [], figures: [], breadcrumb_sections: [], history_notes: [],
        ),
        Iso14812Import::Document.new(
          edition: edition, clause: "3.7.3.15", name: "ADS-equipped vehicle",
          alt_names: [], examples: [], notes: [], sources: [], relationships: [],
          specializations: [], figures: [], breadcrumb_sections: [], history_notes: [],
        ),
      ]
    end

    it "resolves a link label" do
      expect(index.clause_for("ADS-equipped vehicle")).to eq("3.7.3.15")
    end

    it "resolves an OWL class name" do
      expect(index.clause_for("materialEntity")).to eq("3.1.1.3")
      expect(index.clause_for("adsEquippedVehicle")).to eq("3.7.3.15")
    end

    it "returns nil for a class with no concept" do
      expect(index.clause_for("owl::Thing")).to be_nil
      expect(index.clause_for(nil)).to be_nil
    end
  end

  describe "#clauses, #names, #size" do
    it "returns the expected sets" do
      expect(index.clauses).to contain_exactly("3.1.1.5", "3.1.1.1")
      expect(index.names).to contain_exactly("entity", "other")
      expect(index.size).to eq(2)
    end
  end
end
