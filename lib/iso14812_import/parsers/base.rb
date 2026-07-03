# frozen_string_literal: true

module Iso14812Import
  module Parsers
    class Base
      def each_document(&)
        raise NotImplementedError,
              "#{self.class} must implement #each_document"
      end

      def documents
        enum_for(:each_document).to_a
      end
    end
  end
end
