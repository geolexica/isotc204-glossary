# 01 — E1 restructure

**Phase:** A
**Status:** done
**Depends on:** nothing

## Goal

Move the existing 2022 dataset (E1) under `datasets/isotc204-2022/` so the repo
can host multiple editions as siblings. No content changes — files move verbatim
via `git mv` to preserve history.

## Why

The lineage-series layout requires per-edition directories. E1 must relocate
before E2/E3 arrive so the final shape is stable from the first commit.

## Tasks

- [x] Create `datasets/isotc204-2022/` directory
- [x] `git mv concepts/ datasets/isotc204-2022/concepts/`
- [x] `git mv bibliography.yaml datasets/isotc204-2022/bibliography.yaml`
- [x] `git mv figures/ datasets/isotc204-2022/figures/`
- [x] `git mv images/ datasets/isotc204-2022/images/`
- [x] `git mv register.yaml datasets/isotc204-2022/register.yaml`
- [x] Enrich `datasets/isotc204-2022/register.yaml` to v3 schema:
      `schema_type: glossarist`, `schema_version: "3"`, `id: isotc204-2022`,
      `urn: urn:iso:std:iso:ts:14812:2022`, `year: 2022`, `status: current`,
      `owner: ISO/TC 204`, `sourceRepo`, `languages: [eng]`,
      `ref: ISO/TS 14812:2022`
- [x] Update `.github/workflows/build.yml` — validates each `datasets/*`, packages each
- [x] Update `.github/workflows/publish-gcr.yml` — emits one GCR per dataset
- [x] Update `CLAUDE.md` to reflect new layout
- [ ] Verify: `glossarist validate datasets/isotc204-2022/` passes — **blocked by gem bug**, see Notes

## Acceptance criteria

- [x] All 319 concept files preserved with `git log --follow` history intact.
      (git status shows all 319 as `R` renamed entries.)
- [ ] `glossarist validate datasets/isotc204-2022/` exits 0 — **blocked**.
- [x] Top-level repo no longer has stray concept data files.
- [x] README and CLAUDE.md describe the new layout accurately.

## Notes

- The current top-level `register.yaml` is sparse and pre-v3-schema. Repurposing
  it as `datasets/isotc204-2022/register.yaml` preserves the file lineage while
  enriching its content.
- `urn:iso:std:iso:ts:14812:2022` keeps the original TS status of edition 1.
  E2/E3 drop the `ts` segment since ISO 14812 became a full standard.
- The 52 unreferenced PNGs in `images/` are source — never delete. They move
  with the dataset.
- **Gem bug discovered**: `glossarist validate` (v2.8.18) crashes with
  `NoMethodError: undefined method 'cite?' for an instance of Glossarist::BibliographicReference`
  in `Validation::Rules::CiteRefIntegrityRule#cite_mention_keys`. This is a
  pre-existing gem issue, not caused by the restructure (same data, same gem
  version would fail at HEAD before this PR). Tracked as a finding in TODO 19.
  Status will move to "verified" once the gem fix lands and validation runs clean.
