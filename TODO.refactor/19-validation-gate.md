# 19 — Validation gate

**Phase:** D
**Status:** todo
**Depends on:** 15, 17

## Goal

A `rake validate` task runs `glossarist validate` against every dataset
directory. CI calls this on every PR. Pipeline runs invoke it after writing.

## Why

Catching schema violations at conversion time is far cheaper than catching
them on the deployment site. The gate also makes the converter's output
quality measurable: if validate fails, the converter has a bug, not the
data.

## Tasks

- [ ] `Rakefile`:
  ```ruby
  desc "Validate all datasets"
  task :validate do
    Dir["datasets/*"].each do |dataset|
      sh "glossarist validate #{dataset}"
    end
  end
  ```
- [ ] Pipeline `#run` invokes validation at the end; non-zero exit raises
- [ ] `spec/iso14812_import/pipeline_spec.rb` asserts validation status is
      reflected in the summary
- [ ] CI: `.github/workflows/build.yml` runs `bundle exec rake validate`
      instead of (or in addition to) the current single-dataset
      `glossarist validate .`

## Acceptance criteria

- `bundle exec rake validate` exits 0 on a clean tree
- CI runs `rake validate` and fails the build on any validation error
- Pipeline runs surface validation failures clearly (not buried in stdout)

## Notes

- If `glossarist validate` is slow (>5s per dataset), consider caching the
  result keyed on the dataset's git SHA. For 3 datasets of ~400 concepts each,
  probably fine without caching.
- Validation failures should produce a clear list of files + errors, not a
  single cryptic message. If the gem's CLI doesn't do this, file an issue
  upstream.
