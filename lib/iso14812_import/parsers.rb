# frozen_string_literal: true

module Iso14812Import
  module Parsers
    autoload :Base,           "iso14812_import/parsers/base"
    autoload :XmlParser,      "iso14812_import/parsers/xml_parser"
    autoload :MarkdownParser, "iso14812_import/parsers/markdown_parser"
    autoload :YamlDirParser,  "iso14812_import/parsers/yaml_dir_parser"
  end
end
