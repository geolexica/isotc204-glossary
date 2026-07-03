# 21 — Docs updates

**Phase:** D
**Status:** done
**Depends on:** 15, 17

## Goal

Update `README.adoc` and `CLAUDE.md` to accurately describe the multi-edition
lineage-series layout, the converter, the spec suite, and the developer
workflow.

## Tasks

- [x] `README.adoc`:
  - "Repository structure" shows `datasets/` layout
  - "Editions" section listing the three editions with concept counts and
    validation status
  - "Cross-edition `supersedes`" section with example
  - "Converter" section: lib/ layout, autoload structure, how to extend
  - Common commands: `bundle exec rake validate`, `bundle exec rspec`,
    `bundle exec ruby -Ilib scripts/import_iso14812.rb`
  - Dropped the stale `images.yaml` mention
- [x] `CLAUDE.md`:
  - Layout section reflects the new structure
  - Editions section listing the three editions
  - Converter section: lib/ layout, autoload structure, how to extend
  - Common commands updated
  - Note that never-delete-source rule applies to generated dataset files
    too (they are committed, not regenerated on every build)

## Acceptance criteria

- [x] README accurately describes what's in the repo
- [x] CLAUDE.md is sufficient for a fresh Claude Code session to be productive
  without re-discovering the layout

## Notes

- README is the public-facing entry point; CLAUDE.md is the Claude-facing
  entry point. Both need to be accurate post-restructure.
- The TODO.refactor/ directory itself is documented in both files as the
  durable plan of record.
