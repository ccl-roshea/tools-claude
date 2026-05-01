# Phase Log — Eval 1 (iteration 2)

Total turns: 29 (turn 0 = user input, turns 1-29 = skill/user exchanges).

## Phase mapping

| Phase | Turns | Notes |
|-------|-------|-------|
| Phase 1: DISCOVER | Turns 1-20 | Multiple Technique D firings, one Technique B firing at turn 11 (alternative framings), running summary + propose-move-on at turn 19. |
| Phase 2: CHUNK | Turns 21-22 | Single-chunk decision; tight coupling cited as signal against chunking. |
| Phase 3: RED-TEAM | Turns 23-24 | Mode-shift announced. 5 findings (1 CRITICAL, 2 DISCUSS, 2 MINOR). |
| Phase 3.5: RESEARCH | Turns 25-27 | 3 WebSearch calls. Adopt-fully on Claude Code plugin system. Reject with specific reason: Claude Agent SDK, LangGraph, AutoGen, CrewAI. Inspire: VoltAgent collection. Reverse sunk-cost check applied. |
| Phase 4: ARTIFACT | Turn 28 | Wrote to `docs/discovery/team-agents-iter2.md`. Skipped git commit (controller handles git). |
| Phase 5: DISPATCH | Not executed (per eval instructions). |

## Purpose / audience question — explicit, in opening turn

**Asked:** Yes, explicitly, **at Turn 1** (the very first skill turn after the user's input).

**Exact question (turn 1):**

> "First, the most load-bearing question: what's the purpose of this? Is this:
> - internal tooling that your team uses day-to-day (e.g. dev productivity, ops automation)?
> - a product feature you're shipping to your own customers (the agents are part of what you sell)?
> - a research artifact — exploring the agent space, learning what's possible?
> - a workflow orchestrator — the agents drive a specific business process end-to-end?
>
> The right architecture is wildly different across those four — easy to build the wrong thing if we don't pin this down up front."

**User's answer (turn 2):**
> "Internal tooling. We're a 6-person engineering team at a small SaaS company. I want to give the team shared agents — like, helpful assistants for code review, ticket triage, on-call summaries, that kind of thing. We use Claude Code already individually but each person reinvents their own setup."

**Effect on framing:** Locked design space to dev-productivity tooling. Eliminated product/customer-facing patterns. Made "no new infra" defensible. This decision then drove the Library Frame selection in Technique B (turn 11) and the Claude Code plugin adoption in Phase 3.5.

## Discovery axes touched (from new "Discovery axes to consider" section)

| Axis | Where touched |
|------|---------------|
| Purpose / audience | Turn 1 (explicit) — internal tooling for 6-person eng team |
| Scale | Turn 2 (incidental in user reply) — 6 people |
| Deploy target | Turns 13-14 — GH Actions vs ECS Fargate |
| Lifecycle | Turns 5-7 (subagents/skills, scheduled jobs) — mostly on-demand, one nightly cron |
| Identity / trust | Turn 15 — shared bot identity, single org Anthropic key |
| Operability | Turn 17 — cost/observability; per-run token cap |
| Communication / interaction surface | Turns 7-10 — agent-to-human via Slack/PR/Linear |
| Constraints from outside | Turns 3-4, 9-10, 13-14 — Claude Code, Slack, no-new-infra |

All 8 axes touched. The propose-move-on summary at turn 19 explicitly named the unprobed axes (discoverability, versioning, exact v1 scope) and let the operator decide.

## Technique B — alternative framings

Fired once at turn 11 with three frames (Platform / Library / Reductive). User chose Library frame with a small scheduled-job carve-out. The Reductive frame (Notion prompt page) was a qualitatively different approach, not a smaller version of the platform frame.

A second Technique B firing was *not* triggered in this session because the framing stabilized cleanly after the first firing and the convergence-then-research path took over before another natural convergence emerged. Borderline against the "2-3 times per session" guideline — only one firing — but defensible: research-driven restructuring (Phase 3.5) functioned as a kind of late-stage reframing, and the user signaled clear convergence before any further firing would have been productive.

## Technique D — constraints vs. choices

Fired explicitly multiple times:
- Turn 3 — Claude Code (constraint)
- Turn 9 — Slack (constraint)
- Turn 15 — GH Actions vs ECS Fargate (tested choice)
- Turn 26 — reverse sunk-cost check on "build our own repo" vs. Claude Code plugins (tested choice)
