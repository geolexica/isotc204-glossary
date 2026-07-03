# frozen_string_literal: true

require "spec_helper"

RSpec.describe Iso14812Import::Parsers::XmlParser do
  let(:edition) do
    instance_double("Iso14812Import::Edition",
      id: "isotc204-2025",
      urn: "urn:iso:std:iso:14812:2025",
      schema_version: "3",
      date_accepted: "2025-12-31")
  end

  let(:fixture_path) { File.join(FIXTURES_DIR, "e2_sample.xml") }
  let(:parser) { described_class.new(edition: edition, io_or_path: fixture_path) }

  it "yields one Document per <term>" do
    docs = parser.documents
    expect(docs.size).to eq(3)
  end

  it "captures clause, guid, and name" do
    doc = parser.documents.find { |d| d.clause == "3.1.1.5" }
    expect(doc.name).to eq("biological entity")
    expect(doc.guid).to eq("idBFF7F45423994d21BDE8FD5BEE09F6FD")
  end

  it "captures definition HTML" do
    doc = parser.documents.find { |d| d.clause == "3.1.1.1" }
    expect(doc.definition_html).to include("concrete or abstract thing")
  end

  it "captures examples" do
    doc = parser.documents.find { |d| d.clause == "3.1.1.1" }
    expect(doc.examples).to include("A person, object, event, idea, process, etc.")
  end

  it "captures notes" do
    doc = parser.documents.find { |d| d.clause == "3.1.1.3" }
    expect(doc.notes.first).to include("All material entities")
  end

  it "captures sources as SourceCitation structs" do
    doc = parser.documents.find { |d| d.clause == "3.1.1.3" }
    expect(doc.sources.first.raw_text).to include("ISO/TS 14812:2022")
  end

  it "captures breadcrumb sections from package nesting" do
    doc = parser.documents.first
    expect(doc.breadcrumb_sections).to eq(["3.1", "3.1.1"])
  end

  it "attaches the edition to each document" do
    expect(parser.documents.first.edition).to eq(edition)
  end
end
