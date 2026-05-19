# PR 2 Smoke Test — /discover post-trim

## Socratic rework supersession (2026-05-19)

This smoke-test report reflects `/discover` behavior under the prior multi-phase protocol (PREMISE CHECK / DISCOVER / RED-TEAM with Tech-B 4-framings, Tech-D classification, shape-language audit, parked-shapes ledger, structured red-team). That protocol was replaced on 2026-05-19 with a single Socratic-dialogue phase (see `docs/superpowers/specs/2026-05-19-discover-pure-socratic-design.md` and plan `docs/superpowers/plans/2026-05-19-discover-pure-socratic.md`).

**Status of findings below:**

- Structural findings (artifact has X section, ledger has Y entry, gate Z fires) are **no longer applicable** — the relevant structures don't exist in the new artifact.
- Dialogue-quality findings (premise check enumerates concrete paths, Tech-B's 4 framings are equal-weight, etc.) are **superseded** — the protocol they exercise no longer runs.

Retained as a historical record of pre-rework behavior. A fresh smoke test under the Socratic rework will be added when the new evals run end-to-end.

---

**Date:** 2026-05-15
**Test type:** Single-turn simulation against synthetic over-specified prompt
**Skill loaded:** post-PR2 `/discover` (trimmed to 3 phases)

## Test prompt

> "I want to migrate our team's wiki from Confluence to Notion, build a Python script that uses the Confluence REST API and the Notion API to copy pages, preserve attachments via S3 intermediary storage, run it as a scheduled GitHub Action weekly to keep them in sync, and use Markdown as the intermediate format."

## Result

Subagent loaded post-PR2 `/discover` SKILL.md + 4 shared/ files and executed Phase 0 turn 1 cleanly.

## Phase 0 response (subagent output, excerpted)

**§1.1 Restated outcome:** "you want your team's institutional knowledge to live somewhere that works better than Confluence does today, with the Confluence-shaped content available in that new place. The 'migrate,' 'build a Python script,' 'S3 intermediary,' 'GitHub Action weekly sync,' and 'Markdown intermediate' are all hows. The what is 'knowledge accessible in [better place] without losing what's in Confluence.'" §1.1.2 also raises that even Notion itself is a shape.

**§1.2 Shape-language audit (Step 1.5):** 6 shapes listed with category tags:
- "migrate ... from Confluence to Notion" (tool)
- "Python script" (tool)
- "Confluence REST API and the Notion API" (pattern)
- "preserve attachments via S3 intermediary storage" (tool+pattern)
- "scheduled GitHub Action weekly to keep them in sync" (tool+pattern)
- "Markdown as the intermediate format" (tool+pattern)

§1.2.7 closes with the exact prescribed binary-choice (lock-in-with-source vs. park-all). §1.2.8 highlights the most load-bearing shape (weekly sync vs. one-shot cutover) for early operator pre-authorization.

**§Q1 Premise check (Step 2):** Three concrete no-build paths, each specific to the outcome:
- Vendor migration tool (Notion's official Confluence importer; CloudFuze; BetterCloud)
- Stay on Confluence + fix what's actually broken (Atlassian Intelligence, restructure spaces)
- Question the destination entirely (docs-in-repo; search layer; embedded wiki replacement)

None of the three is "use a spreadsheet"-tier filler. Path 3 in particular directly challenges the destination premise.

## Self-assessment results

| Check | Result |
|---|---|
| Step 1 fired (outcome restatement) | ✓ |
| Step 1.5 fired (shape-language audit) | ✓ (6 shapes — 1 over the 5-cap; defensible since each is load-bearing) |
| Step 2 fired (premise check + 3 no-build paths) | ✓ |
| §X.Y.Z labeling used throughout | ✓ |
| No Phase 2-5 leakage (CHUNK / RESEARCH / ARTIFACT / DISPATCH / /superpowers) | ✓ **PASS — trim is clean** |
| /solution-aware closing | N/A — surfaces at end of Phase 2 RED-TEAM, not Phase 0 turn 1 |

## Headline finding

**Trim is structurally clean.** Post-PR2 `/discover` produces a Phase 0 response that does not mention CHUNK, RESEARCH, ARTIFACT, DISPATCH, or `/superpowers` — the four phases that moved to `/solution`. PR 1 discipline (Step 1.5 prompt audit, concrete no-build paths, §X.Y.Z labeling, anti-sycophancy) preserved.

## Two minor protocol stretches (not failures)

1. **6 shapes listed** vs. SKILL.md's 5-cap. Defensible given over-specified prompt; could be tightened with a "+1 more" line or by collapsing two related shapes.
2. **§1.2.8 adds inline commentary** flagging the highest-stakes shape (weekly sync vs. one-shot). Useful but not strictly prescribed by Step 1.5 mechanics.

Neither is a regression; both are subagent judgment calls within reasonable adaptation.

## Caveats

- This is a **single-turn smoke test**, not a full Path B validation. Multi-turn dynamics (Tech-B firing, peel-back interactions, parked-shape ledger updates, soft-signal status lines, RED-TEAM phase, /solution handoff) weren't exercised.
- The synthetic operator (subagent) has no real solution-bias to peel back. Real-operator-bias-drop dynamics are not tested.
- Task 10 (full Path B validation per evals/methodology.md) is deferred per operator — to be run after both PR 1 + PR 2 land and the operator does a real-problem session.

## Cleared to proceed

PR 2 `/discover` trim works as designed. Ready for Task 16 (/solution smoke test) and final review.
