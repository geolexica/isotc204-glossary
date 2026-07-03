# 03 — Document IR

**Phase:** B
**Status:** done
**Depends on:** 02

## Goal

Define the intermediate `Iso14812Import::Document` value object that both
parsers (XML for E2, Markdown for E3) produce. Downstream stages operate on
`Document` exclusively — they never know which parser produced it.

## Why

Open/closed: two parsers (soon three) producing one IR means the model-builder,
writer, and pipeline are parser-agnostic. Adding E4 means adding a parser, not
touching downstream code.

## Shape

```ruby
Iso14812Import::Document = Struct.new(:edition, :clause, :guid, :name,
  :alt_names, :definition_html, :definition_markdown, :examples, :notes,
  :sources, :relationships, :specializations, :figures, :breadcrumb_sections,
  :history_notes) do
  # behavior methods, no state mutation
end
```

Fields:

| Field                  | Type                    | Source                                |
|------------------------|-------------------------|---------------------------------------|
| `edition`              | `Edition`               | Configuration (TODO 04)               |
| `clause`               | `String`                | `3.1.1.5`                             |
| `guid`                 | `String` or `nil`       | E2 XML `<guid>` (absent in E3)        |
| `name`                 | `String`                | Preferred designation                 |
| `alt_names`            | `Array<String>`         | Admitted/deprecated synonyms          |
| `definition_html`      | `String` or `nil`       | E2 CDATA HTML                         |
| `definition_markdown`  | `String` or `nil`       | E3 markdown body                      |
| `examples`             | `Array<String>`         | Rendered-text examples                |
| `notes`                | `Array<String>`         | Ordered notes ("Note 1 to entry")     |
| `sources`              | `Array<SourceCitation>` | Original bibliographic citations      |
| `relationships`        | `Array<RawRelationship>`| OWL predicate → target                |
| `specializations`      | `Array<Specialization>` | Subclass-with-description rows        |
| `figures`              | `Array<FigureRef>`      | `<object>` or `<figure>` references   |
| `breadcrumb_sections`  | `Array<String>`         | E.g. `["3.1", "3.1.1"]` for domains   |
| `history_notes`        | `Array<HistoryNote>`    | Parsed "History note:" lines          |

Supporting value objects (also structs):

- `SourceCitation = Struct.new(:raw_text, :source_ref, :clause, :link, :type)`
- `RawRelationship = Struct.new(:predicate, :target_name, :constraint, :description)`
- `Specialization = Struct.new(:target_name, :description)`
- `FigureRef = Struct.new(:src, :alt, :caption)`
- `HistoryNote = Struct.new(:year, :kind, :text)` — `kind` ∈ `[:introduced, :revised, :withdrawn, :other]`

The `definition_html` vs `definition_markdown` distinction lets the
`ContentConverter` (TODO 08) pick the right coradoc input format.

## Tasks

- [ ] Write `lib/iso14812_import/document.rb` with `Document` struct + behavior
- [ ] Write `lib/iso14812_import/document_section.rb` for the section helpers
      (or fold into `Document`)
- [ ] Write `spec/iso14812_import/document_spec.rb`:
  - Construct a `Document` from struct literal
  - Accessors work
  - `definition` method returns whichever definition field is populated
  - `valid?` predicate (clause + name + some definition present)
- [ ] Specs use real structs, no doubles

## Acceptance criteria

- `Document.new(...)` accepts all listed fields.
- `Document#definition` returns `definition_markdown` if present, else
  `definition_html`, else `nil`.
- `Document#has_definition?` truthy iff either definition field is non-empty.
- Spec passes; code is `Struct`-based (no class with hand-rolled `to_h`).

## Notes

- The IR intentionally has separate fields for HTML vs Markdown definitions
  because E2 and E3 use different source formats. This is honest about the
  input. The ContentConverter (TODO 08) normalizes both to AsciiDoc.
- `guid` is E2-specific but kept on the IR so cross-edition resolution can use
  it as a fallback identifier when clause numbers shift between editions.
