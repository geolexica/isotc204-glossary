# 11 — Concept builder

**Phase:** B
**Status:** done
**Depends on:** 03, 08, 09, 10

## Goal

`Iso14812Import::ConceptBuilder` turns one `Document` into a fully-populated
`Glossarist::ManagedConcept` instance. Uses the glossarist gem's model classes
directly — never builds hashes for serialization.

## Why

This is where the source-neutral IR meets the framework-specific model. Single
responsibility: IR → model. No I/O, no parsing, no relationship mapping (those
have their own classes). The builder calls `ContentConverter`,
`RelationshipMapper`, `FigureRegistry` as collaborators.

## Interface

```ruby
class Iso14812Import::ConceptBuilder
  def initialize(edition:, content_converter:, figure_registry:) end

  # @param document [Iso14812Import::Document]
  # @return [Glossarist::ManagedConcept]
  def build(document) end
end
```

## Build logic

For each `Document`:

1. Convert `definition_html` or `definition_markdown` → AsciiDoc via
   `content_converter`. Wrap in `Glossarist::DetailedDefinition.new(content:)`.
2. Convert each example/note similarly.
3. Build designations:
   - Preferred: `Glossarist::Designation::Expression.new(
       designation: doc.name, normative_status: "preferred", type: "expression")`
   - Alt names: `normative_status: "admitted"` each
4. Build sources from `Document#sources` — parse each citation text into
   `Glossarist::ConceptSource.new(type: "authoritative", origin: Citation.new(ref: ...), modification: ...)`.
   Source text parsing is itself non-trivial — see "Source parser" below.
5. Build relationships via `RelationshipMapper.map(...)` for each
   `Document#relationships` and `Document#specializations`.
6. Build localized concept:
   ```ruby
   lc = Glossarist::LocalizedConcept.new(
     language_code: "eng",
     entry_status: "valid",
     data: Glossarist::ConceptData.new(
       terms: designations,
       definition: definitions,
       examples: examples,
       notes: notes,
       sources: sources,
       lineage_source_similarity: nil,    # set by SupersedesDeriver
     ),
   )
   lc.uuid = deterministic_uuid(edition, clause)
   ```
7. Build managed concept:
   ```ruby
   mc = Glossarist::ManagedConcept.new(
     status: "valid",
     schema_version: "3",
     data: Glossarist::ManagedConceptData.new(
       identifier: clause,
       localized_concepts: { "eng" => lc.uuid },
       domains: domain_refs(edition, document),
       sources: concept_level_sources,
       localizations: [lc],
     ),
   )
   mc.uuid = deterministic_uuid(edition, clause)
   ```

### Source parser subtask

`Document#sources` arrives as raw citation strings like
`"ISO/IEC TS29003:2018, 3.12, modified to add reference to biological entity definition"`.
Parse into:
- `ref.source` = `ISO/IEC TS29003:2018`
- `locality.reference_from` = `3.12`
- `status` = `modified` (or `identical`)
- `modification` = `"...add reference to biological entity definition"`

A separate `Iso14812Import::SourceParser` class handles this with a regex
cascade. Single responsibility, testable in isolation.

## Tasks

- [ ] `lib/iso14812_import/source_parser.rb` — citation text →
      `Glossarist::ConceptSource` parts
- [ ] `spec/iso14812_import/source_parser_spec.rb` — covers 5+ citation shapes
- [ ] `lib/iso14812_import/concept_builder.rb` per the build logic above
- [ ] `spec/iso14812_import/concept_builder_spec.rb`:
  - Builds a ManagedConcept from a fixture Document
  - Localized concept has correct language_code, entry_status
  - Designations include preferred + admitted
  - Definition is converted AsciiDoc wrapped in DetailedDefinition
  - Sources parsed correctly
  - Relationships mapped via RelationshipMapper
  - Domains derived from breadcrumb sections
  - UUIDs are deterministic (same clause + edition → same UUID)
- [ ] Verify `deterministic_uuid` uses UUIDv5 with the edition URN as namespace
      and the clause as name. This guarantees stability across runs.

## Acceptance criteria

- `ConceptBuilder.new(...).build(document)` returns a `ManagedConcept` that
  round-trips through `ManagedConcept.from_yaml(mc.to_yaml)` without loss.
- All nested objects (`LocalizedConcept`, `ConceptData`, `DetailedDefinition`,
  `ConceptSource`, `RelatedConcept`, `Designation::*`) are real glossarist gem
  instances.
- No `to_h`, `to_hash`, `to_yaml` overrides anywhere in our code.
- UUIDs are deterministic per `(edition.urn, clause)`.

## Notes

- The glossarist gem already has `Utilities::UUID.uuid_v5(name, namespace)` —
  use it. Don't roll our own UUID.
- Domain refs: the breadcrumb `[3.1, 3.1.1]` becomes
  `[{concept_id: "3.1.1", source: edition.urn, ref_type: "section"}]`
  pointing at the leaf section. We can also include intermediate sections if
  the v3 model supports it (it does).
- E2 source texts are free-form — `SourceParser` will hit many edge cases.
  Budget time for iteration.
