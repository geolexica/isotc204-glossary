# frozen_string_literal: true

module Iso14812Import
  class SourceParser
    # Matches: "<ref>, <clause>, <status>[ - <modification>]"
    # Status is one of: modified, identical, adapted
    # Modification is optional, may follow status with " - ", " — ", or just ","
    MODIFICATION_PATTERN = /\A
      (?<source>.+?),\s*
      (?<clause>[^,]+),\s*
      (?<status>modified|identical|adapted)
      (?:\s*(?:[-—,]\s*|\s+)(?<modification>.+))?
    \z/ix.freeze

    def self.parse(raw_text, default_type: "authoritative")
      return nil if raw_text.nil? || raw_text.strip.empty?

      if (m = raw_text.match(MODIFICATION_PATTERN))
        return structured(
          source_ref: m[:source].strip,
          clause: m[:clause].strip,
          status: normalize_status(m[:status]),
          modification: m[:modification]&.strip,
          default_type: default_type,
        )
      end

      structured(
        source_ref: raw_text.strip, clause: nil, status: nil,
        modification: nil, default_type: default_type,
      )
    end

    def self.structured(source_ref:, clause:, status:, modification:, default_type:)
      {
        type: default_type,
        origin: {
          ref: { source: source_ref },
          locality: clause ? { type: "clause", reference_from: clause } : nil,
        }.compact,
        status: status,
        modification: modification,
      }.compact
    end
    private_class_method :structured

    def self.normalize_status(s)
      return nil if s.nil?
      s.strip.downcase
    end
    private_class_method :normalize_status
  end
end
