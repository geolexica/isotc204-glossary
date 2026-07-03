# 21 — Docs updates

**Phase:** D
**Status:** todo
**Depends on:** 15, 17

## Goal

Update `README.adoc` and `CLAUDE.md` to accurately describe the multi-edition
lineage-series layout, the converter, the spec suite, and the developer
workflow.

## Why

Future contributors (human or Claude) need an accurate map. The current docs
describe a single-dataset repo; that's about to be wrong. Per the global rule
about never deleting source files, README and CLAUDE.md updates are pure
edits, not removals.

## Tasks

- [ ] `README.adoc`:
  - Update "Repository structure" to show `datasets/` layout
  - Add "Editions" section listing the three editions and their sources
  - Add "Lineage series" section explaining `supersedes` edges
  - Add "Converter" section: how to run `bundle exec scripts/import_iso14812.rb`
  - Drop the stale `images.yaml` mention (already noted in CLAUDE.md)
- [ ] `CLAUDE.md`:
  - Update the layout section
  - Add an "Editions" section listing the three editions
  - Add a "Converter" section: lib/ layout, autoload structure, how to extend
  - Update "Common commands" to include `bundle exec rake validate`,
    `bundle exec rspec`, `bundle exec scripts/import_iso14812.rb`
  - Note the never-delete-source rule applies to generated dataset files too
    (they are committed, not regenerated on every build)

## Acceptance criteria

- README accurately describes what's in the repo
- CLAUDE.md is sufficient for a fresh Claude Code session to be productive
  without re-discovering the layout

## Notes

- These updates land last, after the data is in place. Writing them earlier
  risks documenting a plan that didn't survive execution.
