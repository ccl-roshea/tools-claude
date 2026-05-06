# Checkpoint Protocol

Instructions for maintaining the WIP file during a `/discover` session. Read this when the skill references checkpoint-protocol.md.

## What captures the transcript

The plugin ships a hook (`hooks/mirror-jsonl.sh`) that fires on `Stop` and `SessionEnd`. After every turn it copies the active Claude Code session JSONL from `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl` into `docs/discovery/.wip/<slug>/<session-id>.jsonl`. This is automatic — the agent does not write turn blocks by hand. The hook is conditional: if no WIP file exists in cwd, or if multiple WIPs exist (ambiguous), the hook is a no-op.

The agent's only writes to the WIP file are:
- Creating it after Phase 0 with the YAML header + `## Premise check` section.
- Appending phase-exit ledger entries at every phase boundary (DISCOVER → CHUNK, CHUNK → RED-TEAM, RED-TEAM → RESEARCH, RESEARCH → ARTIFACT).

## WIP file format

**Location:** `docs/discovery/.wip/<topic-slug>.wip.md`

```markdown
---
topic_slug: team-agent-platform
phase: DISCOVER
started: 2026-05-04
---

## Premise check

Ruled out because: <reason>

## Ledgers

(populated at each phase exit)
```

YAML fields: `topic_slug`, `phase`, `started`. Nothing else. The `## Premise check` section is created at session start (after Phase 0 records its outcome). The `## Ledgers` section is created on first phase exit.

## Phase-exit ledger entries

A ledger entry is appended to the `## Ledgers` section at every phase exit (DISCOVER → CHUNK, CHUNK → RED-TEAM, RED-TEAM → RESEARCH, RESEARCH → ARTIFACT). Format:

```text
─── Phase exit: <FROM> → <TO> ───
Constraints (M):
  [V1] <constraint text> (source: <operator quote / external source / inherited from chunk N>)
  [future-pull, V1-justified: <reason>] <constraint text> (source: ...)
  [V2-driven, deferred] note: <text> (source: ...)

Tested choices (K):
  <choice> (alternatives: <list of alternatives considered>)

Unclassified specifics that surfaced this phase (P):
  <specific> — needs Tech-D before phase exits

Want to address the unclassified item now, or proceed to <TO>?
```

- The "Constraints" line format mirrors the labels Tech-D produces (`[V1]`, `[future-pull, V1-justified: ...]`, `[V2-driven, deferred]`).
- The "Unclassified specifics" line is load-bearing: if this list is non-empty at phase exit and the operator chooses to proceed anyway, each unclassified specific is automatically carried into RED-TEAM as a CRITICAL finding.
- The ledger is shown to the operator before the phase-boundary commit, and the operator's decision (proceed / address unclassified items first) is recorded in the next ledger entry under "Constraints" or "Tested choices" as appropriate.

## Slug derivation

After Phase 0, derive a provisional slug: kebab-case from the first 4–5 significant words of the problem statement. Examples: `team-agent-platform`, `auth-redesign`, `cart-graphql-migration`. Use this slug for the WIP filename and YAML field from that point on. If Phase 4 confirms a different final slug, rename both the WIP file and the JSONL directory at that point.

## Phase-boundary commit

At each phase exit, before announcing to the operator that you're moving on:

1. **Surface the phase-exit ledger** to the operator (see "Phase-exit ledger entries" above). Wait for the operator's acknowledgement.
   - If unclassified specifics are present, the operator chooses whether to address them now or proceed (carrying them into RED-TEAM as CRITICAL findings).
2. **Append the ledger entry** to the `## Ledgers` section of the WIP file.
3. Update the `phase` field in YAML to the next phase value.
4. Write the file.
5. Run:
   ```bash
   git add docs/discovery/.wip/<slug>.wip.md docs/discovery/.wip/<slug>/
   git commit -m "chore(discover): checkpoint <slug> — entering <NEXT-PHASE>"
   ```

The commit stages both the WIP file (ledger update) and any JSONLs the hook has accumulated since the last commit.

Phase sequence: `PREMISE CHECK` → `DISCOVER` → `CHUNK` → `RED-TEAM` → `RESEARCH` → `ARTIFACT`. (Phase 0 / PREMISE CHECK does not produce a ledger entry — it produces a `## Premise check` section instead.)

## Resume reconstruction

When invoked as `/discover resume <slug>`:

1. Read `docs/discovery/.wip/<slug>.wip.md`.
2. Parse YAML: extract `topic_slug` and `phase`.
3. Read the `## Premise check` and `## Ledgers` sections. Do **not** read the JSONLs in `docs/discovery/.wip/<slug>/` — they are large and the structured ledger entries are the canonical resume context.
4. Tell the operator:

   > "Resuming `<slug>` from Phase `<phase>`. Confirmed constraints: [list from latest ledger]. Tested choices: [list from latest ledger]. Continuing where we left off."

5. Resume the Socratic flow from the current phase's entry state. Do not re-ask anything covered by the ledger entries.

The hook will resume mirroring on the first turn of the resumed session — a new `<new-session-id>.jsonl` will appear in `docs/discovery/.wip/<slug>/` alongside the prior session's JSONL.

## Completion (end of Phase 4)

After the artifact is written to `docs/discovery/<slug>.md`:

```bash
git mv docs/discovery/.wip/<slug> docs/discovery/<slug>
git rm docs/discovery/.wip/<slug>.wip.md
git add docs/discovery/<slug>.md docs/discovery/<slug>/
git commit -m "docs(discovery): add artifact and transcript for <slug>"
```

The final layout is:
- `docs/discovery/<slug>.md` — the artifact
- `docs/discovery/<slug>/<session-id>.jsonl` — one or more JSONL files, one per Claude Code session that touched this discovery (resumed sessions accumulate)

The WIP file (`docs/discovery/.wip/<slug>.wip.md`) is removed in this commit.
