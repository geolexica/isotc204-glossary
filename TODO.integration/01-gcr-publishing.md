# 01 — Versioned GCR Publishing via glossarist Ruby Gem

## Goal

This repository publishes versioned GCR packages as GitHub Release assets. On every push to `main`, update `gcr-latest`. On version tags (`gcr-v*`), create a pinned release.

## Repository Info

| Field | Value |
|-------|-------|
| **Dataset ID / shortname** | `isotc204` |
| **Owner** | ISO/TC 204 |
| **Format** | v1 (`concepts/concept-3.1.1.1.yaml`) |
| **Concepts** | 312 |
| **Languages** | eng |
| **GCR filename** | `isotc204-{version}.gcr` |

## Release Convention

| Trigger | Tag | Asset |
|---------|-----|-------|
| Push to `main` | `gcr-latest` (rolling) | `isotc204.gcr` |
| Tag `gcr-v1.0.0` | `gcr-v1.0.0` (pinned) | `isotc204-1.0.0.gcr` |

Download URLs:
```
https://github.com/geolexica/isotc204-glossary/releases/download/gcr-latest/isotc204.gcr
https://github.com/geolexica/isotc204-glossary/releases/download/gcr-v1.0.0/isotc204-1.0.0.gcr
```

## Current State

- `.github/workflows/publish-gcr.yml` checks out vocabulary-browser and uses Node.js — **must be replaced**
- Has a manually uploaded `gcr-latest` release with `isotc204.gcr`

## Tasks

### 1. Replace publish-gcr.yml with glossarist gem

```yaml
name: publish-gcr

on:
  push:
    branches: [main]
    tags: ['gcr-v*']
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

      - name: Determine version
        id: version
        run: |
          if [[ "${GITHUB_REF}" == refs/tags/gcr-v* ]]; then
            VERSION="${GITHUB_REF_NAME#gcr-v}"
            echo "version=${VERSION}" >> "$GITHUB_OUTPUT"
            echo "tag=gcr-v${VERSION}" >> "$GITHUB_OUTPUT"
            echo "filename=isotc204-${VERSION}.gcr" >> "$GITHUB_OUTPUT"
          else
            DATEVER=$(date +%Y.%m.%d)
            echo "version=${DATEVER}" >> "$GITHUB_OUTPUT"
            echo "tag=gcr-latest" >> "$GITHUB_OUTPUT"
            echo "filename=isotc204.gcr" >> "$GITHUB_OUTPUT"
          fi

      - name: Build GCR package
        run: |
          glossarist package . -o "${{ steps.version.outputs.filename }}" \
            --shortname isotc204 \
            --version "${{ steps.version.outputs.version }}" \
            --title "ISO/TC 204 ITS Vocabulary" \
            --owner "ISO/TC 204"

      - name: Publish release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ steps.version.outputs.tag }}
          name: "GCR Package ${{ steps.version.outputs.version }}"
          body: "Auto-generated GCR package. ${{ steps.version.outputs.version }}"
          files: ${{ steps.version.outputs.filename }}
```

### 2. Verify locally

```bash
gem install glossarist
glossarist package . -o isotc204-test.gcr \
  --shortname isotc204 --version 0.0.1 \
  --title "ISO/TC 204 ITS Vocabulary" --owner "ISO/TC 204"
glossarist validate isotc204-test.gcr
```

### 3. Remove vocabulary-browser checkout

After switching, no Node.js or vocabulary-browser dependency is needed.

## Acceptance Criteria

- [ ] `publish-gcr.yml` uses `gem install glossarist` only
- [ ] Push to main updates `gcr-latest` with `isotc204.gcr`
- [ ] Tag `gcr-v1.0.0` creates release with `isotc204-1.0.0.gcr`
- [ ] `metadata.yaml` inside GCR has `shortname: isotc204` and `version`
- [ ] No checkout of vocabulary-browser
