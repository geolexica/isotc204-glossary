# 23 — Architecture retrospective

**Phase:** —
**Status:** done
**Depends on:** 17

## Goal

After the converter is running and all three editions are in place, write a
retrospective capturing what worked, what didn't, and what should be improved
next. This is the "always think about architecture" loop closing.

## Worked well

- **`Document` IR as the parser-neutral intermediate.** Both E2 (XML) and E3
  (markdown) parsers produce identical-shape Structs; downstream code
  (ConceptBuilder, Writer, SupersedesDeriver) is parser-blind. Adding a new
  source format = new parser file + edition config. No edits to downstream.
- **`ConceptDocument.from_managed_concept(...).to_yamls`** produces correct
  multi-doc YAML via the gem — no hand-stitched YAML streams.
- **Deterministic UUIDv5** from `(edition.urn, clause)` gives stable
  identifiers across re-runs → idempotent output, clean git diffs.
- **Forward-only `supersedes` edges** (browser derives inverse) keeps
  authoring minimal and matches the model.
- **Spec suite catches regressions fast** — 55 examples in ~25ms.
- **V3 class hierarchy throughout.** Critical insight: the validator loads
  via `V3::ConceptDocument`, so building with the top-level (legacy) classes
  loses the UUID-vs-identifier distinction. Fixed early; specs would have
  caught it.
- **Two-PR strategy** (gem fixes in PR #190, dataset work in PR #33) kept
  review scope manageable.

## Didn't work well / needs follow-up

### Glossarist gem blockers

Four bugs in glossarist 2.8.18 had to be fixed before validation could run
cleanly:

1. `Utilities::UUID.pack_uuid_namespace` called ActiveSupport's
   `MatchData#present?` (ActiveSupport not a declared dependency).
2. `BibliographicReference` lacked `#cite?`, crashing
   `CiteRefIntegrityRule` on any concept with bib references.
3. `ConceptDocumentSerializer#deserialize` clobbered YAML UUIDs with
   filename-derived ids (filename-as-record-key under grouped layout).
4. `RelatedConceptCycleRule#resolve_target_id` returned `ref.id || ref.source`
   — a cross-edition `supersedes 3.1.1.1` looked like an intra-edition
   self-loop.

All four are fixed in PR #190 with regression specs. **Lesson**: the gem had
clearly never been exercised against a real cross-edition dataset before.
Future gem work should consume this repo (or similar) as an integration test.

### Converter quality follow-ups

- **E2 figure registration not wired.** `XmlParser` doesn't yet call
  `figure_registry.register(...)` for `<package><figure>` blocks. These are
  package-level (section) diagrams, not concept-level — would need a model
  for "shared figures" or per-concept references via AsciiDoc xref.
- **`lineage_source_similarity` is `nil` everywhere.** The
  `Glossarist::ConceptComparator` API wasn't investigated deeply enough to
  wire safely. Currently SupersedesDeriver has a guarded call but always
  produces nil.
- **GLS-302 warnings (~1000 total).** Each edition's `register.yaml` lacks
  a `sections:` block declaring the section hierarchy that concepts reference
  via `data.domains[].concept_id`. Adding sections is a content authoring
  task (low architectural interest, high tedium).
- **GLS-306 warnings (~1000 total on E3).** "No authoritative source defined."
  E3 markdown has no source citation lines (see TODO 18).
- **Markdown cross-reference resolution for specialization tables.** The
  target_name has raw markdown link syntax (e.g.
  `[ADS-dedicated vehicle](ADS-dedicated vehicle.md)`). A 2-pass parser
  resolving filenames → clauses would produce cleaner refs.

### Process observations

- **Hand-stitched YAML is the wrong instinct.** The first version of the
  writer manually joined per-doc YAML. Switching to
  `ConceptDocument#to_yamls` was a one-line fix that solved multiple bugs
  at once. **Always look for the framework-provided serialization path
  before writing your own.**
- **The never-delete-source rule applied to itself.** The 52 unreferenced
  PNGs in `images/` triggered orphan-image warnings — exactly the signal
  the validator is supposed to send. Don't suppress them; don't act on
  them either.
- **`send` to privates / `instance_variable_set` are non-issues with
  autoload + lutaml-model.** The discipline of "use the framework" makes
  the forbidden idioms irrelevant because they never come up.

## Global-rule candidates surfaced

Two patterns from this work seem generalizable enough to be global rules:

1. **"Use the framework's multi-doc wrapper when it exists."** For lutaml-model
   classes with multi-document YAML output (ConceptDocument here, possibly
   others), use the dedicated wrapper class's `to_yamls` / `from_yamls`. Never
   hand-stitch YAML streams with `---` separators and `.join`.

2. **"Cross-dataset / cross-edition references are qualified by URN."** Any
   validation rule, cycle detector, or graph algorithm that walks
   `related[]` must distinguish intra-dataset edges (ref.source is nil) from
   cross-dataset edges (ref.source is a URN). The two cannot be mixed in the
   same graph without false positives.

## Concrete improvement TODOs for the next iteration

- `Iso14812Import::Parsers::XmlParser#each_document` should accept a
  `figure_registry:` collaborator and call `register(...)` for each
  `<figure>` element encountered in a package. The figures would be added
  to each term's `Document#figures` in that package.
- A `MentionResolver` class that runs AFTER SourceIndex is built, walks each
  Document's specializations/relationships/definition, and resolves raw
  markdown link syntax to clause IDs. This would clean up E3 specialization
  targets and enable proper narrower-edge resolution.
- A `SectionTreeBuilder` that derives the `sections:` block for register.yaml
  from the breadcrumbs observed during parsing. Would silence GLS-302.
- `ConceptComparator` integration for real similarity scoring, replacing the
  stub in `SupersedesDeriver#set_similarity`.

## What to read next

If you're picking up this codebase cold:

1. `TODO.refactor/00-overview.md` for the big picture
2. `lib/iso14812_import/pipeline.rb` for the run order
3. `lib/iso14812_import/document.rb` for the IR shape (the parser-neutral
   intermediate that everything downstream consumes)
4. `lib/iso14812_import/concept_builder.rb` for how the IR meets the
   glossarist gem's V3 model classes
5. `spec/iso14812_import/` for executable examples of each class's behavior
