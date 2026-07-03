# 10 — Figure registry

**Phase:** B
**Status:** todo
**Depends on:** 02, 03

## Goal

`Iso14812Import::FigureRegistry` tracks all figure references encountered
during parsing and produces `figures/<id>.yaml` files at write time, plus
the in-memory lookup that `ContentConverter` uses to emit `<<fig-id>>` xrefs.

## Why

Both E2 and E3 reference figures (E2 via `<figure><img>` in packages, E3 via
`<object type="image/svg+xml">` in markdown bodies). The v3 non-verbal entity
model (per commit 4348b5a) requires one YAML file per figure under
`figures/`. Centralizing figure registration avoids duplication across
parsers and the content converter.

## Interface

```ruby
class Iso14812Import::FigureRegistry
  FigureEntry = Struct.new(:id, :identifier, :images, :caption, :alt, :sources,
                           keyword_init: true)

  def initialize(edition:) end
  def register(src:, alt: nil, caption: nil)  # returns figure id
  def resolve(src)                            # returns figure id or nil
  def each_figure(&block) end
  def figures_path                            # datasets/<edition>/figures/
end
```

Figure ID derivation: deterministic from the source filename stem
(e.g. `images/Entity terms.png` → `fig_Entity_terms`, mirroring the existing
`fig_A.23.yaml` pattern in the 2022 dataset).

## Tasks

- [ ] `lib/iso14812_import/figure_registry.rb`:
  - `#register(src:, alt:, caption:)` — derive id, store entry, return id
  - `#resolve(src)` — idempotent lookup
  - `#each_figure` — yield each `FigureEntry`
  - `#to_yaml_files(path)` — write one file per entry via `Glossarist::Figure`
    model serialization
- [ ] `spec/iso14812_import/figure_registry_spec.rb`:
  - Register a figure, resolve it by src, get the same id back
  - Register the same src twice → idempotent (one entry, same id)
  - Different srcs → different ids
  - Caption/alt preserved
  - `to_yaml_files` writes the expected number of files (use a tmpdir)
- [ ] Verify `Glossarist::Figure` model API:
      `Glossarist::Figure.new(id:, identifier:, images: [...])`

## Acceptance criteria

- A figure referenced N times produces exactly one YAML file.
- YAML files validate against `glossarist validate`.
- Image srcs are relative paths within the dataset
  (`images/Entity terms.png`, not absolute paths).

## Notes

- E2 images currently live inside the E2 source repo (`images/*.png`); the
  pipeline must copy them to `datasets/isotc204-2025/images/` at import time,
  preserving the original filenames. Per global rule, never delete the
  originals.
- E3 diagrams are auto-generated `.dot.svg` + `.dot.png` pairs from
  `iso14812/diagrams/`. Same copy-on-import pattern.
- The `figures/` directory per dataset is small (< 10 figures in current E1
  data); registry memory is not a concern.
