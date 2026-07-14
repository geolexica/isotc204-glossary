# ISO/TC 204 ITS Vocabulary — Edition 3 (draft)

## Status

**Working draft.** Not yet balloted. Content is subject to change without
notice. Do not cite as a normative reference.

## Source

Generated from the [ISO/TC 204 iso14812 ontology repository](https://github.com/ISO-TC204/iso14812).
Edition 3 represents a structural shift: the vocabulary is now authored
as a formal OWL ontology (Turtle, `docs/*.ttl`) plus per-term markdown
files (`docs/terms/*.md`) that document the human-readable definitions,
notes, examples, and provenance.

This dataset is produced by parsing the markdown term files and
converting them to the Glossarist v3 YAML format. The conversion is
performed by the `Iso14812Import` converter under `lib/iso14812_import/`
in this repo.

## Scope

~380 concepts. Adds new concepts not present in Edition 2 and revises
existing ones. Some Edition 2 concepts are not yet represented in
Edition 3 — these are flagged as superseded in the Edition 2 dataset
until they are either re-introduced or formally withdrawn.

## Provenance

Each concept's markdown source includes `History note:` lines that
describe when it was introduced, when it was last revised, and what
changed. These are preserved in the dataset as `HistoryNote` structs
on the `Document` IR.
