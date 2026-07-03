# 13 — Pipeline

**Phase:** B
**Status:** done
**Depends on:** 02–12

## Goal

`Iso14812Import::Pipeline` orchestrates an end-to-end import run for one
edition: load edition config → select parser → parse → build index → build
concepts → derive cross-edition edges → write to disk → validate.

## Why

The collaborators (`XmlParser`, `MarkdownParser`, `ConceptBuilder`, `Writer`,
`SupersedesDeriver`) are individually simple. The pipeline wires them in the
correct order with the correct dependencies. This is the only place that
order is encoded — changing the order = one file edit.

## Interface

```ruby
class Iso14812Import::Pipeline
  def initialize(edition_config_path:, output_root: "datasets",
                 previous_edition_config_path: nil)
  end

  def run
    # returns summary: { edition_id:, concepts_written:, figures_written:,
    #                    supersedes_edges:, validation_status: }
  end
end
```

## Run order

1. Load `Edition` from `edition_config_path`. Load previous edition (if any).
2. Resolve source: git_ref → checkout worktree (or use local_path).
3. Select parser via `edition.source.parser`:
   - `"xml"` → `Parsers::XmlParser`
   - `"markdown"` → `Parsers::MarkdownParser`
   - `"none"` → no-op (E1 passthrough — already on disk)
4. First pass: parser yields all `Document`s. Collect into array.
5. Build `SourceIndex` from documents.
6. Build `FigureRegistry`, `ContentConverter`, `ConceptBuilder` with
   shared collaborators.
7. For each document: build `ManagedConcept` via builder. Collect.
8. If previous edition: load its `SourceIndex` (re-parse if needed, or cache
   to `.cache/<edition_id>-index.yml`). Call `SupersedesDeriver.derive(...)`.
9. `Writer.new(edition:, output_root:).write_concepts(...)` then
   `write_figures(...)`, `write_bibliography(...)`, `write_register`.
10. Validate: shell to `glossarist validate <dataset_path>`. Capture pass/fail.
11. Return summary struct.

## Tasks

- [ ] `lib/iso14812_import/pipeline.rb` with the run sequence above
- [ ] `lib/iso14812_import/pipeline_summary.rb` (Struct)
- [ ] `spec/iso14812_import/pipeline_spec.rb`:
  - End-to-end with a tiny fixture XML edition (3 concepts)
  - Asserts 3 concept files written
  - Asserts register.yaml written
  - Asserts validation passes (or skip if glossarist gem not available in spec)
  - Asserts summary struct fields populated
  - With a previous edition: asserts supersedes edges present
- [ ] CLI entry point `scripts/import_iso14812.rb`:
  - `import_iso14812.rb --edition config/editions/isotc204-2025.yml [--previous ...]`
  - Loads Pipeline, runs, prints summary
  - Exit code: 0 on success, 1 on validation failure

## Acceptance criteria

- A full E2 import via CLI produces `datasets/isotc204-2025/` with N concept
  files, register.yaml, figures/ — all validatable.
- Re-running the pipeline produces identical output (idempotent).
- Pipeline summary accurately reports counts.

## Notes

- The pipeline is the only class that knows the run order. Per OCP, adding a
  new stage (e.g. "post-process validation report") means extending the
  pipeline, not editing the writer or builder.
- For very large editions, the documents array could be replaced with a
  streaming consumer — but for ~300-400 concepts the array is fine.
- If `previous_edition_config_path` is given, the previous edition's index is
  needed. Cache it on first compute to avoid re-parsing the previous edition's
  source on every run.
