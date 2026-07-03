# 23 — Architecture retrospective

**Phase:** —
**Status:** todo (after TODOs 01–17 land)
**Depends on:** 17

## Goal

After the converter is running and all three editions are in place, write a
retrospective capturing what worked, what didn't, and what should be improved
next. This is the "always think about architecture" loop closing.

## Prompts

- Did the `Document` IR abstraction hold up? Were there fields both parsers
  couldn't populate cleanly? Should the IR be split per-parser?
- Did `ConceptBuilder` stay under one screen of code? If not, what to extract?
- Did `ContentConverter`'s reliance on coradoc produce clean output, or did
  we accumulate post-processing patches? If patches, file them upstream.
- Did `SupersedesDeriver` handle every edge case, or did we discover new ones
  during execution?
- Is the autoload setup ergonomic, or do new contributors struggle to find
  where a class lives?
- Spec coverage: are there any classes without specs? Any specs that test
  implementation rather than behavior?
- Performance: how long does a full E3 import take? If >30s, where's the
  bottleneck?
- Is the V3 schema sufficient, or did we hit limitations that require
  upstream changes to glossarist / concept-model?

## Tasks

- [ ] Read every `lib/iso14812_import/**/*.rb` file
- [ ] For each class, ask: is its responsibility still MECE? Has it accreted
      concerns?
- [ ] Read every spec — is each one testing behavior or implementation?
- [ ] Run `bundle exec rspec --profile` to find slow specs
- [ ] Survey git log on `lib/` — find churn hotspots
- [ ] Document findings in this file (or split into follow-up TODOs under
      `TODO.refactor/` for the next iteration)
- [ ] If any architectural pattern emerged that should be a global rule,
      propose it for inclusion in user's `~/.claude/CLAUDE.md`

## Acceptance criteria

- Retrospective doc exists and is honest about strengths/weaknesses
- At least 3 concrete improvement TODOs filed for the next iteration
- Any global-rule candidates surfaced to the user

## Notes

- This TODO is intentionally non-actionable until the work is done. It's a
  forcing function for reflection — without it, we move to the next feature
  without learning.
- The retrospective should be one screen of text, not a dissertation.
