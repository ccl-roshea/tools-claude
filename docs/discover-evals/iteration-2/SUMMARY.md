# Iteration 2 — Targeted Fix Validation

**Date:** 2026-04-29
**Skill change:** Added "Discovery axes to consider" subsection to Phase 1 of SKILL.md (commit `586c1f3`). The new subsection lists 8 axes worth touching during exploration, with explicit guidance that purpose/audience is always worth asking outright.

## Why iteration 2 happened

Iteration 1 Eval 1 had assertion #10 (internal-vs-product-vs-research framing) as borderline. The conversation arrived at "internal tooling" implicitly, but the skill never asked the explicit question. The fix adds a guidance section that flags purpose/audience as always-worth-asking-explicitly.

## Re-test result

Eval 1 re-run on the same prompt with the modified skill.

**Assertion #10 unambiguously passes.** The purpose/audience question was asked at **Turn 1** — the very first skill turn — with all four canonical options enumerated and an explicit justification ("the right architecture is wildly different across those four — easy to build the wrong thing if we don't pin this down up front").

| | Iteration 1 | Iteration 2 |
|---|---|---|
| Assertion #10 | borderline (implicit only) | **PASS (explicit at Turn 1)** |
| Total assertions passing | 14/15 | 14/15 |
| Turn count | 40 | 29 |
| WebSearch calls | 2 | 3 |
| Tokens | 66,210 | 66,578 |
| Duration | 5m 57s | 7m 19s |

## New borderline (conversation-specific noise)

Iteration 2's borderline shifted to assertion #8 (sync-vs-async / state persistence). Iteration 1 covered this explicitly at turns 10-11. Iteration 2 covered it implicitly via lifecycle questions (on-demand subagents vs. nightly cron) but didn't frame it as an explicit sync-vs-async question.

This is **not a regression of the fix** — it's that the simulated conversation went a different direction this time (more focus on agent-as-skill, less on communication semantics). The fix targeted purpose/audience and worked as intended.

## Decision

**Iteration 2 closes the loop on iteration 1's borderline.** Not iterating further at this point — additional simulated-eval iterations will keep finding conversation-specific borderlines without addressing real-user concerns. Real validation is Phase 4 (Path B with the operator).

## Artifact location

The iteration-2 discovery artifact is saved at `docs/discovery/team-agents-iter2.md` to avoid clobbering iteration 1's at `docs/discovery/team-claude-code-skills-repo.md`.
