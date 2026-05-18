# Checkpoint Protocol

Instructions for maintaining the WIP file during a Socrates session (currently `/discover`; `/solution` adopts the same protocol with its own slug directory). Read this when the skill references checkpoint-protocol.md.

## What captures the transcript

The plugin ships a hook (`hooks/mirror-jsonl.sh`) that fires on `Stop` and `SessionEnd`. After every turn it copies the active Claude Code session JSONL from `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl` into the matching WIP's slug directory (`docs/socrates/discover/.wip/<slug>/<session-id>.jsonl` for `/discover`; `docs/socrates/solution/.wip/<slug>/<session-id>.jsonl` for `/solution`). This is automatic — the agent does not write turn blocks by hand. The hook uses the `session_id` field in each WIP's YAML frontmatter (see below) to disambiguate when multiple WIPs exist in the same cwd (e.g., a parent `/solution` session and a child `/discover` sub-skill session). If no WIP's `session_id` matches the current session, the hook is a no-op.

The agent's only writes to the WIP file are:
- Creating it after Phase 0 with the YAML header + `## Premise check` section.
- Appending phase-exit ledger entries at every phase boundary (DISCOVER → CHUNK, CHUNK → RED-TEAM, RED-TEAM → RESEARCH, RESEARCH → ARTIFACT).

## WIP file format

**Location:** `docs/socrates/discover/.wip/<topic-slug>.wip.md`

```markdown
---
topic_slug: team-agent-platform
phase: DISCOVER
started: 2026-05-04
session_id: 01abcd23-4567-89ef-0123-456789abcdef
---

## Premise check

Ruled out because: <reason>

## Ledgers

(populated at each phase exit)
```

YAML fields: `topic_slug`, `phase`, `started`, `session_id`. Nothing else. The `## Premise check` section is created at session start (after Phase 0 records its outcome). The `## Ledgers` section is created on first phase exit.

**`session_id` field semantics:** the Claude Code session ID for the session that created and owns this WIP. Used by the JSONL mirror hook (`hooks/mirror-jsonl.sh`) to disambiguate when multiple WIPs exist in the same cwd — for example, a parent `/solution` session running and a child `/discover` sub-skill session firing in parallel. The hook reads each WIP's frontmatter, extracts `session_id`, and mirrors the current session's JSONL only to the WIP whose `session_id` matches the current session.

- **Where it's written:** the consuming skill creates the WIP at Phase 0 (or SHAPE-DISCOVER for `/solution`); `session_id` is written into the frontmatter at WIP creation, alongside `topic_slug`, `phase`, and `started`. It is not changed after creation.
- **Where the value comes from:** Claude Code exposes the running session's ID to the skill (the session-id environment surfaced to the skill at invocation). The skill reads it and writes it verbatim into the YAML. If the value is unavailable, the skill records `session_id: unknown` and surfaces the issue to the operator — the hook will then no-op for this WIP (safer than mirroring to the wrong slug).
- **Sub-skill case:** when `/solution` dispatches a `/discover` subagent, the subagent runs in its own CC session with its own session ID; it creates its own WIP under `docs/socrates/discover/.wip/` with that subagent's session ID. The parent `/solution`'s WIP keeps the parent's session ID. The hook fires once per session and matches each session's JSONL to the correct WIP.

## Phase-exit ledger entries

A ledger entry is appended to the `## Ledgers` section at every phase exit (DISCOVER → CHUNK, CHUNK → RED-TEAM, RED-TEAM → RESEARCH, RESEARCH → ARTIFACT). Format:

```text
─── Phase exit: <FROM> → <TO> ───
Constraints (M):
  [V1] <constraint text> (source: <category> — <specific citation>)
  [future-pull, V1-justified: <reason>] <constraint text> (source: <category> — <specific citation>)
  [V2-driven, deferred] note: <text> (source: <category> — <specific citation>)

Tested choices (K):
  <choice> (alternatives: <list of alternatives considered>)

Unclassified specifics that surfaced this phase (P):
  <specific> — needs Tech-D before phase exits

Want to address the unclassified item now, or proceed to <TO>?
```

- The "Constraints" line format mirrors the labels Tech-D produces (`[V1]`, `[future-pull, V1-justified: ...]`, `[V2-driven, deferred]`). `<category>` MUST be one of the five from Tech-D's verifiability rule — `regulator`, `contract`, `deployed system`, `prior empirical result`, `factual measurement` — per `anti-sycophancy.md`. Operator-preference shapes do NOT belong in Constraints; they go to the `## Parked shapes` subsection (see below) and the strict source-citation form is what Gate 1 validates against.
- The "Unclassified specifics" line is load-bearing: if this list is non-empty at phase exit and the operator chooses to proceed anyway, each unclassified specific is automatically carried into RED-TEAM as a CRITICAL finding.
- The ledger is shown to the operator before the phase-boundary commit, and the operator's decision (proceed / address unclassified items first) is recorded in the next ledger entry under "Constraints" or "Tested choices" as appropriate.

## Parked shapes

A running ledger subsection that captures solution-shapes (operator-introduced or skill-proposed) which failed Tech-D's verifiability rule and were peeled back to an outcome-question rather than locked in as constraints. Unlike the phase-exit ledger entries above, this subsection is updated as shapes are parked — it is not a phase-exit snapshot. Lives in the WIP file under a top-level `## Parked shapes` heading; format is a YAML list:

```yaml
## Parked shapes
- shape: "real-time updates"
  parked_at_turn: 7
  outcome_question: "How often does the outcome 'real-time' serves actually trigger? What breaks if not met?"
  introduced_by: operator   # or "skill" for skill-proposed strawmans
  resolved: false           # set true when outcome-question is answered later
  resolution: null          # filled with the answered outcome when resolved
- shape: "comprehensive task instructions with guardrails"
  parked_at_turn: 0         # parked from Phase 0 prompt audit
  outcome_question: "What outcome does the 'comprehensive guardrails' frame serve? What junior failure mode is it preventing?"
  introduced_by: operator
  resolved: false
  resolution: null
```

Field semantics (one entry per parked shape):

- `shape` — the verbatim shape-language phrase as it surfaced (operator quote or skill phrasing). Quote it.
- `parked_at_turn` — turn number when the shape was parked. `0` means parked during Phase 0 prompt audit; otherwise the Phase 1 turn index.
- `outcome_question` — the outcome-question the shape gets put on trial against. Required; never leave blank or "obvious." This is what later turns answer to convert the entry to `resolved: true`.
- `introduced_by` — `operator` (came from the prompt or operator response) or `skill` (skill-proposed strawman that failed verifiability). No other values.
- `resolved` — `false` until the outcome-question is answered in a later turn; flip to `true` at that point.
- `resolution` — `null` while unresolved; filled with the answered outcome string when `resolved: true`. The shape is then a candidate for promotion to "Tested choices" in the next phase-exit ledger entry.

PR 1 has no `/solution` skill. Parked shapes that remain unresolved at end-of-session carry through to the artifact's "Open choices" section as "Shape-candidates deferred to executor." (PR 2's `/solution` skill will consume the parked-shapes list as its candidate-shape input set.)

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
   git add docs/socrates/discover/.wip/<slug>.wip.md docs/socrates/discover/.wip/<slug>/
   git commit -m "chore(discover): checkpoint <slug> — entering <NEXT-PHASE>"
   ```

The commit stages both the WIP file (ledger update) and any JSONLs the hook has accumulated since the last commit.

Phase sequence: `PREMISE CHECK` → `DISCOVER` → `CHUNK` → `RED-TEAM` → `RESEARCH` → `ARTIFACT`. (Phase 0 / PREMISE CHECK does not produce a ledger entry — it produces a `## Premise check` section instead.)

## Resume reconstruction

When invoked as `/discover resume <slug>`:

1. Read `docs/socrates/discover/.wip/<slug>.wip.md`.
2. Parse YAML: extract `topic_slug` and `phase`.
3. Read the `## Premise check` and `## Ledgers` sections. Do **not** read the JSONLs in `docs/socrates/discover/.wip/<slug>/` — they are large and the structured ledger entries are the canonical resume context.
4. Tell the operator:

   > "Resuming `<slug>` from Phase `<phase>`. External constraints: [list from latest ledger]. Tested choices: [list from latest ledger]. Continuing where we left off."

5. Resume the Socratic flow from the current phase's entry state. Do not re-ask anything covered by the ledger entries.

The hook will resume mirroring on the first turn of the resumed session — a new `<new-session-id>.jsonl` will appear in `docs/socrates/discover/.wip/<slug>/` alongside the prior session's JSONL.

## Completion (end of Phase 4)

After the artifact is written to `docs/socrates/discover/<slug>.md`:

```bash
git mv docs/socrates/discover/.wip/<slug> docs/socrates/discover/<slug>
git rm docs/socrates/discover/.wip/<slug>.wip.md
git add docs/socrates/discover/<slug>.md docs/socrates/discover/<slug>/
git commit -m "docs(discover): add artifact and transcript for <slug>"
```

The final layout is:
- `docs/socrates/discover/<slug>.md` — the artifact
- `docs/socrates/discover/<slug>/<session-id>.jsonl` — one or more JSONL files, one per Claude Code session that touched this discovery (resumed sessions accumulate)

The WIP file (`docs/socrates/discover/.wip/<slug>.wip.md`) is removed in this commit.
