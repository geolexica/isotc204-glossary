# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Iso14812Import::Edition do
  let(:config_dir) { Dir.mktmpdir("iso14812-edition-spec") }
  let(:config_path) { File.join(config_dir, "test-edition.yml") }

  after { FileUtils.remove_entry(config_dir) if File.directory?(config_dir) }

  def write_config(hash)
    File.write(config_path, hash.to_yaml)
  end

  def base_attrs(overrides = {})
    {
      "id" => "x", "schema_version" => "3", "urn" => "u", "year" => 2025,
      "ref" => "R", "status" => "current", "owner" => "O",
      "source" => {}, "languages" => ["eng"],
    }.merge(overrides)
  end

  describe ".load" do
    it "loads all required fields" do
      write_config(
        "id" => "test-2025", "schema_version" => "3",
        "urn" => "urn:test:2025", "year" => 2025, "ref" => "Test 2025",
        "status" => "current", "owner" => "TestOrg",
        "source_repo" => "https://example.com",
        "languages" => ["eng"],
        "source" => { "type" => "git_ref", "parser" => "xml", "ref" => "abc123" },
      )
      edition = described_class.load(config_path)

      expect(edition.id).to eq("test-2025")
      expect(edition.urn).to eq("urn:test:2025")
      expect(edition.year).to eq(2025)
      expect(edition.parser_kind).to eq("xml")
      expect(edition.source_ref).to eq("abc123")
    end

    it "raises KeyError when required field missing" do
      write_config("id" => "test", "urn" => "urn:test")
      expect { described_class.load(config_path) }.to raise_error(KeyError)
    end
  end

  describe "#current?" do
    it "is true when status is current" do
      edition = described_class.new(base_attrs("status" => "current"))
      expect(edition).to be_current
      expect(edition).not_to be_superseded
    end
  end

  describe "#predecessor" do
    it "loads the previous edition's config when it exists" do
      prev_path = File.join(config_dir, "prev.yml")
      File.write(prev_path, base_attrs(
        "id" => "prev", "urn" => "urn:test:prev", "year" => 2024,
        "ref" => "Prev", "status" => "superseded",
      ).to_yaml)
      edition = described_class.new(base_attrs(
        "id" => "curr", "urn" => "urn:test:curr",
        "supersedes" => "prev",
      ))

      predecessor = edition.predecessor(config_root: config_dir)
      expect(predecessor.id).to eq("prev")
      expect(predecessor.year).to eq(2024)
    end

    it "returns nil when no supersedes field" do
      edition = described_class.new(base_attrs)
      expect(edition.predecessor(config_root: config_dir)).to be_nil
    end
  end
end
