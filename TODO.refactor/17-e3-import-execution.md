# 17 — E3 import execution

**Phase:** C
**Status:** done
**Depends on:** 16, 15

## Goal

Run the pipeline against E3 source at iso14812 HEAD, producing
`datasets/isotc204-ed3/` with all E3 concepts and forward `supersedes` edges
to E2.

## Pre-flight

- [ ] Confirm `~/src/external/iso14812/docs/terms/` is at the expected HEAD
- [ ] Confirm `datasets/isotc204-2025/` exists and validates (E2 import done)
- [ ] Confirm `config/editions/isotc204-ed3.yml` has `supersedes: isotc204-2025`

## Tasks

- [ ] Run `bundle exec scripts/import_iso14812.rb \
        --edition config/editions/isotc204-ed3.yml \
        --previous config/editions/isotc204-2025.yml`
- [ ] Capture pipeline summary
- [ ] Run `glossarist validate datasets/isotc204-ed3/`; fix any errors at the
      converter source
- [ ] Spot-check 5 E3 concepts including one that has clear E2 predecessor
- [ ] Verify supersedes chain E3 → E2 → E1 by picking one clause present in
      all three editions and checking both edges
- [ ] Update `datasets/isotc204-2025/register.yaml` to `status: superseded`
      (E2 is no longer current once E3 lands)
- [ ] Update `datasets/isotc204-2022/register.yaml` to confirm `status: superseded`
- [ ] Commit generated dataset + register status updates

## Acceptance criteria

- `datasets/isotc204-ed3/concepts/` contains one file per E3 markdown term
- `glossarist validate datasets/isotc204-ed3/` exits 0
- Sample clause has both E3→E2 and (transitively) E2→E1 supersedes edges
- Only E3 register has `status: current`; E1 and E2 are `superseded`

## Notes

- After this lands, the lineage series is complete on the data side. TODO 22
  (deployment repo) wires the three datasets into the browser's `datasetGroups`
  config.
- If a concept exists in E3 with no E2 predecessor (genuinely new in E3),
  that's correct — no supersedes edge. Don't synthesize one.
- If a concept exists in E2 with no E3 successor (withdrawn in E3), the
  SupersedesDeriver marks the E2 concept `status: superseded`. Confirm this
  happens during the run.
