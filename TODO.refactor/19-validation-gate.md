# 19 — Validation gate

**Phase:** D
**Status:** done
**Depends on:** 15, 17

## Goal

A `rake validate` task runs `glossarist validate` against every dataset
directory. CI calls this on every PR. Pipeline runs invoke it after writing.

## Tasks

- [x] `Rakefile` `validate` task iterates `datasets/*`
- [x] Pipeline `#run` invokes validation at the end
- [x] CI runs `glossarist validate` per dataset
- [x] **Pre-existing gem bugs that blocked validation are fixed**
      (glossarist PR #190 — 4 commits, 4 regression specs):
  - UUID util: drop ActiveSupport `MatchData#present?`
  - `BibliographicReference`: add `cite?` / `local?` / `external?` predicates
  - `ConceptStore`: preserve YAML UUID when filename differs from UUID
  - `RelatedConceptCycleRule`: exclude cross-edition refs from intra-edition graph

## Acceptance criteria

- [x] `glossarist validate datasets/isotc204-2022/` exits VALID (warnings only)
- [x] `glossarist validate datasets/isotc204-2025/` exits VALID (warnings only)
- [x] `glossarist validate datasets/isotc204-ed3/` exits VALID (warnings only)

## Output (current state)

| Dataset | Result | Notable warnings |
|---------|--------|------------------|
| isotc204-2022 | VALID | 332× GLS-302 (sections), 54× GLS-021 (orphan images — intentional source files) |
| isotc204-2025 | VALID | 313× GLS-309, 312× GLS-302, 310× GLS-112, 289× GLS-306 |
| isotc204-ed3  | VALID | 967× GLS-112, 383× GLS-306, 383× GLS-302 |

Remaining warnings are converter quality follow-ups (TODO 23 retrospective).

## Notes

- Per global rule: NEVER push tags myself. The user does releases. The
  pipeline's validation step shells out to the gem CLI; when a new gem version
  is released with the four fixes from PR #190, CI will start passing
  without the local `rake install` workaround.
- Validation failures should produce a clear list of files + errors. If the
  gem's CLI doesn't do this, file an issue upstream.
