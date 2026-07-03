# 20 — CI updates

**Phase:** D
**Status:** todo
**Depends on:** 19

## Goal

`.github/workflows/build.yml` and `.github/workflows/publish-gcr.yml` updated
for the multi-dataset layout: per-dataset validation, per-edition GCR packages.

## Why

The current workflows assume a single dataset at repo root. After
restructure, the workflows must discover datasets under `datasets/` and
treat each as a separate unit.

## Tasks

- [ ] `build.yml`:
  - Replace `glossarist validate .` with `bundle exec rake validate`
    (per TODO 19) — discovers all datasets
  - Test-package step: build a GCR per dataset (loop)
- [ ] `publish-gcr.yml`:
  - On tag push, build and publish one GCR per dataset:
    - `isotc204-2022-<version>.gcr`
    - `isotc204-2025-<version>.gcr`
    - `isotc204-ed3-<version>.gcr`
  - Also publish unversioned aliases (`isotc204-2022.gcr`, etc.) so the
    deployment repo can pin to "latest of each edition"
- [ ] Add a Ruby setup step that installs bundler and `bundle install`s
      (the converter's Gemfile will exist after TODO 02)

## Acceptance criteria

- CI passes on PRs that touch any dataset
- A tag push produces N GCR files in the release (N = number of datasets)
- Each GCR is named after its dataset id

## Notes

- Per global rule: NEVER push tags myself. The user does releases. This TODO
  is about updating the workflow file, not about running it.
- Workflow changes go through PR — never push directly to main.
