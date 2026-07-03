# 15 — E2 import execution

**Phase:** B
**Status:** done (modulo gem validation bug)
**Depends on:** 06, 07, 08, 09, 10, 11, 12, 13, 14, 04

## Goal

Run the pipeline end-to-end against E2 source at iso14812 commit `dfe7e9d4`,
producing `datasets/isotc204-2025/` with all E2 concepts and forward
`supersedes` edges to E1 concepts.

## Tasks

- [x] Confirm `git -C ~/src/external/iso14812 cat-file -t dfe7e9d4` reports `commit`
- [x] Pipeline extracts the file via `git show ref:path`
- [x] Run `bundle exec ruby -Ilib scripts/import_iso14812.rb \
        --edition config/editions/isotc204-2025.yml \
        --previous config/editions/isotc204-2022.yml`
- [x] Output: 313 concepts, 24 bibliography entries, 310 supersedes edges
- [x] 9 E1 concepts flagged as withdrawn in summary (write-back to disk is
      a separate concern; the deriver reports but does not mutate the prior
      edition's files — the browser derives `superseded_by` at render time)
- [x] Spot-checked 5+ output files; multi-doc YAML format matches E1
- [x] File naming by clause ID (3.1.1.1.yaml, etc.) per user direction
- [ ] `glossarist validate datasets/isotc204-2025/` — **blocked by pre-existing gem bug** (TODO 19)

## Output summary

```
Edition:        isotc204-2025
Previous:       isotc204-2022
Concepts:       313
Figures:        0       (figures inside E2 XML not yet wired — see TODO 10 notes)
Bibliography:   24
Supersedes:     310 edges
Withdrawn:      9 older concepts marked
```

## Acceptance criteria

- [x] `datasets/isotc204-2025/concepts/` contains 313 files (one per E2 `<term>`)
- [x] Multi-doc YAML: managed concept + localized concept per file
- [x] Clause IDs as filenames (3.1.1.1.yaml)
- [x] Supersedes edges present (`type: supersedes`, `ref.source: urn:iso:std:iso:ts:14812:2022`)
- [x] Re-running is idempotent (same input → same output bytes)
- [ ] `glossarist validate` passes — blocked by gem bug

## Notes

- 9 E1 concepts are flagged as withdrawn but their on-disk status is not
  mutated. The browser's render-time derivation of `superseded_by` from
  forward `supersedes` handles this; no write-back to E1 is needed.
- 3 E2 concepts have no E1 predecessor (genuinely new in E2) — they have no
  supersedes edge, correctly.
- Figures embedded in E2 XML's `<package><figure>` blocks aren't yet
  registered. TODO 10 spec needs to extend XmlParser to call
  `figure_registry.register(...)` for these. Not blocking — figures are a
  secondary representation.
