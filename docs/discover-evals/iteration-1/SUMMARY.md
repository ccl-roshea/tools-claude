# Iteration 1 — Eval Results Summary

**Date:** 2026-04-29
**Skill:** `/discover` at `../../skills/discover/`
**Eval mode:** Self-answering subagent (with-skill only; no baseline since /discover's output type is structurally different from the no-skill case)

## Caveat on interpretation

These evals are **structural smoke tests** — they verify the skill loads, transitions phases correctly, fires its anti-sycophancy techniques on triggers, and writes well-formed artifacts. They do NOT validate quality on real-world problems because the "user" answers are simulated by the same LLM running the skill. The skill cannot be sycophantic toward a "user" that gives perfectly cooperative responses to its own questions.

**Real validation comes from Phase 4 (Path B) with a human operator.**

## Per-eval results

| Eval | Prompt | Turns | Tools | Pass |
|------|--------|------:|-------|------|
| 1 — vague-agents | "I want to deploy agents for my team that can communicate" | 40 | 2 WS, 4 W, 4 R, 4 B | 14/15 (1 borderline) |
| 2 — todo-app | "Build me a todo app" | 15 | 3 WS, 4 W, 5 R, 2 B | 10/10 |
| 3 — multi-subsystem | "We need a platform with auth, billing, a marketplace, and analytics" | 15 | 6 WS, 4 W, 5 R, 4 B | 11/11 |
| 4 — overspecified | "Build a REST API using Express with Postgres and deploy to AWS ECS" | 26 | 2 WS, 1 WF, 4 W, 7 R, 1 B | 12/12 |

**Aggregate: 47/48 assertions PASS, 1 borderline.** (WS = WebSearch, WF = WebFetch, W = Write, R = Read, B = Bash.)

## Token / time summary

| Eval | Tokens | Duration |
|------|-------:|---------:|
| 1 | 66,210 | 5m 57s |
| 2 | 64,632 | 5m 09s |
| 3 | 81,516 | 8m 35s |
| 4 | 69,350 | 5m 35s |

Total: 281,708 tokens, ~25 minutes wall-clock.

## Notable behaviors observed

### Eval 1: Long discovery, soft signals didn't trigger early termination
40 turns is at the upper edge. The skill's "10+ turns since a new theme emerged" signal didn't fire as aggressively as it could have. Auth/cost/observability were asked sequentially over turns 20-25; could have been compressed but the skill explicitly forbids compound questions. Acceptable tradeoff but worth tightening if a future iteration shows this pattern repeating.

### Eval 1: Internal-vs-product framing was implicit, not explicit (assertion #10 borderline)
The artifact's framing reads as internal tooling, but the skill never asked the explicit "is this internal tooling, a product feature, or a research artifact?" question. A strict grader would mark this as failed. Suggested fix in iteration 2: add internal-vs-product as an explicit prompt during Phase 1 framing exploration.

### Eval 3: Strong build-vs-buy outcome
4 of 4 chunks evaluated, 3 classified Adopt-fully (Clerk, Stripe Connect, PostHog). The marketplace chunk was the only build-custom one. Phase 3.5 demonstrated the skill's design intent clearly — the original 4-chunk build-everything plan collapsed into 1 build-custom chunk + 3 integration chunks. Significant scope reduction.

### Eval 4: Reductive frame landed
Technique B's option 3 ("no new service at all — use Postgres' built-in PostgREST or Hasura, or write Cloudflare Workers that hit the DB directly") was qualitatively different from options 1 and 2, both of which deployed a service. The simulated user picked a hybrid. In a real run, this would put pressure on the deployment-target choice.

### Eval 4: Phase 3.5 changed the recommended default
Search constraint was AWS (real constraint) → recommended target shifted from ECS (typed choice) to App Runner (better fit given constraints). The skill working as designed.

## What these evals don't tell us

- Whether Technique B's reductive frames feel substantive to a real human
- Whether red-team findings make sense to a person
- Whether chunking proposals would be accepted or rejected
- Whether the skill correctly fights sycophancy under pressure (the failure mode it's designed to prevent)

These require Phase 4 (Path B) — operator-driven clean-room run on the Test 1 prompt.

## Recommended action

1. **Proceed to Phase 4.** The skill is structurally sound enough to validate against the human-operator baseline.
2. **Defer iteration 2** until Phase 4 results are in. The borderline assertion #10 (internal-vs-product framing) is worth a small fix, but it's better bundled with whatever Phase 4 surfaces than addressed in isolation.
