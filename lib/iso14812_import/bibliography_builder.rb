# frozen_string_literal: true

module Iso14812Import
  class BibliographyBuilder
    attr_reader :entries

    def initialize
      @entries = {}
    end

    def register(raw_text)
      return if raw_text.nil? || raw_text.strip.empty?
      return @entries[raw_text] if @entries.key?(raw_text)

      id = "ref_#{format('%03d', next_index)}"
      @entries[raw_text] = Glossarist::BibliographyEntry.new(
        id: id,
        reference: raw_text,
        title: extract_title(raw_text),
      )
    end

    def each_entry(&)
      @entries.values.each(&)
    end

    def size = @entries.size

    private

    def next_index = @entries.size + 1

    def extract_title(raw_text)
      raw_text.split(/,/).first.to_s.strip
    end
  end
end
