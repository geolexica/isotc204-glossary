# frozen_string_literal: true

require "spec_helper"

RSpec.describe Iso14812Import::FigureRegistry do
  let(:edition) { instance_double("Iso14812Import::Edition", id: "test") }

  let(:registry) { described_class.new(edition: edition) }

  describe "#register" do
    it "derives a deterministic id from the src" do
      id = registry.register(src: "images/Entity terms.png", alt: "Entity terms")
      expect(id).to eq("fig_Entity_terms")
    end

    it "is idempotent for the same src" do
      first = registry.register(src: "images/Foo.png")
      second = registry.register(src: "images/Foo.png")
      expect(first).to eq(second)
      expect(registry.size).to eq(1)
    end

    it "produces distinct ids for different srcs" do
      a = registry.register(src: "images/Foo.png")
      b = registry.register(src: "images/Bar.png")
      expect(a).not_to eq(b)
    end

    it "preserves caption and alt" do
      registry.register(src: "x.png", alt: "alt-text", caption: "caption-text")
      entry = registry.each_figure.first
      expect(entry.alt).to eq("alt-text")
      expect(entry.caption).to eq("caption-text")
    end
  end

  describe "#resolve" do
    it "returns the registered id" do
      id = registry.register(src: "x.png")
      expect(registry.resolve("x.png")).to eq(id)
    end

    it "returns nil for unregistered src" do
      expect(registry.resolve("not-registered.png")).to be_nil
    end
  end

  describe "#each_figure, #size" do
    it "yields each entry" do
      registry.register(src: "a.png")
      registry.register(src: "b.png")
      expect(registry.each_figure.to_a.size).to eq(2)
      expect(registry.size).to eq(2)
    end
  end
end
