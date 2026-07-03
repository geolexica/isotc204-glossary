# 14 — Supersedes deriver

**Phase:** B
**Status:** todo
**Depends on:** 05, 11

## Goal

`Iso14812Import::SupersedesDeriver` walks two editions' concept collections
and adds `supersedes` edges to the newer edition's concepts, targeting the
older edition's clauses. Also computes `lineage_source_similarity` for each
newer concept, using the glossarist gem's `ConceptComparator`.

## Why

The lineage-series model derives `superseded_by` at render time from authored
`supersedes` edges. We only author the forward direction (new → old). The
derivation must run after both editions are built, since it needs both
collections in memory.

## Edge cases

| Situation                             | Action                                            |
|---------------------------------------|---------------------------------------------------|
| Clause exists in both, content same   | Add `supersedes` edge; `lineage_source_similarity: 100` |
| Clause exists in both, content differs| Add `supersedes` edge; similarity from comparator |
| New clause (no predecessor)           | No edge; similarity nil                            |
| Old clause with no successor          | Mark old concept `status: superseded`             |
| Clause collision (rare)               | Log warning, skip                                 |

## Interface

```ruby
class Iso14812Import::SupersedesDeriver
  def initialize(newer_edition:, older_edition:,
                 newer_concepts:, older_concepts:,
                 older_index:, newer_index:)
  end

  # Mutates newer_concepts (adds RelatedConcept to each) and returns the
  # array. Also marks withdrawn older_concepts in place.
  def derive! end
end
```

## Tasks

- [ ] Survey `Glossarist::ConceptComparator` API —
      `/Users/mulgogi/src/glossarist/glossarist-ruby/lib/glossarist/concept_comparator.rb`.
      Document the call signature in spec comments.
- [ ] `lib/iso14812_import/supersedes_deriver.rb`:
  - For each newer concept, find older concept by clause
  - If match: append `RelatedConcept.new(type: "supersedes",
    ref: ConceptRef.new(source: older_edition.urn, id: clause))` to newer's
    `data.related` (or top-level `related` per the model)
  - If match: compute similarity via ConceptComparator, set on localized
    concept's `data.lineage_source_similarity`
  - For older concepts with no successor: set `older.status = "superseded"`
- [ ] `spec/iso14812_import/supersedes_deriver_spec.rb`:
  - Two fixtures (3 older, 4 newer — 2 clauses overlap, 1 doesn't, 2 are new)
  - Assert: 2 newer concepts have `supersedes` edges
  - Assert: 1 older concept marked superseded
  - Assert: 2 new concepts have no supersedes edge
  - Assert: similarity scores are integers in [0,100]
  - Use real ManagedConcept instances, no doubles

## Acceptance criteria

- All overlap clauses get forward `supersedes` edges authored in the newer
  edition.
- All orphan older concepts get `status: superseded`.
- Similarity scores come from the glossarist gem, not hand-rolled heuristics.
- Round-trip: derived edges survive `ManagedConcept#from_yaml(to_yaml(...))`.

## Notes

- Only forward `supersedes` is authored. The browser derives `superseded_by`
  at render time. Authoring both is duplication.
- Similarity is a hint, not authoritative. If `ConceptComparator` is too slow
  for 300+ concepts, we can compute similarity lazily on first access (defer
  to runtime). For now, compute at import time and persist.
- The deriver is the only class that mutates concepts after the builder.
  Keep it isolated.
