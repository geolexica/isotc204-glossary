# 01 — Versioned GCR Publishing via glossarist Ruby Gem

## Goal

This repository publishes versioned GCR packages as GitHub Releases, triggered by version tags.

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

| Trigger | Tag | Assets |
|---------|-----|--------|
| Push tag `v1.0.0` | `v1.0.0` | `isotc204-1.0.0.gcr` + `isotc204.gcr` |
| workflow_dispatch | `v{version}` | `isotc204-{version}.gcr` + `isotc204.gcr` |

### Two assets per release
1. **Versioned**: `isotc204-1.0.0.gcr` — for archival and pinned downloads
2. **Unversioned alias**: `isotc204.gcr` — enables stable `releases/latest/download/` URL

### Download URLs
```
# Latest (always points to newest release)
https://github.com/geolexica/isotc204-glossary/releases/latest/download/isotc204.gcr

# Pinned version
https://github.com/geolexica/isotc204-glossary/releases/download/v1.0.0/isotc204-1.0.0.gcr
```

## How to publish

```bash
# Tag and push to trigger GCR build
git tag v1.0.0
git push origin v1.0.0

# Or use GitHub UI: Releases → Draft a new release → tag v1.0.0
```

## Acceptance Criteria

- [ ] `publish-gcr.yml` triggers on `v*` tag push only
- [ ] `gem install glossarist` builds GCR with `--shortname isotc204 --version`
- [ ] Release has both `isotc204-{version}.gcr` and `isotc204.gcr` assets
- [ ] `metadata.yaml` has `shortname: isotc204` and `version`
- [ ] No checkout of vocabulary-browser
