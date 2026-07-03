# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is a **multi-edition terminology dataset** (lineage series) for ISO/TC 204
Intelligent Transport Systems (ISO 14812), not an application. It hosts three
editions of the vocabulary as sibling datasets under `datasets/`, with
cross-edition `supersedes` relationships wiring them into a navigable timeline.
All building, validation, and rendering happen in external repos and gems.

The live site is https://isotc204.geolexica.org, deployed from the separate
[`geolexica/isotc204.geolexica.org`](https://github.com/geolexica/isotc204.geolexica.org) repo.

## Editions

| Edition          | Source                                          | Status     |
|------------------|-------------------------------------------------|------------|
| `isotc204-2022`  | Imported from MLGT spreadsheet (E1)             | superseded |
| `isotc204-2025`  | Built from `iso14812` commit `dfe7e9d4` (E2 XML)| superseded |
| `isotc204-ed3`   | Built from `iso14812` HEAD (E3 markdown + TTL)  | current    |

E1 was hand-imported. E2 and E3 are produced by the converter under `lib/iso14812_import/`
(see `TODO.refactor/` for the full build plan). Re-running the converter is idempotent.

## Repository layout

```
isotc204-glossary/
├── datasets/
│   ├── isotc204-2022/        # E1 — 319 concepts (UUID filenames, pre-v3 legacy)
│   │   ├── register.yaml     # v3 register with urn, year, status
│   │   ├── concepts/
│   │   ├── bibliography.yaml
│   │   ├── figures/
│   │   └── images/
│   ├── isotc204-2025/        # E2 — concepts generated from XML parser
│   └── isotc204-ed3/         # E3 — concepts generated from markdown parser
├── lib/iso14812_import/      # the converter library (autoload-structured)
├── spec/                     # rspec suite for the converter
├── scripts/import_iso14812.rb   # CLI entry: runs Pipeline for one edition
├── config/editions/          # one YAML per edition (urn, year, source ref, parser)
├── TODO.refactor/            # numbered, status-tracked work items
├── Gemfile, Rakefile
└── .github/workflows/        # validate per-dataset, package per-edition
```

## Common commands

```sh
bundle install                              # set up converter deps
bundle exec rake validate                   # glossarist validate on every dataset
bundle exec rspec                           # converter test suite
bundle exec scripts/import_iso14812.rb \
  --edition config/editions/isotc204-2025.yml \
  [--previous config/editions/isotc204-2022.yml]   # re-run an import (idempotent)

gem install glossarist                      # if not using bundler
glossarist validate datasets/isotc204-2022/ # validate one dataset
glossarist package datasets/isotc204-2022/ -o out.gcr \
  --shortname isotc204-2022 --version 1.0.0 # build a GCR
```

## Concept file format — multi-document YAML stream

Each `concepts/<id>.yaml` is a multi-document stream:

1. **First doc** — `ManagedConcept`: `data.identifier`, `data.localized_concepts.eng`,
   `data.domains`, top-level `related[]`, `status`, `date_accepted`,
   `schema_version: '3'`, `id`.
2. **Subsequent docs** — `LocalizedConcept` per language: `data.terms[]`,
   `data.definition[]`, `data.examples[]`, `data.notes[]`, `data.sources[]`,
   `language_code`, `entry_status`.

Cross-references inside content use `{{urn:iso:std:iso:14812:<clause>,<display>}}`.
Figure xrefs use AsciiDoc `<<fig-id>>` targeting `figures/<id>.yaml`.

### Cross-edition `supersedes`

Forward direction only (new → old), authored in the newer concept:

```yaml
related:
  - type: supersedes
    ref:
      source: urn:iso:std:iso:ts:14812:2022
      id: '3.5.8.8'
```

The concept-browser derives `superseded_by` at render time. Never author both
directions.

## Schema migrations

The repo is on v3 schema. Recent migrations (do not regress):

- **v3 schema** (commit c92db6a): `data.domains`, `related[]`, hierarchy, `schema_version: '3'`.
- **V3 dataset wrapping** (commit c45fd28): `bibliography.yaml` is single-key mapping.
- **Non-verbal migration** (commit 4348b5a): figures one-per-file under `figures/`.
- **Multi-edition restructure**: E1 moved under `datasets/isotc204-2022/`.

## Branch / PR workflow

`main` is protected. All changes through PRs from feature branches. The
`publish-gcr.yml` workflow runs only on `v*` tags — never push tags; the user
decides releases.

## TODO.refactor/

Numbered work items tracking the multi-edition build-out. Each file has
status (todo / in-progress / done / deferred) and acceptance criteria. See
`TODO.refactor/00-overview.md` for the full plan.

## Unreferenced source images

52 of the 54 PNGs in `datasets/isotc204-2022/images/` are not referenced by any
concept. They are source — never delete. This is intentional signal (orphan-image
validation surfaces them), not cleanup targets. The never-delete-source rule is
absolute and overrides any "unused by code" reasoning.
