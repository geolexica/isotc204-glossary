# frozen_string_literal: true

require "iso14812_import"
require "glossarist"
require "optparse"

module Iso14812Import
  class Cli
    attr_reader :argv, :edition_path, :previous_path, :output_root

    def initialize(argv)
      @argv = argv.dup
      @output_root = "datasets"
      parse_options!
    end

    def run
      pipeline = Pipeline.new(
        edition_config_path: edition_path,
        previous_edition_config_path: previous_path,
        output_root: output_root,
      )
      summary = pipeline.run
      print_summary(summary)
      exit(summary.validation_passed ? 0 : 1)
    end

    private

    def parse_options!
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: import_iso14812.rb --edition CONFIG [options]"
        opts.on("--edition PATH", "Edition config YAML") { |v| @edition_path = v }
        opts.on("--previous PATH", "Previous edition config YAML") { |v| @previous_path = v }
        opts.on("--output-root PATH", "Output root (default: datasets)") { |v| @output_root = v }
        opts.on("-h", "--help") do
          warn opts
          exit 0
        end
      end
      parser.parse!(argv)
      abort "Missing required --edition option" unless edition_path
    end

    def print_summary(summary)
      puts "Edition:        #{summary.edition_id}"
      puts "Previous:       #{summary.previous_edition_id || '(none)'}"
      puts "Concepts:       #{summary.concepts_written}"
      puts "Figures:        #{summary.figures_written}"
      puts "Bibliography:   #{summary.bibliography_written}"
      puts "Supersedes:     #{summary.supersedes_edges || 0} edges"
      puts "Withdrawn:      #{summary.withdrawn_marked || 0} older concepts marked"
      puts "Validation:     #{summary.validation_passed ? 'pass' : 'FAIL'}"
    end
  end
end

Iso14812Import::Cli.new(ARGV).run
