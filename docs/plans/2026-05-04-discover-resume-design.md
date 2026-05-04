# Design: Cross-session resume for /discover

**Date:** 2026-05-04
**Status:** Approved, ready for implementation

## Context

The `/discover` skill accumulates all state (confirmed constraints, tested choices, explored themes, chunks, red-team findings) in Claude's working memory during phases 1–3.5. The first and only durable write is the Phase 4 artifact commit. If a session runs out of context budget before Phase 4, all discovery work is lost.

`TODO.md` lists "Cross-session resume" as a deferred future capability. This design implements it.

## Approach

A WIP file written to disk after every exchange captures the full session transcript. The YAML front matter holds just enough machine-readable data to route a resume (slug, phase, turn count). On resume, Claude reads the transcript and re-derives all state — no structured state schema to maintain, no sync risk between YAML and internal model. The transcript also serves as a permanent human-readable audit trail of every discovery session.

## File format

**Location:** `docs/discovery/.wip/<topic-slug>.wip.md`

```markdown
---
topic_slug: team-agent-platform
phase: DISCOVER
turn_count: 7
started: 2026-05-04
---

## Session transcript

**Turn 1**
**Q:** What's the primary audience — internal team tooling or a product feature?
**A:** Internal tooling for our engineering team.

**Turn 2**
**Q:** You mentioned Azure. Is that a constraint imposed on you, or a choice?
**A:** Constraint — IT policy after last year's AWS cost incident.

...
```

YAML fields: `topic_slug`, `phase`, `turn_count`, `started`. Nothing else — all discovery content lives in the transcript.

## Session lifecycle

### New session (`/discover <problem>`)

1. After the first exchange, derive a provisional slug (kebab-case, first 4–5 significant words of the problem statement). Create `docs/discovery/.wip/<slug>.wip.md` with the 4-line YAML header and Turn 1.
2. After every subsequent exchange: append the turn to the transcript. Update `turn_count` in YAML. Write to disk. No commit.
3. At each phase boundary: update `phase` in YAML, write to disk, commit.

### Resume (`/discover resume <slug>`)

1. Read `docs/discovery/.wip/<slug>.wip.md`.
2. Parse YAML → know phase and turn count.
3. Read full transcript → re-derive all state (constraints, choices, themes, chunks, red-team findings).
4. Tell the operator: "Resuming `<slug>` from Phase X, Turn N. Based on the transcript, here's what's been established: [brief summary of constraints, choices, current phase status]. Continuing..."
5. Resume the Socratic flow — do not re-ask anything already covered in the transcript.

### Completion (end of Phase 4)

1. Write `docs/discovery/<slug>.md` (the normal artifact, unchanged).
2. Strip the 4-line YAML front matter from the WIP file.
3. Move the remaining transcript to `docs/discovery/<slug>.transcript.md`.
4. Delete `docs/discovery/.wip/<slug>.wip.md`.
5. Single commit: `docs(discovery): add artifact and transcript for <slug>` — includes artifact + transcript.

## Phase boundary commits

| Transition | YAML phase value after commit |
|---|---|
| DISCOVER → CHUNK | `CHUNK` |
| CHUNK → RED-TEAM | `RED-TEAM` |
| RED-TEAM → RESEARCH | `RESEARCH` |
| RESEARCH → ARTIFACT | `ARTIFACT` |
| ARTIFACT complete | WIP deleted, transcript committed |

Commit message per boundary: `chore(discover): checkpoint <slug> — entering <PHASE>`

## Files changed

| File | Change |
|---|---|
| `skills/discover/SKILL.md` | Add "Session startup" section before Phase 1; add per-exchange write reminder in Phase 1; add phase-boundary commit instruction at each phase exit; add Phase 4 finalization steps |
| `skills/discover/references/checkpoint-protocol.md` | New file — full WIP format spec, slug derivation, YAML update instructions, git commands, resume reconstruction protocol, completion cleanup |

## What's out of scope

Phase 5 (DISPATCH) resume: once the artifact is committed, dispatch state is tracked in the artifact itself (links to design docs, upstream decisions). Phase 5 resume is handled by reading the artifact, not the WIP file. No changes needed.
