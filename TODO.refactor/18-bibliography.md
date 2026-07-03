# 18 — Bibliography

**Phase:** D
**Status:** todo
**Depends on:** 01, 15

## Goal

Each edition has its own `bibliography.yaml` listing the normative references
cited in concept sources. E1 already has one (moved to
`datasets/isotc204-2022/bibliography.yaml` in TODO 01). E2 and E3 need their
own, derived from `<source>` elements / `History note:` lines / citation
strings encountered during import.

## Why

A `data.sources[].origin.ref.source` value like `"ISO/IEC TS29003:2018"` is
only useful if there's a matching bibliography entry to resolve the citation.
Cross-edition bibliography changes (a reference added in E2, dropped in E3)
are themselves meaningful provenance.

## Tasks

- [ ] Extract bibliography during parsing:
  - In `XmlParser`: collect all unique `<source>` text values
  - In `MarkdownParser`: collect all citation strings
- [ ] Add a `Iso14812Import::BibliographyBuilder` class that takes the
      collected citations and emits `Glossarist::BibliographyEntry` instances
- [ ] Writer (TODO 12) calls `write_bibliography(bib)` — already specced
- [ ] `datasets/isotc204-2025/bibliography.yaml` and
      `datasets/isotc204-ed3/bibliography.yaml` produced alongside concepts
- [ ] Validate: `glossarist validate` covers bibliography (verify in TODO 19)

## Acceptance criteria

- Each edition has a `bibliography.yaml` listing every cited reference
- Bibliography entries are wrapped under a single `bibliography:` key
  (V3 dataset syntax per commit c45fd28 — no top-level arrays)
- Entries round-trip via `Glossarist::BibliographyEntry.from_yaml`

## Notes

- The V3 single-key wrapping (commit c45fd28) is intentional — don't regress.
- Bibliography is small (10-30 entries per edition), so in-memory array is fine.
