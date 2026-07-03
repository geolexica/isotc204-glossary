# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe Iso14812Import::Parsers::MarkdownParser do
  let(:edition) do
    instance_double("Iso14812Import::Edition",
      id: "isotc204-ed3",
      urn: "urn:iso:std:iso:14812:ed3",
      schema_version: "3",
      date_accepted: "2026-06-01")
  end

  let(:terms_dir) { Dir.mktmpdir("e3-terms") }
  let(:fixture_md) { File.join(FIXTURES_DIR, "e3_sample.md") }

  before do
    FileUtils.cp(fixture_md, File.join(terms_dir, "ITS application.md"))
  end

  after { FileUtils.remove_entry(terms_dir) if File.directory?(terms_dir) }

  let(:parser) { described_class.new(edition: edition, terms_dir: terms_dir) }

  it "yields one Document per markdown file" do
    expect(parser.documents.size).to eq(1)
  end

  it "extracts the title from the H1" do
    expect(parser.documents.first.name).to eq("ITS application")
  end

  it "extracts the clause" do
    expect(parser.documents.first.clause).to eq("3.2.8.1")
  end

  it "extracts the definition prose" do
    expect(parser.documents.first.definition_markdown).to include("requirements for an")
  end

  it "extracts notes in order" do
    doc = parser.documents.first
    expect(doc.notes.length).to eq(2)
    expect(doc.notes.first).to include("involve associations with nodes")
  end

  it "extracts history notes with structured year/kind" do
    doc = parser.documents.first
    expect(doc.history_notes.length).to eq(2)
    revised = doc.history_notes.find { |n| n.kind == :revised }
    introduced = doc.history_notes.find { |n| n.kind == :introduced }
    expect(revised.year).to eq(2025)
    expect(introduced.text).to include("Introduced in ISO/TS 14812:2022")
  end

  it "extracts the relationship table" do
    doc = parser.documents.first
    predicates = doc.relationships.map(&:predicate)
    expect(predicates).to include("involves", "realizationOf")
  end

  it "extracts the specialization table" do
    doc = parser.documents.first
    expect(doc.specializations.length).to eq(1)
    spec = doc.specializations.first
    expect(spec.target_name).to include("Personal ITS application")
    expect(spec.description).to include("for a single")
  end
end
