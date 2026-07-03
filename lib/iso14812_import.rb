# frozen_string_literal: true

module Iso14812Import
  autoload :VERSION, "iso14812_import/version"

  # Value objects / configuration
  autoload :Edition,            "iso14812_import/edition"
  autoload :Document,           "iso14812_import/document"
  autoload :DocumentSection,    "iso14812_import/document_section"
  autoload :SourceIndex,        "iso14812_import/source_index"
  autoload :DeterministicUuid,  "iso14812_import/deterministic_uuid"

  # Collaborators (single-responsibility services)
  autoload :ContentConverter,    "iso14812_import/content_converter"
  autoload :RelationshipMapper,  "iso14812_import/relationship_mapper"
  autoload :FigureRegistry,      "iso14812_import/figure_registry"
  autoload :SourceParser,        "iso14812_import/source_parser"
  autoload :ConceptBuilder,      "iso14812_import/concept_builder"
  autoload :Writer,              "iso14812_import/writer"
  autoload :SupersedesDeriver,   "iso14812_import/supersedes_deriver"
  autoload :Pipeline,            "iso14812_import/pipeline"
  autoload :PipelineSummary,     "iso14812_import/pipeline_summary"
  autoload :BibliographyBuilder, "iso14812_import/bibliography_builder"

  # Sub-namespaces
  autoload :Parsers, "iso14812_import/parsers"
end
