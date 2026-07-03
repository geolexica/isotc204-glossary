# 04 — Edition configuration

**Phase:** B
**Status:** done
**Depends on:** 02

## Goal

Define `Iso14812Import::Edition` — a value object describing one edition's
metadata. One YAML config file per edition lives under
`lib/iso14812_import/editions/` (or `config/editions/`).

## Why

Each edition has different source path, URN, year, predecessor, and lifecycle
status. Externalizing this to YAML keeps the converter code edition-agnostic
(open/closed). Adding E4 = adding a YAML file.

## Edition config shape

```yaml
# config/editions/isotc204-2025.yml
id: isotc204-2025
schema_version: "3"
urn: urn:iso:std:iso:14812:2025
year: 2025
ref: ISO 14812:2025
status: superseded        # set to current once E3 lands; superseded once E3 is current
supersedes: isotc204-2022
predecessor_urn: urn:iso:std:iso:ts:14812:2022
date_accepted: 2025-12-31
owner: ISO/TC 204
source_repo: https://github.com/ISO-TC204/iso14812
source:
  type: git_ref           # git_ref | local_path
  repo: /Users/mulgogi/src/external/iso14812
  ref: dfe7e9d4           # commit/tag/branch
  parser: xml             # xml | markdown
  vocabulary_path: "14812 - Vocabulary.xml"
languages: [eng]
```

Three edition files:

- `isotc204-2022.yml` — already-imported, points to `datasets/isotc204-2022/`
  as both source and output (parser: none / passthrough).
- `isotc204-2025.yml` — E2, parser: xml, ref: `dfe7e9d4`.
- `isotc204-ed3.yml` — E3, parser: markdown, ref: HEAD.

## Tasks

- [ ] `lib/iso14812_import/edition.rb` — `Edition` class with attrs matching
      config fields, plus `.load(path)` class method using `YAML.load_file`
- [ ] `config/editions/isotc204-2022.yml`
- [ ] `config/editions/isotc204-2025.yml`
- [ ] `config/editions/isotc204-ed3.yml`
- [ ] `spec/iso14812_import/edition_spec.rb`:
  - `.load(path)` returns an `Edition` with all fields populated
  - Missing required fields raise `ArgumentError`
  - `#predecessor` returns the previous `Edition` (loads its config)
  - `#current?` true iff `status == "current"`
- [ ] Validation: every edition except the oldest has `supersedes` and
      `predecessor_urn` populated

## Acceptance criteria

- `Edition.load("config/editions/isotc204-2025.yml")` returns a fully-populated
  instance.
- `edition.predecessor` for E3 returns the E2 edition.
- Specs pass with real `Edition` instances (no doubles).

## Notes

- Don't load all editions eagerly. `Pipeline` loads only what it needs per run.
- The `source.parser` field drives which parser class the `Pipeline` instantiates
  — open/closed for new parsers.
