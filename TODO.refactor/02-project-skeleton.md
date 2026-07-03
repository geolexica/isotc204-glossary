# 02 — Project skeleton

**Phase:** B
**Status:** done
**Depends on:** 01

## Goal

Lay down the Ruby project skeleton for the converter under `lib/iso14812_import/`
with proper autoloads, plus `spec/`, `Gemfile`, `Rakefile`. No business logic
yet — just structure.

## Why

The converter is a non-trivial Ruby library (parsers, IR, model-builder, writer,
pipeline). It needs a clean foundation with autoload-only loading (per global
rule) before any class is written.

## Layout

```
isotc204-glossary/
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── lib/
│   ├── iso14812_import.rb            # parent namespace + autoloads
│   └── iso14812_import/
│       ├── version.rb
│       ├── edition.rb                # TODO 04
│       ├── document.rb               # TODO 03
│       ├── document_section.rb       # TODO 03
│       ├── source_index.rb           # TODO 05
│       ├── parsers/
│       │   ├── base.rb               # abstract parser interface
│       │   ├── xml_parser.rb         # TODO 07
│       │   └── markdown_parser.rb    # TODO 16
│       ├── content_converter.rb      # TODO 08
│       ├── relationship_mapper.rb    # TODO 09
│       ├── figure_registry.rb        # TODO 10
│       ├── concept_builder.rb        # TODO 11
│       ├── writer.rb                 # TODO 12
│       ├── supersedes_deriver.rb     # TODO 14
│       └── pipeline.rb               # TODO 13
├── spec/
│   ├── spec_helper.rb
│   ├── fixtures/
│   │   ├── e2_sample.xml
│   │   ├── e3_sample.md
│   │   └── expected_concept.yaml
│   └── iso14812_import/
│       ├── edition_spec.rb
│       ├── document_spec.rb
│       ├── source_index_spec.rb
│       ├── parsers/
│       │   ├── xml_parser_spec.rb
│       │   └── markdown_parser_spec.rb
│       ├── content_converter_spec.rb
│       ├── relationship_mapper_spec.rb
│       ├── figure_registry_spec.rb
│       ├── concept_builder_spec.rb
│       ├── writer_spec.rb
│       ├── supersedes_deriver_spec.rb
│       └── pipeline_spec.rb
└── scripts/
    └── import_iso14812.rb            # CLI entry point
```

## Tasks

- [ ] `Gemfile` with deps: `glossarist` (~> 2.8), `nokogiri` (~> 1.16),
      `coradoc` (~> 1.0), `rspec` (~> 3.13) in `:development`
- [ ] `Rakefile` with: `spec`, `lint`, `import:e2`, `import:e3`, `validate`
- [ ] `lib/iso14812_import.rb` declaring `module Iso14812Import` with `autoload`
      entries for every class listed above (paths: `"iso14812_import/..."`)
- [ ] `lib/iso14812_import/parsers.rb` declaring `module Parsers` with autoloads
      for `Base`, `XmlParser`, `MarkdownParser`
- [ ] `lib/iso14812_import/version.rb` with `VERSION = "0.1.0"`
- [ ] `spec/spec_helper.rb` requiring `iso14812_import` + rspec config
- [ ] Stub `lib/iso14812_import/*.rb` files for each autoloaded class — just
      `module Iso14812Import; class Foo; end; end` skeletons — so the autoloads
      resolve. Real logic comes in subsequent TODOs.
- [ ] `.rspec` file with `--format documentation --color`
- [ ] Verify: `ruby -Ilib -e "require 'iso14812_import'"` loads cleanly with no
      errors and no eager requires

## Acceptance criteria

- `bundle exec rspec` runs and reports 0 examples, 0 failures.
- `ruby -Ilib -e "require 'iso14812_import'; puts Iso14812Import::VERSION"`
  prints `0.1.0`.
- `grep -r 'require_relative' lib/` returns nothing.
- `grep -r "require [\"']iso14812_import" lib/` returns nothing (autoload only).
- Every autoload entry resolves to a file that exists.

## Notes

- Per the global rule, **autoload entries go in the immediate parent namespace's
  file**. `Iso14812Import::Parsers::XmlParser` lives in
  `lib/iso14812_import/parsers/xml_parser.rb`, and the autoload for it is in
  `lib/iso14812_import/parsers.rb` (NOT in `lib/iso14812_import.rb`).
- Top-level `lib/iso14812_import.rb` declares autoloads only for direct
  children: `Edition`, `Document`, `DocumentSection`, `SourceIndex`,
  `ContentConverter`, `RelationshipMapper`, `FigureRegistry`, `ConceptBuilder`,
  `Writer`, `SupersedesDeriver`, `Pipeline`, `Parsers` (submodule).
