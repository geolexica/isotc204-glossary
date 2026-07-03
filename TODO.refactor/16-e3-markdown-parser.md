# 16 — E3 markdown parser

**Phase:** C
**Status:** done
**Depends on:** 03, 06, 08

## Goal

`Iso14812Import::Parsers::MarkdownParser` walks E3's `docs/terms/*.md` files
at iso14812 HEAD and emits one `Document` per file. Uses coradoc for
markdown parsing where appropriate, but extracts structural fields (clause,
notes, history notes, relationship tables) via section-splitter logic first
since the markdown structure is highly regular.

## Why

E3 source is markdown + a Turtle ontology. The markdown structure
(breadcrumbs, headings, `Clause:` lines, `Note N to entry:`, `History note:`,
`## Relationships for X` tables, `## Specializations of X` tables) is regular
enough that a section splitter is more reliable than full AST traversal.

## Interface

Same as `XmlParser`:

```ruby
class Iso14812Import::Parsers::MarkdownParser < Base
  def initialize(edition:, terms_dir:) end  # terms_dir = path to docs/terms/
  def each_document(&block) end
end
```

## Section splitter state machine

For each markdown file:

1. Strip first line (breadcrumb) and last 2 lines (separator + comment link)
2. Walk remaining lines, transition state on:
   - `^# (.*)$` → capture title
   - `^Clause: (.*)$` → capture clause
   - `^Alternative preferred term: (.*)$` → alt name
   - `^Note (\d+) to entry: (.*)$` → note
   - `^History note: (.*)$` → history note (parse year/kind inline)
   - `^<object` ... `^</object>` → figure reference (multiline)
   - `^## Specializations of ` → enter specialization-table state
   - `^## Relationships for ` → enter relationship-table state
   - `^---$` → end of body
3. The "definition prose" is everything between the title and the first
   recognized directive line. Capture as `definition_markdown`.

## Tasks

- [ ] `lib/iso14812_import/parsers/markdown_parser.rb`:
  - `#each_document` walks `terms_dir/*.md`, calls `parse_file(path)` per file
  - `#parse_file` runs the state machine, returns a `Document`
  - History note parsing: `"2025: Revised to be..."` → `(year: 2025, kind: :revised, text: "...")`
  - Table parsing: rows become `RawRelationship` / `Specialization`
- [ ] `spec/iso14812_import/parsers/markdown_parser_spec.rb`:
  - Fixture: 3 hand-crafted markdown files covering (a) minimal, (b) full with
    tables, (c) edge case (no history notes)
  - Assert each Document field
  - Real-file smoke test: parse all 386 terms, count Documents, spot check
- [ ] Also inspect Turtle files to extract any relationships not visible in
      markdown (e.g. formal `subClassOf` declarations). Optional — markdown
      may already duplicate these.

## Acceptance criteria

- `MarkdownParser.new(edition:, terms_dir:).documents.length` matches the
  count of `*.md` files in `terms_dir`.
- All structural fields populated when present in source.
- Tables parse without crashes on edge cases (empty cells, escaped pipes).
- History note year/kind extraction works for the 4 patterns documented in
  TODO 06 census (revised / introduced / withdrawn / other).

## Notes

- The E3 markdown is itself generated from the Turtle ontology. For maximum
  fidelity, parsing the Turtle directly may give better relationship data
  than the markdown tables. Survey this during execution; if Turtle is richer,
  add a `TurtleParser` and merge its output with the markdown parser's. Both
  still produce `Document` IR — open/closed.
- Some E3 terms have an `<object type="image/svg+xml">` block between the
  title and definition; others between definition and Clause. The splitter
  must be tolerant of position.
- Coradoc is not used in the splitter itself — it's used later by
  `ContentConverter` on the captured `definition_markdown`. The splitter's
  job is to identify the boundaries of `definition_markdown`, not to parse
  its content.
