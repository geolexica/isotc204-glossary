# frozen_string_literal: true

require "spec_helper"

RSpec.describe Iso14812Import::SourceParser do
  describe ".parse" do
    it "returns nil for nil input" do
      expect(described_class.parse(nil)).to be_nil
    end

    it "returns nil for blank input" do
      expect(described_class.parse("  ")).to be_nil
    end

    it "parses a structured citation with modification" do
      result = described_class.parse(
        "ISO/IEC TS29003:2018, 3.12, modified to add reference to biological entity definition",
      )
      expect(result[:type]).to eq("authoritative")
      expect(result[:origin][:ref][:source]).to eq("ISO/IEC TS29003:2018")
      expect(result[:origin][:locality][:reference_from]).to eq("3.12")
      expect(result[:status]).to eq("modified")
      expect(result[:modification]).to include("biological entity")
    end

    it "parses a citation with identical status" do
      result = described_class.parse("ISO 14812:2025, 3.1.1.5, identical")
      expect(result[:status]).to eq("identical")
      expect(result[:origin][:ref][:source]).to eq("ISO 14812:2025")
    end

    it "falls through to bare reference when pattern doesn't match" do
      result = described_class.parse("Some Free-form Reference Text")
      expect(result[:origin][:ref][:source]).to eq("Some Free-form Reference Text")
      expect(result[:origin][:locality]).to be_nil
    end
  end
end
