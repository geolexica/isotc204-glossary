# 22 — Deployment (separate repo, deferred)

**Phase:** E
**Status:** deferred — out of scope for this PR series

## Goal

Update `geolexica/isotc204.geolexica.org/site-config.yml` to enumerate all
three datasets as a `kind: lineage` group, so the concept-browser renders the
edition timeline UI.

## Tasks (when this is unblocked)

- [ ] In `~/src/geolexica/isotc204.geolexica.org/site-config.yml`:
  - Add three dataset entries under `datasets:` (one per edition), each with
    its own `gcrPackage:` URL (the per-edition GCR from TODO 20)
  - Add a `datasetGroups:` entry:
    ```yaml
    datasetGroups:
      - id: isotc204
        label: ISO/TC 204 ITS Vocabulary
        kind: lineage
        datasets: [isotc204-ed3, isotc204-2025, isotc204-2022]
        color: '#d97706'
    ```
  - Update routing if needed for cross-edition URN resolution
- [ ] Verify the site renders the edition timeline correctly via
      `npx concept-browser build` + local preview
- [ ] PR the change to `geolexica/isotc204.geolexica.org`

## Why deferred

This is a separate repository. Its PR cadence and review owners differ from
this data repo. Bundling it here would expand the scope beyond what one PR
should hold.

## Acceptance criteria

- `npx concept-browser build` succeeds against the updated site-config
- Edition timeline sidebar renders all three editions
- Clicking between editions shows the supersedes edges in the graph view

## Notes

- The current `datasets.yml` / `site-config.yml` VIML example is the
  reference: `kind: lineage` + `datasets: [newest, ..., oldest]`.
- After this lands, https://isotc204.geolexica.org will show all three
  editions with timeline navigation. That's the visible payoff for the
  entire TODO.refactor effort.
