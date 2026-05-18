# PR 2 Smoke Test — /solution SHAPE-DISCOVER

**Date:** 2026-05-15
**Test type:** Single-turn simulation against synthetic discovery.md fixture + parked-shapes ledger
**Skill loaded:** newly-created PR 2 `/solution` (6 phases)

## Test fixture (synthetic)

`docs/socrates/discover/team-onboarding-flow.md`:
- 4 outcomes (productive by week-2, env+access by EOD-1, domain understanding by week-1, help-network by day-3)
- 2 external constraints (1-2 hires/quarter; 8-engineer team)
- 2 open axes
- 3 parked shapes: "use Notion for the onboarding wiki" / "comprehensive onboarding checklist with 50+ items" / "buddy system pairing"

## Result

Subagent loaded post-PR2 `/solution` SKILL.md + 4 shared files + 3 solution-specific reference files and executed SHAPE-DISCOVER turn 1 cleanly.

## SHAPE-DISCOVER response (subagent output, key excerpts)

**§1.3:** *"I am NOT re-doing outcome discovery. The four outcomes ... and the two external constraints ... are settled by /discover. My job is to evaluate the three parked shapes against those outcomes."* — Clean phase-boundary respect.

**§2 Tech-B firing (4 shape framings spanning complexity spectrum):**
- Complex (custom platform: provisioning + knowledge graph + routing) — ~4-6 weeks
- Middle (lightweight repo + provisioning script + curated docs)
- Low-build (glue: template + existing scripts + wiki cleanup)
- No-build (adopt existing vendor: Pyn / Sora / GitHub-Slack integrated flow)

§2.2: *"the amortization math at 1-2 hires/quarter on an 8-engineer team favors Low-build or No-build; Complex platform thinking will feel rigorous but the amortization is weak."* — The subagent surfaces the structural argument, not just the framings.

**§3 Tech-D classifications:**
| Parked shape | Classification | Notes |
|---|---|---|
| Notion wiki | **candidate** | 4 alternatives enumerated; operator probe (§Q1) to check for external source first |
| 50+ checklist | **default-to-test** | No-build alternative constructed: 1-page milestones + buddy check-in |
| Buddy system | **candidate** | 4 alternatives: 1:1 / team rotation / async-channel / hybrid |

**Cross-shape coupling flagged** (§3.3.5): if checklist resolves to no-build (milestone + buddy), buddy decision becomes load-bearing — argues for serial resolution. Subagent asks operator (§Q4) whether to serialize or parallelize.

**§Q1–§Q4** asked to operator: source-check on Notion; no-build challenge on checklist; whole-problem framing pick (with bias-warning that math favors Low/No-build); sequencing question on shape 2→3 dependency.

## Self-assessment results

| Check | Result |
|---|---|
| SHAPE-DISCOVER phase identified | ✓ |
| Tech-D applied to all 3 parked shapes | ✓ (with appropriate classifications) |
| Tech-B fired with credible 4-option shape framings (including real No-build) | ✓ (Pyn/Sora named; not "use a spreadsheet" filler) |
| §X.Y.Z addressing used (including §Q parallel counter) | ✓ |
| No /discover-phase leakage (no premise check / outcome restatement / prompt audit) | ✓ **PASS — boundary clean** |
| WIP creation with session_id mentioned | ✓ |

## Headline finding

**/solution's SHAPE-DISCOVER mechanics work as designed.** The subagent:
1. Reads discovery.md + parked-shapes ledger, recognizes outcomes are settled
2. Applies Tech-D's shape-classification rule (constraint / candidate / default-to-test) to each parked shape
3. Fires Tech-B with 4 alternative shape framings spanning the complexity spectrum
4. Names WIP creation with `session_id` field per PR 2 hook contract
5. Surfaces cross-shape coupling proactively (shape 2 → shape 3)

The default-to-test classification on the 50+ checklist is the most valuable demonstration — the subagent constructed a credible no-build alternative (milestones + buddy) and asked the operator to articulate what the 50-item checklist catches that the simpler alternative doesn't. That's the Socratic move the architecture was designed to enable.

## Minor adaptations the subagent self-flagged

1. **Cross-shape coupling** between shapes 2 and 3 surfaced (§3.3.5) — minor deviation from "one shape at a time" but operator-friendly.
2. **Tech-B closing question** ("which resonates?") deferred to §Q3 rather than inlined at end of §2 — functionally equivalent.
3. **Candidate-path alternative enumeration** done agent-side before operator input — defensible breadth-then-narrow; could be more conservative.

None of these is a defect.

## Caveats

- This is a **single-turn smoke test**, not a full session run. Multi-turn dynamics (CHUNK, RED-TEAM-on-shapes, RESEARCH, ARTIFACT-write with all 6 gates, DISPATCH) weren't exercised.
- The synthetic operator (subagent) has no real solution-bias. Real-operator dynamics not tested.
- Task 10 (full Path B end-to-end /discover → /solution → /superpowers validation) is deferred per operator. Best done after PR 1 + PR 2 are merged and cache-refreshed.

## Cleared to proceed

PR 2 `/solution` works as designed. Ready for final code review and merge.
