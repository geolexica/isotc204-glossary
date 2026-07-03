# 06 — E2 XML investigation

**Phase:** B
**Status:** done
**Depends on:** nothing (investigation only)

## Goal

Survey the actual structure of `14812 - Vocabulary.xml` at commit `dfe7e9d4`
in iso14812 and produce a written mapping from XML elements to Document IR
fields. This is reconnaissance for TODO 07.

## Why

The E2 XML is 4068 lines, hierarchical, with embedded HTML in CDATA. Before
writing the parser, we need to enumerate: which elements exist, what they
contain, what edge cases appear, how cross-references work.

## Tasks

- [ ] Extract `git -C ~/src/external/iso14812 show dfe7e9d4:"14812 - Vocabulary.xml" > /tmp/e2-vocabulary.xml`
- [ ] Element census: `nokogiri` script that counts occurrences of each element
      and lists unique attributes per element. Output → `TODO.refactor/e2-xml-census.md`
- [ ] Identify all distinct CDATA patterns inside `<definition>`:
      - Plain text
      - HTML with `<a href="#GUID">` cross-refs
      - HTML with `<i>`, `<b>`, `<u>`, `<font>` formatting
      - Field codes (`<span style='mso-element:field-begin'></span> REF GUID <span ...>`)
  - Document each pattern with a sample line
- [ ] Enumerate `<source>` element formats (free text? structured?)
- [ ] Enumerate where `<note>` and `<example>` appear (term-level vs
      package-level)
- [ ] Identify package/section nesting depth and how clause numbers compose
- [ ] Survey figure references — `<figure>` element location, image path format
- [ ] Note any malformed XML, encoding issues, or non-UTF8 content
- [ ] Produce a mapping table: `XML element → Document field`, with edge cases
      flagged. Commit as `TODO.refactor/e2-xml-mapping.md`.

## Acceptance criteria

- Census doc lists every element with count + sample.
- Mapping doc covers every Document IR field, showing the XML source(s).
- At least 5 representative CDATA samples documented for the content converter.

## Notes

- The XML namespace is `https://www.iso.org/tc204/wg1/vocabulary` — Nokogiri
  needs to handle this (or strip namespaces for tractability).
- The MS Office field codes (`mso-element:field-begin` ... `field-end`) wrap
  many cross-references inside the CDATA HTML. The ContentConverter must
  extract the `REF GUID` from inside these.
- The `<guid>` element on each term is the bridge for cross-edition identity
  in some cases — preserve it on the Document IR.
