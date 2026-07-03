# frozen_string_literal: true

require "yaml"

module Iso14812Import
  class Edition
    attr_reader :id, :schema_version, :urn, :year, :ref, :status, :supersedes,
                :predecessor_urn, :date_accepted, :owner, :source_repo,
                :source, :languages, :config_path

    def self.load(path)
      new(YAML.load_file(path), config_path: path)
    end

    def initialize(attrs, config_path: nil)
      attrs = attrs || {}
      @config_path = config_path
      @id = attrs.fetch(:id) { attrs.fetch("id") }
      @schema_version = attrs.fetch(:schema_version) { attrs.fetch("schema_version") { "3" } }
      @urn = attrs.fetch(:urn) { attrs.fetch("urn") }
      @year = attrs.fetch(:year) { attrs.fetch("year") }
      @ref = attrs.fetch(:ref) { attrs.fetch("ref") }
      @status = attrs.fetch(:status) { attrs.fetch("status") }
      @supersedes = attrs[:supersedes] || attrs["supersedes"]
      @predecessor_urn = attrs[:predecessor_urn] || attrs["predecessor_urn"]
      @date_accepted = attrs[:date_accepted] || attrs["date_accepted"]
      @owner = attrs.fetch(:owner) { attrs.fetch("owner") }
      @source_repo = attrs[:source_repo] || attrs["source_repo"]
      @source = (attrs[:source] || attrs["source"]) || {}
      @languages = (attrs[:languages] || attrs["languages"]) || []
    end

    def current? = status == "current"
    def superseded? = status == "superseded"
    def parser_kind = source.fetch(:parser) { source.fetch("parser") { "none" } }
    def vocabulary_path = source[:vocabulary_path] || source["vocabulary_path"]
    def terms_dir = source[:terms_dir] || source["terms_dir"]
    def source_repo_path = source[:repo] || source["repo"]
    def source_ref = source[:ref] || source["ref"]
    def source_type = (source[:type] || source["type"] || "git_ref")

    def predecessor(config_root: nil)
      return nil unless config_root && supersedes

      predecessor_path = File.join(config_root, "#{supersedes}.yml")
      return nil unless File.exist?(predecessor_path)

      self.class.load(predecessor_path)
    end
  end
end
