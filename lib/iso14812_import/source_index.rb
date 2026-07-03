# frozen_string_literal: true

module Iso14812Import
  class SourceIndex
    attr_reader :edition_id, :by_clause, :by_name, :by_guid

    def self.build(edition, documents)
      new(
        edition_id: edition.id,
        by_clause: documents.each_with_object({}) { |d, h| h[d.clause] = d },
        by_name:   documents.each_with_object({}) { |d, h| h[d.name.downcase] = d },
        by_guid:   documents.reject { |d| d.guid.nil? }
                           .each_with_object({}) { |d, h| h[d.guid] = d },
      )
    end

    def initialize(edition_id:, by_clause:, by_name:, by_guid:)
      @edition_id = edition_id
      @by_clause = by_clause
      @by_name = by_name
      @by_guid = by_guid
    end

    def lookup(clause: nil, name: nil, guid: nil)
      return by_guid[guid] if guid
      return by_clause[clause] if clause
      return by_name[name.downcase] if name
      nil
    end

    def clauses = by_clause.keys
    def names = by_name.keys
    def guids = by_guid.keys
    def size = by_clause.size
  end
end
