# 18 — Bibliography

**Phase:** D
**Status:** done (E2); won't-do (E3 — no source data)
**Depends on:** 01, 15

## Goal

Each edition has its own `bibliography.yaml` listing the normative references
cited in concept sources.

## Outcome

| Edition | Bibliography entries | Source |
|---------|----------------------|--------|
| isotc204-2022 | pre-existing | MLGT spreadsheet import |
| isotc204-2025 | 24 | `<source>` elements in E2 XML |
| isotc204-ed3  | 0 | E3 markdown has no `<source>` lines |

## Why E3 bibliography is empty

E3 markdown term files (`docs/terms/*.md` in iso14812) do not carry explicit
source citation lines. Each term has a `History note:` (provenance text) and
clause reference, but no structured `<source>` element. The Turtle ontology
(`docs/*.ttl`) also does not contain bibliographic citations — it's a pure
UML/OWL model.

To populate E3's bibliography, we would need to either:
- Mine the bibliography from the ISO 14812 standard document itself (out of
  scope — the standard isn't in source form here)
- Add source lines to the markdown upstream in the iso14812 repo (an
  editorial decision, not a converter concern)

Both are out of scope for this PR series. Marking the E3 bibliography as a
follow-up rather than blocking.

## Tasks

- [x] Extract bibliography during parsing:
  - In `XmlParser`: collect all unique `<source>` text values ✓
  - In `MarkdownParser`: collect all citation strings (none in E3 — empty)
- [x] `Iso14812Import::BibliographyBuilder` collects `Glossarist::BibliographyEntry`
- [x] Writer calls `write_bibliography(bib)` per dataset
- [x] `datasets/isotc204-2025/bibliography.yaml` produced
- [x] E3 bibliography is correctly empty (no source data to extract)

## Acceptance criteria

- [x] E1 keeps its existing bibliography.yaml (untouched)
- [x] E2 has `bibliography.yaml` with 24 entries, single-key wrapped
      (V3 dataset syntax)
- [x] E3 has no `bibliography.yaml` (no entries — `Writer#write_bibliography`
      returns 0 and writes nothing)
- [x] Entries round-trip via `Glossarist::BibliographyEntry.from_yaml`

## Notes

- The V3 single-key wrapping (`bibliography:` top-level key) is via
  `Glossarist::BibliographyData` model — never hand-rolled.
- If E3 sources become available later (e.g. added to iso14812 markdown
  upstream), the converter picks them up automatically via `MarkdownParser`'s
  existing citation extraction path. No code change needed — only a re-run.
