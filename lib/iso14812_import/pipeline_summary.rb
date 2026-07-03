# frozen_string_literal: true

module Iso14812Import
  PipelineSummary = Struct.new(
    :edition_id,
    :previous_edition_id,
    :concepts_written,
    :figures_written,
    :bibliography_written,
    :supersedes_edges,
    :withdrawn_marked,
    :validation_passed,
    :validation_output,
    keyword_init: true,
  ) do
    def to_h
      super.transform_keys(&:to_s)
    end
  end
end
