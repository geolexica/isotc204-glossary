# 01 — GCR Package Publishing via glossarist Ruby Gem

## Goal

This repository publishes a GCR (Glossarist Concept Repository) package as a GitHub Release asset on every push to `main`. The vocabulary-browser downloads this GCR to build www.geolexica.org.

## Repository Info

- **Dataset ID:** `isotc204`
- **Owner:** ISO/TC 204
- **Concept format:** v1 (`concepts/concept-3.1.1.1.yaml` with `termid`, `eng.definition`, etc.)
- **Concept count:** 312
- **Languages:** eng
- **GCR release asset:** `isotc204.gcr`

## Current State

- `.github/workflows/publish-gcr.yml` checks out `glossarist/vocabulary-browser` and uses its `package-dataset.mjs` Node.js script to build GCR
- This is wrong — GCR building is the glossarist Ruby gem's job

## Tasks

### 1. Replace publish-gcr.yml to use glossarist Ruby gem

Delete the current workflow that checks out vocabulary-browser. Replace with:

```yaml
name: publish-gcr

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  publish-gcr:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'

      - name: Install glossarist
        run: gem install glossarist

      - name: Build GCR package
        run: |
          glossarist package . -o isotc204.gcr \
            --title "ISO/TC 204 ITS Vocabulary" \
            --owner "ISO/TC 204"
        # Or if concepts need harmonization:
        # glossarist upgrade . -o isotc204.gcr

      - name: Update gcr-latest release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: gcr-latest
          name: "GCR Package (latest)"
          body: "Auto-generated GCR package. Updated on push to main."
          files: isotc204.gcr
```

### 2. Verify `glossarist package` works with this repo

```bash
gem install glossarist
glossarist package /path/to/isotc204-glossary -o isotc204.gcr --title "ISO/TC 204" --owner "ISO/TC 204"
glossarist validate isotc204.gcr
```

### 3. Verify GCR content

The GCR should contain:
- `metadata.yaml` with title, owner, statistics, schema_version
- `concepts/3.1.1.1.yaml` through `concepts/3.7.6.2.yaml` (312 files)
- `register.yaml` from the repo

### 4. Remove vocabulary-browser dependency

After switching to the Ruby gem:
- No Node.js setup needed
- No checkout of vocabulary-browser
- No `npm ci` step
- Faster CI, simpler dependency chain

## GCR Download URL

After publishing, the vocabulary-browser fetches from:
```
https://github.com/geolexica/isotc204-glossary/releases/download/gcr-latest/isotc204.gcr
```

This URL is configured in `datasets.yml` (in vocabulary-browser or geolexica.org):
```yaml
- id: isotc204
  gcrPackage: https://github.com/geolexica/isotc204-glossary/releases/download/gcr-latest/isotc204.gcr
```

## Acceptance Criteria

- [ ] `publish-gcr.yml` uses `gem install glossarist` (no Node.js)
- [ ] `glossarist package` produces a valid GCR with 312 concepts
- [ ] GCR is uploaded to `gcr-latest` release
- [ ] No checkout of vocabulary-browser repository
