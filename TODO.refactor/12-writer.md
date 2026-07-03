# 12 — Writer

**Phase:** B
**Status:** done
**Depends on:** 02, 11

## Goal

`Iso14812Import::Writer` serializes `ManagedConcept` instances to disk using
the glossarist gem's serialization (lutaml-model), one multi-document YAML
file per concept. Also writes `register.yaml` and `figures/*.yaml`.

## Why

Single responsibility for I/O. Concept builder doesn't touch disk; pipeline
orchestrates; writer does the actual writes. This isolates any future changes
to file layout or serialization format.

## Interface

```ruby
class Iso14812Import::Writer
  def initialize(edition:, output_root: "datasets") end

  # @param concepts [Enumerable<Glossarist::ManagedConcept>]
  def write_concepts(concepts) end

  # @param registry [Iso14812Import::FigureRegistry]
  def write_figures(registry) end

  # @param bibliography [Enumerable<Glossarist::BibliographyEntry>, nil]
  def write_bibliography(bibliography) end

  def write_register                # writes register.yaml from edition config
  end

  def dataset_path                  # datasets/<edition.id>/
end
```

## File layout per concept

`datasets/<edition.id>/concepts/<clause>.yaml` — multi-document YAML stream:

```
---  # ManagedConcept
<data, related, status, date_accepted, schema_version, id>
---
---  # LocalizedConcept(s)
<data, id>
```

The glossarist gem produces this multi-document form natively via
`ManagedConcept#to_yaml` — verify this in TODO 02 boot smoke test.

## Tasks

- [ ] `lib/iso14812_import/writer.rb`:
  - Compute paths, create directories
  - `#write_concepts(concepts)` — iterate, call `concept.to_yaml`, write to
    `concepts/<clause>.yaml`
  - `#write_figures(registry)` — delegate to `registry.to_yaml_files(figures_path)`
  - `#write_register` — write `register.yaml` from edition config via a
    `Glossarist::DatasetRegister` model instance (lutaml-based, not hand-rolled)
  - `#write_bibliography(bib)` — if bib non-nil
- [ ] `spec/iso14812_import/writer_spec.rb`:
  - Build a fixture concept (real `ManagedConcept`), write it, read back the
    file, parse with `ManagedConcept.from_yaml(File.read(...))`, assert
    equality on key fields
  - Writing is idempotent (same input → same output bytes)
  - Register YAML round-trips
  - Uses tmpdir for output
- [ ] Verify the glossarist gem's `ManagedConcept#to_yaml` actually produces
      multi-document output. If not, this is a gap to raise upstream — do NOT
      work around it with hand-rolled YAML emission.

## Acceptance criteria

- Every written concept file is readable by `glossarist validate`.
- Output is deterministic — running the writer twice produces identical bytes.
- No `File.write` of hand-rolled strings — all serial content comes from
  glossarist gem model methods.
- Round-trip equality on key fields (`id`, `data.identifier`, `data.localizations.first.terms`, etc.).

## Notes

- The current 2022 concept files are the ground truth for output shape. The
  writer must produce equivalent YAML for the same logical content.
- File naming: clause IDs (e.g. `3.5.8.8.yaml`) for E2 and E3. E1 keeps its
  UUIDs (no rename per the never-delete-source rule).
- Idempotency matters because the pipeline may be re-run after edits; users
  should see clean git diffs.
