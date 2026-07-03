# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe Iso14812Import::Parsers::MarkdownParser, "object/example/refs handling" do
  let(:edition) do
    instance_double("Iso14812Import::Edition",
      id: "isotc204-ed3",
      urn: "urn:iso:std:iso:14812:ed3",
      schema_version: "3",
      date_accepted: "2026-06-01")
  end

  let(:terms_dir) { Dir.mktmpdir("e3-terms-obj") }
  let(:fixture_md) { File.join(FIXTURES_DIR, "e3_object_example.md") }

  before { FileUtils.cp(fixture_md, File.join(terms_dir, "entity.md")) }
  after { FileUtils.remove_entry(terms_dir) if File.directory?(terms_dir) }

  let(:doc) { described_class.new(edition: edition, terms_dir: terms_dir).documents.first }

  it "excludes multi-line <object> blocks from the definition" do
    expect(doc.definition_markdown).not_to include("<object")
    expect(doc.definition_markdown).not_to include("<img")
    expect(doc.definition_markdown).not_to include("</object>")
  end

  it "captures the <object> block as a figure reference" do
    expect(doc.figures.length).to eq(1)
    fig = doc.figures.first
    expect(fig.src).to include("entity.dot.png")
    expect(fig.alt).to eq("entity Diagram")
  end

  it "routes EXAMPLE: lines to examples[], not the definition" do
    expect(doc.examples.length).to eq(1)
    expect(doc.examples.first).to include("person")
    expect(doc.definition_markdown).not_to include("EXAMPLE:")
  end

  it "excludes the ## References to X reverse-relationship table from the definition" do
    expect(doc.definition_markdown).not_to include("Referencing Term")
    expect(doc.definition_markdown).not_to include("| --- |")
  end

  it "does not promote References rows to specializations" do
    # Only the two Specializations of entity rows should land here.
    # The References table rows must NOT appear.
    expect(doc.specializations.length).to eq(2)
    names = doc.specializations.map(&:target_name).join(" ")
    expect(names).to include("immaterial entity", "material entity")
    expect(names).not_to include("bounded secured managed domain")
  end
end
