# 00 — Overview

## Goal

Turn this repository into a multi-edition lineage-series dataset for ISO/TC 204
ITS vocabulary (ISO 14812), with three editions co-existing under `datasets/`
and cross-edition `supersedes` relationships wiring them into a navigable
timeline on https://isotc204.geolexica.org.

## Editions

| Edition          | Concepts | Source                                            | Status     |
|------------------|----------|---------------------------------------------------|------------|
| `isotc204-2022`  | 319      | Pre-imported (originally MLGT spreadsheet)        | superseded |
| `isotc204-2025`  | 313      | `14812 - Vocabulary.xml` @ `dfe7e9d4` (XML)       | superseded |
| `isotc204-ed3`   | 384      | `docs/terms/*.md` + `docs/*.ttl` @ HEAD (markdown)| current    |

**Cross-edition edges**:
- E2 → E1: 310 `supersedes` edges, 9 E1 concepts marked withdrawn
- E3 → E2: 301 `supersedes` edges, 12 E2 concepts marked withdrawn

## Architectural principles (applied throughout)

1. **Model-driven.** Every concept is a `Glossarist::ManagedConcept`. No
   hand-rolled `to_yaml` / `to_h` / `to_hash` anywhere in `lib/`.
2. **Open/closed.** Adding E4 = new parser file + edition config. No edits
   to `ConceptBuilder`, `Writer`, `Pipeline`, or `SupersedesDeriver`.
3. **MECE.** Each class has one responsibility (parsing, IR, building, writing,
   edge derivation, orchestration). 14 classes across `lib/iso14812_import/`.
4. **DRY.** E2 (XML) and E3 (markdown) parsers both produce the same `Document`
   IR. Downstream stages are parser-agnostic.
5. **Performance.** Single-pass parsers, in-memory indexes, lazy autoloads.
6. **No forbidden idioms.** Verified by grep: no `send` to privates, no
   `instance_variable_set/get`, no `respond_to?` for typing, no `require_relative`
   inside the library (autoload only).

## Specs

50 examples, 0 failures. Real `Glossarist::*` instances or `Struct` value
objects — no `double()`. Every public class has a spec.

## Status summary

| TODO                              | Phase | Status        |
|-----------------------------------|-------|---------------|
| 01-e1-restructure                 | A     | done*         |
| 02-project-skeleton               | B     | done          |
| 03-document-ir                    | B     | done          |
| 04-edition-config                 | B     | done          |
| 05-source-index                   | B     | done          |
| 06-e2-xml-investigation           | B     | done          |
| 07-e2-xml-parser                  | B     | done          |
| 08-content-converter              | B     | done          |
| 09-relationship-mapper            | B     | done          |
| 10-figure-registry                | B     | partial (E2 figures not yet wired) |
| 11-concept-builder                | B     | done          |
| 12-writer                         | B     | done          |
| 13-pipeline                       | B     | done          |
| 14-supersedes-deriver             | B     | done          |
| 15-e2-import-execution            | B     | done*         |
| 16-e3-markdown-parser             | C     | done          |
| 17-e3-import-execution            | C     | done*         |
| 18-bibliography                   | D     | done (E2); not yet for E3 (no source lines in markdown) |
| 19-validation-gate                | D     | blocked by gem bug — see note below |
| 20-ci-updates                     | D     | done          |
| 21-docs-updates                   | D     | done (CLAUDE.md); README pending |
| 22-deployment-separate-repo       | E     | deferred (separate repo, separate PR) |
| 23-architecture-retrospective     | —     | partial (notes below) |

`*` = output is structurally correct; `glossarist validate` cannot run clean
because of two pre-existing bugs in glossarist 2.8.18:
- `cite_ref_integrity_rule` calls `BibliographicReference#cite?` (undefined)
- `Utilities::UUID.pack_uuid_namespace` calls `MatchData#present?` (ActiveSupport dependency)

Both are filed for upstream fix. The data is valid against the v3 schema; the
gem's validation CLI itself is broken.

## Phase ordering (as executed)

1. **Phase A — E1 restructure** (TODO 01). ✓ complete
2. **Phase B — E2 import** (TODOs 02–15). ✓ complete
3. **Phase C — E3 import** (TODOs 16–17). ✓ complete
4. **Phase D — Cross-cutting** (TODOs 18–21). Mostly complete.
5. **Phase E — Deployment** (TODO 22). Deferred — separate repo.

## Architecture retrospective (summary; full notes in TODO 23)

### Worked well
- Document IR as the parser-neutral intermediate. Both E2 (XML) and E3
  (markdown) parsers produce identical-shape structs; downstream code is
  parser-blind.
- `ConceptDocument.from_managed_concept(...).to_yamls` produces correct
  multi-doc YAML via the gem — no hand-rolling.
- Deterministic UUIDv5 from `(edition.urn, clause)` gives stable identifiers
  across re-runs → idempotent output.
- Forward-only `supersedes` edges (browser derives inverse) keeps authoring
  minimal.
- Spec suite catches regressions fast (50 examples in 25ms).

### Didn't work well / needs follow-up
- The glossarist gem has two pre-existing bugs (cited above) that block the
  validation gate. Need upstream fixes.
- E2 figures (`<package><figure>` blocks in XML) aren't yet wired to
  `FigureRegistry`. XmlParser needs an extension for figure collection.
- E3 markdown splitter leaves trailing footer noise in some definitions
  (`<object>` close tag, `---` separator). Quality issue, not architectural.
- Cross-edition similarity scoring is stubbed (ConceptComparator's API needs
  investigation). All lineage_source_similarity fields are currently nil.
- Bibliography is empty for E3 because E3 markdown has no `<source>` lines —
  would need to mine the Turtle ontology for citation data.

### Global-rule candidates
- "Use the framework's `ConceptDocument`-style wrapper for multi-doc YAML
  streams" — applies to any lutaml-model class with multi-document output.
  Don't hand-stitch YAML streams.
