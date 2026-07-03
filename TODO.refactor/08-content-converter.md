# 08 — Content converter

**Phase:** B
**Status:** todo
**Depends on:** 02, 03

## Goal

`Iso14812Import::ContentConverter` converts HTML (E2 CDATA) or Markdown (E3
body) into AsciiDoc with inline URN cross-references resolved, ready for the
`DetailedDefinition` content field.

Uses coradoc as the format-conversion engine (HTML → AsciiDoc, Markdown →
AsciiDoc). After coradoc emits AsciiDoc, a post-processing step rewrites
source-native cross-references into the v3 URN form:

- E2: `<a href="#GUID">` (HTML) → `{{urn:iso:std:iso:14812:2025:<clause>,<display>}}`
- E3: `[display](TermName.md)` (Markdown link) → `{{urn:iso:std:iso:14812:ed3:<clause>,<display>}}`

Resolution requires the per-edition `SourceIndex`.

## Why

Both E2 and E3 definitions need to land in the same canonical form (AsciiDoc +
URN refs) so the concept-browser renders them identically. Coradoc handles the
format conversion; this class handles the cross-ref rewriting that depends on
the edition's index.

## Interface

```ruby
class Iso14812Import::ContentConverter
  def initialize(edition:, source_index:, figure_registry:)
  end

  # @param html [String] raw HTML, e.g. from E2 CDATA
  # @return [String] AsciiDoc with URN refs
  def from_html(html) end

  # @param markdown [String] raw Markdown, e.g. from E3 term body
  # @return [String] AsciiDoc with URN refs
  def from_markdown(markdown) end
end
```

## Tasks

- [ ] `lib/iso14812_import/content_converter.rb`:
  - Initialize with edition + source_index + figure_registry
  - `#from_html(html)`: call coradoc HTML→AsciiDoc, then post-process
  - `#from_markdown(md)`: call coradoc Markdown→AsciiDoc, then post-process
  - Post-processing steps (private methods):
    - `resolve_urn_refs(adoc, edition, index)` — replace source-native links
    - `resolve_figure_refs(adoc, figure_registry)` — replace `<object>` /
      `image::` with `<<fig-id>>`
    - `strip_office_field_codes(html)` — remove MSO `field-begin/end` wrappers
      before coradoc (E2 specific)
- [ ] `spec/iso14812_import/content_converter_spec.rb`:
  - HTML→AsciiDoc: simple text round-trips
  - HTML with `<a href="#GUID">` cross-ref → URN ref (using fixture index)
  - Markdown with `[display](Filename.md)` cross-ref → URN ref
  - Unresolved cross-refs (target not in index) → left as plain text + log
  - Figure refs rewritten to `<<fig-id>>` form
- [ ] Verify coradoc API surface first — read
      `/Users/mulgogi/src/mn/coradoc/coradoc-markdown/lib/coradoc-markdown.rb`
      and the `coradoc` gem's public entry. Likely
      `Coradoc::Convert.from_html(html)` and `Coradoc::Convert.from_markdown(md)`,
      or hub-and-spoke via `Coradoc::CoreModel`. Document the actual API in
      the spec comments.

## Acceptance criteria

- E2 fixture HTML converts to AsciiDoc with correct URN refs.
- E3 fixture Markdown converts to AsciiDoc with correct URN refs.
- Unresolved refs are preserved as text and logged (no silent data loss).
- No regex that crashes on edge cases (CDATA with quotes, nested tags, etc.).

## Notes

- Coradoc is the canonical conversion library per user direction. Do not
  hand-roll HTML→AsciiDoc — that would be reinventing a wheel the user
  explicitly directed us to use.
- If coradoc mangles certain constructs, snapshot the bad output and raise an
  issue upstream. Don't paper over with custom regex fixes.
- Office field codes are an E2-specific nuisance. The MSO wrapper format is
  consistent (`<span style='mso-element:field-begin'></span> REF <GUID> <span style='mso-element:field-end'></span>`) — a single regex can extract the
  GUID and merge the surrounding text. Do this BEFORE coradoc.
