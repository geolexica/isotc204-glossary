# 07 — E2 XML parser

**Phase:** B
**Status:** todo
**Depends on:** 03, 06

## Goal

`Iso14812Import::Parsers::XmlParser` walks the E2 vocabulary XML tree and
emits one `Document` per `<term>` element, with parent-package breadcrumbs
captured for the domain hierarchy.

## Why

E2 is XML — the source format is fundamentally different from E3 markdown.
This parser is the E2-specific adapter; it produces the same `Document` IR
that the markdown parser produces, so downstream stages are shared.

## Interface

```ruby
class Iso14812Import::Parsers::Base
  def each_document(&block) raise NotImplementedError end
  def documents = enum_for(:each_document).to_a
end

class Iso14812Import::Parsers::XmlParser < Base
  def initialize(edition:, io_or_path:) end
  def each_document(&block) end
end
```

Streaming via Nokogiri `Reader` or `SAX` for the 4k-line file. Block yields
one `Document` at a time.

## Tasks

- [ ] `lib/iso14812_import/parsers/base.rb` — abstract `Base` with
      `each_document` raising `NotImplementedError`, plus a `documents`
      convenience that materializes the enum
- [ ] `lib/iso14812_import/parsers/xml_parser.rb` — concrete parser:
  - `#initialize(edition:, io_or_path:)` — store edition, open XML
  - `#each_document` — walk Nokogiri reader, maintain a section breadcrumb
    stack as packages open/close, emit `Document` per `<term>`
  - Map each XML field per the TODO 06 mapping table
- [ ] `spec/iso14812_import/parsers/xml_parser_spec.rb`:
  - Fixture: a hand-built 20-line XML file with 2 nested packages and 2 terms
  - Assert: parser yields 2 documents
  - Assert: each document has correct clause, name, definition_html
  - Assert: breadcrumb_sections is correct
  - Assert: edition is attached
  - Assert: guid is extracted
- [ ] Property test: parse the real `14812 - Vocabulary.xml` and verify
  ~300 documents are emitted (number to be confirmed in TODO 06)

## Acceptance criteria

- `XmlParser.new(edition: e2, path: ...).documents` returns an `Array<Document>`
  with the correct cardinality (matches term count from TODO 06 census).
- All emission happens via the block form — no large intermediate arrays
  held in memory.
- Specs pass against fixture and against a real-XML smoke test.

## Notes

- Don't strip namespaces — use them properly with Nokogiri's ` Nokogiri::XML::Reader`
  namespace-aware mode.
- The CDATA inside `<definition>` is HTML, but the parser should NOT try to
  parse it here. Pass `definition_html` raw to the `ContentConverter`. Single
  responsibility.
- `<source>` may have multiple variants (free text vs citation string). The
  parser captures raw text; `ContentConverter` or a dedicated
  `SourceParser` (TODO 11) parses it.
