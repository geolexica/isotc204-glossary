# frozen_string_literal: true

module Iso14812Import
  Document = Struct.new(
    :edition,
    :clause,
    :guid,
    :name,
    :alt_names,
    :definition_html,
    :definition_markdown,
    :examples,
    :notes,
    :sources,
    :relationships,
    :specializations,
    :figures,
    :breadcrumb_sections,
    :history_notes,
    keyword_init: true,
  ) do
    def self.empty_for(edition)
      new(
        edition: edition,
        clause: nil, guid: nil, name: nil,
        alt_names: [], definition_html: nil, definition_markdown: nil,
        examples: [], notes: [], sources: [],
        relationships: [], specializations: [],
        figures: [], breadcrumb_sections: [],
        history_notes: [],
      )
    end

    def definition
      definition_markdown || definition_html
    end

    def has_definition?
      definition && !definition.strip.empty?
    end

    def valid?
      !clause.nil? && !clause.strip.empty? &&
        !name.nil? && !name.strip.empty? &&
        has_definition?
    end
  end

  SourceCitation = Struct.new(:raw_text, :source_ref, :clause, :link, :type,
                              keyword_init: true)
  RawRelationship = Struct.new(:predicate, :target_name, :constraint, :description,
                               keyword_init: true)
  Specialization = Struct.new(:target_name, :description, keyword_init: true)
  FigureRef = Struct.new(:src, :alt, :caption, keyword_init: true)
  HistoryNote = Struct.new(:year, :kind, :text, keyword_init: true)
end
