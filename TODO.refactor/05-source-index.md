# 05 — Source index

**Phase:** B
**Status:** todo
**Depends on:** 03, 04

## Goal

`Iso14812Import::SourceIndex` builds a per-edition lookup table mapping
clause IDs and term names to source location, so cross-edition supersedes
derivation and inline cross-reference resolution can find targets in O(1).

## Why

The converter needs to resolve `[ITS service](ITS service.md)` markdown links
and `<a href="#idGUID">` XML cross-refs to clause IDs. Without an index, every
cross-ref becomes an O(N) scan. The index is built once per edition, reused
across all concepts in that edition and in the next edition's supersedes
derivation.

## Shape

```ruby
Iso14812Import::SourceIndex = Struct.new(:edition_id, :by_clause, :by_name,
  :by_guid, keyword_init: true) do
  def self.build(edition, documents)
    # documents is an Array<Document> from the parser pass
    new(
      edition_id: edition.id,
      by_clause: documents.map { |d| [d.clause, d] }.to_h,
      by_name:   documents.map { |d| [d.name.downcase, d] }.to_h,
      by_guid:   documents.reject { |d| d.guid.nil? }
                         .map { |d| [d.guid, d] }.to_h,
    )
  end

  def lookup(clause: nil, name: nil, guid: nil)
    # ...
  end
end
```

## Tasks

- [ ] `lib/iso14812_import/source_index.rb` with the struct + `self.build` +
      `#lookup` + `#clauses` + `#names`
- [ ] `spec/iso14812_import/source_index_spec.rb`:
  - Build from a fixture array of 3 documents
  - Lookup by clause returns the right document
  - Lookup by name is case-insensitive
  - Lookup by guid works for E2 documents (E3 documents have nil guid)
  - Lookup with no matching key returns nil
  - `#clauses` and `#names` return sets
- [ ] No doubles — use real `Document` instances

## Acceptance criteria

- `SourceIndex.build(edition, docs)` runs in O(N) over docs.
- `#lookup(clause: "3.1.1.5")` is O(1).
- Round-trips through YAML? No — `SourceIndex` is built in-memory per pipeline
  run. Never serialized.

## Notes

- The index is built **after** the parser pass, **before** the concept-builder
  pass. It is also passed to `SupersedesDeriver` for cross-edition lookups
  (where it consults the previous edition's index).
- For very large datasets (10k+ concepts), we'd need to chunk the index. For
  ~300-400 concepts per edition, the in-memory hash is fine.
