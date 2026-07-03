# frozen_string_literal: true

require "spec_helper"

RSpec.describe Iso14812Import::Document do
  let(:edition) { instance_double("Iso14812Import::Edition") }

  describe ".new (struct defaults)" do
    it "accepts all fields as keyword args" do
      doc = described_class.new(
        edition: edition, clause: "3.1.1.5", guid: "GUID1", name: "entity",
        alt_names: [], definition_html: "<p>text</p>", definition_markdown: nil,
        examples: [], notes: [], sources: [], relationships: [], specializations: [],
        figures: [], breadcrumb_sections: ["3", "3.1", "3.1.1"],
        history_notes: [],
      )
      expect(doc.clause).to eq("3.1.1.5")
      expect(doc.name).to eq("entity")
      expect(doc.breadcrumb_sections.last).to eq("3.1.1")
    end
  end

  describe "#definition" do
    it "returns definition_markdown when present" do
      doc = described_class.new(
        edition: edition, clause: "x", name: "y",
        definition_html: "<p>html</p>", definition_markdown: "**md**",
        alt_names: [], examples: [], notes: [], sources: [],
        relationships: [], specializations: [], figures: [],
        breadcrumb_sections: [], history_notes: [],
      )
      expect(doc.definition).to eq("**md**")
    end

    it "falls back to definition_html when markdown is nil" do
      doc = described_class.new(
        edition: edition, clause: "x", name: "y",
        definition_html: "<p>html</p>", definition_markdown: nil,
        alt_names: [], examples: [], notes: [], sources: [],
        relationships: [], specializations: [], figures: [],
        breadcrumb_sections: [], history_notes: [],
      )
      expect(doc.definition).to eq("<p>html</p>")
    end
  end

  describe "#valid?" do
    it "is true when clause, name, and definition present" do
      doc = described_class.new(
        edition: edition, clause: "3.1.1.1", name: "entity",
        definition_markdown: "thing",
        alt_names: [], definition_html: nil, examples: [], notes: [], sources: [],
        relationships: [], specializations: [], figures: [],
        breadcrumb_sections: [], history_notes: [],
      )
      expect(doc).to be_valid
    end

    it "is false when clause is missing" do
      doc = described_class.new(
        edition: edition, clause: nil, name: "entity",
        definition_markdown: "thing",
        alt_names: [], definition_html: nil, examples: [], notes: [], sources: [],
        relationships: [], specializations: [], figures: [],
        breadcrumb_sections: [], history_notes: [],
      )
      expect(doc).not_to be_valid
    end
  end
end
