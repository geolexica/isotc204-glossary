# 09 — Relationship mapper

**Phase:** B
**Status:** todo
**Depends on:** 03

## Goal

`Iso14812Import::RelationshipMapper` translates source-native relationship
predicates (OWL predicates from E3 Turtle, `<a>` typing from E2 prose) into
the 52 v3 relationship types defined in
`Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES`.

For predicates with no clean v3 equivalent (e.g. `canControl`,
`performsAllOf`), preserves the original predicate as `content` on a generic
`related_concept` relationship — lossless but explicit about non-equivalence.

## Why

The 52 v3 relationship types come from ISO standards (10241-1, 25964, 19135,
12620, TBX). OWL predicates in the iso14812 ontology are domain-specific and
don't map 1:1. Pretending they do would lie about semantic equivalence.
Using the predicate name as content preserves the data without false claims.

## Mapping table

| Source predicate  | v3 type              | Notes                                    |
|-------------------|----------------------|------------------------------------------|
| `subClassOf`      | `broader`            | Direct hierarchy                         |
| `subClassOf` (some instance) | `broader_instantial` | When constraint is `some`/`instance_of`  |
| `partOf`          | `is_part_of`         | Partitive                                |
| `hasPart`         | `has_part`           | Partitive inverse                        |
| `realizationOf`   | `related_concept`    | No clean ISO mapping; preserve as label  |
| `canControl`      | `related_concept`    | Domain-specific                          |
| `performsAllOf`   | `related_concept`    | Domain-specific                          |
| `involves`        | `related_concept`    | Domain-specific                          |
| `references`      | `references`         | Direct mapping                           |
| `see`             | `see`                | Direct mapping                           |
| `replaces`/`replaced_by` | `replaces`/`replaced_by` | Direct mapping                  |
| Specialization table row | `narrower`     | Each row carries `content: description`  |

## Interface

```ruby
class Iso14812Import::RelationshipMapper
  PREDICATE_MAP = {
    "subClassOf" => { type: "broader" },
    "partOf"     => { type: "is_part_of" },
    # ...
  }.freeze

  def self.map(raw_predicate, target_clause:, description: nil, constraint: nil)
    # Returns a hash suitable for Glossarist::RelatedConcept.new(**hash)
  end
end
```

## Tasks

- [ ] `lib/iso14812_import/relationship_mapper.rb`:
  - `PREDICATE_MAP` constant — frozen hash
  - `.map(...)` returns `{type:, ref: {source:, id:}, content:}`
  - Unknown predicates → `{type: "related_concept", content: raw_predicate}`
- [ ] `spec/iso14812_import/relationship_mapper_spec.rb`:
  - All entries in PREDICATE_MAP produce valid v3 types
  - Unknown predicate preserves its name in `content`
  - Description is preserved when provided
  - Constraint text is appended to content if non-trivial
- [ ] Validate that every type in PREDICATE_MAP values is in
      `Glossarist::GlossaryDefinition::RELATED_CONCEPT_TYPES` — guard against
      typos at boot

## Acceptance criteria

- All 12+ mapped predicates produce valid `Glossarist::RelatedConcept` objects.
- Unknown predicates do not raise — they fall through to `related_concept`.
- A spec asserts the PREDICATE_MAP value types are a subset of the gem's
  allowed types.

## Notes

- This is the canonical place to extend when a new iso14812 predicate shows up.
  Adding a mapping = one line in `PREDICATE_MAP`. Open/closed.
- The Turtle ontology will likely have predicates we haven't seen yet. Survey
  them during TODO 16 (markdown parser) and update this map.
- Constraint text (`some X`, `min 2`, `only X`) is OWL quantification. The v3
  model has no cardinality/quantification fields, so it lives in `content`.
