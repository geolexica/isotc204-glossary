# frozen_string_literal: true

require "securerandom"

module Iso14812Import
  class FigureRegistry
    FigureEntry = Struct.new(:id, :identifier, :src, :alt, :caption, :sources,
                              keyword_init: true)

    attr_reader :edition, :entries

    def initialize(edition:)
      @edition = edition
      @entries = {}
      @counter = 0
    end

    def register(src:, alt: nil, caption: nil)
      return @entries[src].id if @entries.key?(src)

      id = derive_id(src)
      @entries[src] = FigureEntry.new(
        id: id, identifier: id, src: src, alt: alt, caption: caption, sources: [],
      )
      id
    end

    def resolve(src)
      @entries[src]&.id
    end

    def each_figure(&)
      @entries.values.each(&)
    end

    def size = @entries.size

    private

    def derive_id(src)
      stem = File.basename(src, ".*")
                        .gsub(/[^A-Za-z0-9]+/, "_")
                        .gsub(/^_+|_+$/, "")
      "fig_#{stem}"
    end
  end
end
