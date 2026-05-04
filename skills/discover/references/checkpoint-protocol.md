# Checkpoint Protocol

Instructions for maintaining the WIP file during a `/discover` session. Read this when the skill references checkpoint-protocol.md.

## WIP file format

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

YAML fields: `topic_slug`, `phase`, `turn_count`, `started`. Nothing else. All discovery content lives in the transcript.

## Slug derivation

After the first exchange, derive a provisional slug: kebab-case from the first 4–5 significant words of the problem statement. Examples: `team-agent-platform`, `auth-redesign`, `cart-graphql-migration`. Use this slug for the WIP filename and YAML field from that point on. If Phase 4 confirms a different final slug, rename the WIP file at that point.

## Per-exchange write (every turn, phases 1–3.5)

After every turn — questions, Technique B framings, "propose moving on" exchanges, any exchange:

1. Append the turn block to the transcript section:
   ```
   **Turn N**
   **Q:** <your question or statement>
   **A:** <operator's response>
   ```
2. Increment `turn_count` in the YAML front matter.
3. Rewrite the full file (YAML block + transcript) to `docs/discovery/.wip/<slug>.wip.md`.
4. No git commit.

## Phase-boundary commit

At each phase exit, before announcing to the operator that you're moving on:

1. Update the `phase` field in YAML to the next phase value.
2. Write the file.
3. Run:
   ```bash
   git add docs/discovery/.wip/<slug>.wip.md
   git commit -m "chore(discover): checkpoint <slug> — entering <NEXT-PHASE>"
   ```

Phase sequence: `DISCOVER` → `CHUNK` → `RED-TEAM` → `RESEARCH` → `ARTIFACT`

## Resume reconstruction

When invoked as `/discover resume <slug>`:

1. Read `docs/discovery/.wip/<slug>.wip.md`.
2. Parse YAML: extract `topic_slug`, `phase`, `turn_count`.
3. Read the full transcript.
4. Tell the operator:

   > "Resuming `<slug>` from Phase `<phase>`, Turn `<turn_count>`. Based on the transcript, here's what we've established: [brief summary — list confirmed constraints, tested choices, and current phase status in 3–5 sentences]. Continuing where we left off."

5. Resume the Socratic flow from the current phase's entry state. Do not re-ask any question already in the transcript.

## Completion (end of Phase 4)

After the artifact is written to `docs/discovery/<slug>.md`:

1. Read the WIP file. Remove the YAML front matter block (the `---` line, the four YAML fields, and the closing `---` line — 6 lines total).
2. Write the remaining content (the `## Session transcript` section and everything below it) to `docs/discovery/<slug>.transcript.md`.
3. Stage all three changes together and commit:
   ```bash
   git add docs/discovery/<slug>.md docs/discovery/<slug>.transcript.md
   git rm docs/discovery/.wip/<slug>.wip.md
   git commit -m "docs(discovery): add artifact and transcript for <slug>"
   ```
   This single commit replaces the two-step commit that was previously in Phase 4 Step 5.
