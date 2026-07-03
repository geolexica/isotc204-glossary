# frozen_string_literal: true

module Iso14812Import
  DocumentSection = Struct.new(:clause, :name, :parent_clause, keyword_init: true) do
    def root? = parent_clause.nil?
    def depth = clause.count(".") + 1
  end
end
