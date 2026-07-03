# frozen_string_literal: true

require "logger"
require "forwardable"

module Iso14812Import
  class ContentConverter
    OFFICE_FIELD_PATTERN = /
      <span\s+style=['"]mso-element:field-begin['"][^>]*>\s*<\/span>
      \s*REF\s+([A-Za-z0-9]+)
      \s*<span\s+style=['"]mso-element:field-end['"][^>]*>\s*<\/span>
    /x.freeze

    HTML_REF_PATTERN = %r{<a\s+href=["']#([A-Za-z0-9]+)["'][^>]*>([^<]+)</a>}.freeze
    MD_REF_PATTERN   = %r{\[([^\]]+)\]\(([^)]+\.md)\)}.freeze

    attr_reader :edition, :source_index, :figure_registry, :logger

    def initialize(edition:, source_index:, figure_registry:, logger: default_logger)
      @edition = edition
      @source_index = source_index
      @figure_registry = figure_registry
      @logger = logger
    end

    def from_html(html)
      cleaned = strip_office_field_codes(html.to_s)
      adoc = coradoc_convert(cleaned, from: :html)
      resolve_inline_refs(adoc, :html)
    end

    def from_markdown(markdown)
      adoc = coradoc_convert(markdown.to_s, from: :markdown)
      resolve_inline_refs(adoc, :markdown)
    end

    private

    def strip_office_field_codes(html)
      html.gsub(OFFICE_FIELD_PATTERN) do
        guid = Regexp.last_match(1)
        target = source_index.lookup(guid: guid)
        target ? target.name : ""
      end
    end

    def coradoc_convert(text, from:)
      return "" if text.strip.empty?
      return text unless defined?(::Coradoc)

      ::Coradoc.convert(text, from: from, to: :asciidoc).to_s
    rescue StandardError => e
      logger.warn("Coradoc #{from}→AsciiDoc failed: #{e.message}; passing through")
      text
    end

    def resolve_inline_refs(adoc, format)
      pattern = format == :html ? HTML_REF_PATTERN : MD_REF_PATTERN
      adoc.gsub(pattern) do |match|
        resolve_one(match, format)
      end
    end

    def resolve_one(match, format)
      if format == :html
        guid, display = match.match(HTML_REF_PATTERN).captures
        target = source_index.lookup(guid: guid)
      else
        display, link = match.match(MD_REF_PATTERN).captures
        target = source_index.lookup(name: File.basename(link, ".md"))
      end

      if target
        "{{#{edition.urn}:#{target.clause},#{display}}}"
      else
        logger.info("Unresolved cross-ref: #{display}")
        display
      end
    end

    def default_logger
      level = ENV.fetch("ISO14812_LOG_LEVEL", "warn")
      Logger.new($stderr, level: level.to_sym)
    rescue ArgumentError
      Logger.new($stderr)
    end
  end
end
