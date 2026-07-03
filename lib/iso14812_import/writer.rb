# frozen_string_literal: true

require "fileutils"

module Iso14812Import
  class Writer
    attr_reader :edition, :output_root

    def initialize(edition:, output_root: "datasets")
      @edition = edition
      @output_root = output_root
    end

    def dataset_path = File.join(output_root, edition.id)
    def concepts_dir  = File.join(dataset_path, "concepts")
    def figures_dir   = File.join(dataset_path, "figures")

    def write_concepts(concepts)
      FileUtils.mkdir_p(concepts_dir)
      concepts.each do |concept|
        clause = concept.data.id || concept.uuid
        path = File.join(concepts_dir, "#{clause}.yaml")
        File.write(path, serialize_concept(concept))
      end
      concepts.length
    end

    def write_figures(registry)
      return 0 if registry.size.zero?

      FileUtils.mkdir_p(figures_dir)
      registry.each_figure do |entry|
        path = File.join(figures_dir, "#{entry.id}.yaml")
        File.write(path, serialize_figure(entry))
      end
      registry.size
    end

    def write_register
      FileUtils.mkdir_p(dataset_path)
      File.write(File.join(dataset_path, "register.yaml"), serialize_register)
    end

    def write_bibliography(entries)
      return 0 if entries.nil? || entries.empty?

      FileUtils.mkdir_p(dataset_path)
      data = Glossarist::BibliographyData.new(entries: entries)
      File.write(File.join(dataset_path, "bibliography.yaml"), data.to_yaml)
      entries.length
    end

    private

    def serialize_concept(concept)
      Glossarist::ConceptDocument.from_managed_concept(concept).to_yamls
    end

    def serialize_figure(entry)
      Glossarist::Figure.new(
        id: entry.id,
        identifier: entry.identifier,
        images: [Glossarist::FigureImage.new(
          src: entry.src, format: image_format(entry.src), role: "raster",
        )],
      ).to_yaml
    end

    def image_format(src)
      ext = File.extname(src).downcase.delete(".")
      %w[png svg jpg jpeg gif webp].include?(ext) ? ext : "png"
    end

    def serialize_register
      Glossarist::DatasetRegister.new(
        schema_type: "glossarist",
        schema_version: edition.schema_version,
        id: edition.id,
        urn: edition.urn,
        year: edition.year,
        ref: edition.ref,
        status: edition.status,
        owner: edition.owner,
        source_repo: edition.source_repo,
        languages: edition.languages,
        supersedes: edition.supersedes,
      ).to_yaml
    end
  end
end
