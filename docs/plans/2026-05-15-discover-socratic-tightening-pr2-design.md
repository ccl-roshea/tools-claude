# Design: /discover Socratic tightening (PR 2 of 2)

**Date:** 2026-05-15
**Status:** Design approved, ready for implementation plan
**Sequence:** PR 2 of 2 (PR 1 landed in-skill discipline changes; this PR extracts the skill split + supporting infrastructure)
**Repo:** tools-claude
**Affects:** plugin rename + new skill + shared reference dir + hooks + marketplace manifest

## Context

PR 1 (merged at `e33218d`) landed in-skill discipline changes to `/discover`: the verifiability rule, Phase 0 prompt-audit, Phase 1 peel-back rule with WIP Parked-shapes ledger, visible soft-signals every 5 turns, and migration to `docs/socrates/discover/` paths. With those discipline changes in place, the architecture that makes them load-bearing — a clean separation between *outcome discovery* (Socratic on what the operator actually wants) and *shape solutioning* (Socratic on how to satisfy the outcomes) — is now ready to be extracted as a structural skill split.

PR 1's design doc named this extraction as PR 2 scope. The brainstorming session that produced this design fleshed out the open file-layout and protocol-shape decisions deferred at PR 1 time. The architecture (split into `/discover` + `/solution`; rename plugin to `socrates`; shared anti-sycophancy library; sub-skill `/discover` invocation from `/solution`; three artifact tiers) was settled during PR 1 brainstorming and remains unchanged. PR 2 implements it.

The motivation for the split is structural enforcement of the discipline. PR 1 added rules ("peel back shapes, don't classify them in Phase 1") that an LLM running a unified skill may forget under load. PR 2 makes those rules unforgettable by removing the vocabulary that violates them from each skill's prompt context: `/discover` has no concept of "chunk" or "build-vs-buy"; `/solution` has no PREMISE CHECK or outcome-DISCOVER. The wrong move becomes impossible at the file boundary.

## Scope (PR 2)

Six structural changes, plus path/manifest plumbing:

1. **Plugin rename** — `plugins/discover/` → `plugins/socrates/`. Marketplace manifest update.
2. **Shared reference dir** — `plugins/socrates/shared/` holding common protocols (anti-sycophancy, labeling, red-team mechanics, checkpoint, chunking).
3. **/discover skill trim** — strip CHUNK / RESEARCH / ARTIFACT / DISPATCH; keep PREMISE / DISCOVER / RED-TEAM-on-outcomes. /discover now writes a *discovery* artifact only.
4. **/solution skill new** — six-phase skill consuming /discover's discovery artifact; phases SHAPE-DISCOVER / CHUNK / RED-TEAM-on-shapes / RESEARCH / ARTIFACT / DISPATCH. Writes a *solution* artifact + dispatches /superpowers per chunk.
5. **Sub-skill /discover invocation from /solution** — for scoped re-discovery on a specific outcome dimension when shape-evaluation surfaces an outcome gap.
6. **JSONL hook session-id disambiguation** — fixes `LIMITATIONS §10` so the auto-mirror works when /solution and a sub-skill /discover have concurrent WIPs.

---

## Section 1: Plugin rename + shared dir

**Modifies:**
- `tools-claude/.claude-plugin/marketplace.json` — plugin name `discover` → `socrates`; source path `./plugins/discover` → `./plugins/socrates`
- Rename: `plugins/discover/` → `plugins/socrates/` (full directory rename)
- `plugins/socrates/.claude-plugin/plugin.json` — name field update

**New layout:**

```
plugins/socrates/
├── .claude-plugin/plugin.json
├── shared/                          ← NEW
│   ├── anti-sycophancy.md           (moved from skills/discover/references/)
│   ├── labeling-protocol.md         (moved)
│   ├── red-team-protocol.md         (NEW — mechanics extracted from current /discover Phase 3)
│   ├── checkpoint-protocol.md       (moved; serves both skills' WIP format)
│   └── chunking-guidelines.md       (moved; /solution will use it; /discover won't)
├── skills/
│   ├── discover/
│   │   ├── SKILL.md                 (trimmed — see Section 3)
│   │   └── references/
│   │       ├── artifact-template.md  (discovery-specific; what discovery.md looks like)
│   │       ├── artifact-gates.md     (discovery-specific gates)
│   │       └── research-protocol.md  (discovery-portion: shallow build-vs-buy check)
│   └── solution/                     ← NEW
│       ├── SKILL.md                  (6 phases — see Section 4)
│       └── references/
│           ├── solution-artifact-template.md
│           ├── solution-gates.md
│           ├── research-protocol.md  (solution-portion: full Phase 3.5 build-vs-buy)
│           └── dispatch-protocol.md  (moved from current /discover references)
├── hooks/
│   ├── hooks.json
│   ├── mirror-jsonl.sh              (updated for session-id matching)
│   └── test-mirror-jsonl.sh         (updated)
└── evals/
    ├── evals.json
    ├── methodology.md
    └── reports/
```

**Cross-skill references:**

Each `SKILL.md` reads shared files via relative path: `../../shared/anti-sycophancy.md`. The relative form is path-stable across the cache install (the cache mirrors the source tree).

**Path strategy:**

- Existing `docs/socrates/discover/` (locked in PR 1) stays for /discover artifacts and WIPs.
- New `docs/socrates/solution/` added for /solution artifacts and WIPs.
- `plugins/discover/...` references in any remaining file paths become `plugins/socrates/...`.

---

## Section 2: Shared anti-sycophancy library

**Modifies:** `plugins/socrates/shared/anti-sycophancy.md` (post-move).

The Tech-D content from PR 1 stays largely as-written, with one generalization: the rule statement and operator-facing prompt template should be skill-agnostic. Each skill specializes the *question* the rule answers in their own SKILL.md.

- **Generic statement (in `shared/anti-sycophancy.md`):** "When a specific surfaces, classify as EXTERNAL (verifiable via one of 5 categories — lock in) or PREFERENCE / SHAPE (no external source — defer to the skill-specific handling: /discover peels back to outcomes; /solution adds to candidate-shape list)."
- **/discover-specific in `skills/discover/SKILL.md` Phase 1:** "PREFERENCE path: peel back to the outcome the shape serves; park in WIP ledger with outcome-question."
- **/solution-specific in `skills/solution/SKILL.md` SHAPE-DISCOVER:** "PREFERENCE path: classify as candidate (evaluate against alternatives) or default-to-test (run Tech-B's no-build framing against it). Parked-shape ledger entry from /discover is the input set."

Tech-B and Tech-C remain in `shared/anti-sycophancy.md` with skill-specific framings called out:
- **Tech-B in /discover:** alternative *outcome* framings (4 spanning complexity spectrum)
- **Tech-B in /solution:** alternative *shape* framings (4 spanning complexity spectrum, where No-build = adopt existing tool)
- **Tech-C** unchanged in mechanics; the *checks* are skill-specific (see Section 5)

---

## Section 3: /discover skill trim

**Modifies:** `plugins/socrates/skills/discover/SKILL.md`.

**Resulting structure (3 phases):**

- **Phase 0 — PREMISE CHECK.** As-is from PR 1, including Step 1.5 prompt audit. No changes.
- **Phase 1 — DISCOVER.** As-is from PR 1, including the verifiability rule, parked shapes, visible soft-signals. No changes.
- **Phase 2 — RED-TEAM (outcomes only).** Renumbered from current Phase 3. Check list narrowed to outcome-level concerns (see Section 5).

**Removed:** old Phase 2 (CHUNK), old Phase 3.5 (RESEARCH), old Phase 4 (ARTIFACT — discovery version), old Phase 5 (DISPATCH). These move to /solution.

**Artifact change:** /discover still writes an artifact, but it's a *discovery* artifact (outcomes + parked shapes + open axes + external constraints), not the full chunked plan. The template at `references/artifact-template.md` is correspondingly trimmed.

**Handoff:** /discover's closing instruction tells the operator: "Outcomes captured. To proceed to solutioning, run `/solution <slug>`." No automatic dispatch; operator-driven handoff.

---

## Section 4: /solution skill (new)

**Creates:** `plugins/socrates/skills/solution/SKILL.md` + `references/`.

**Six phases:**

- **Phase 0 — SHAPE-DISCOVER.** Reads discovery.md + parked-shapes WIP entries. For each parked shape: Tech-D classifies as constraint (lock in with external citation), candidate (evaluate alternatives via Tech-D's tested-choice path), or default-to-test (Tech-B's no-build framing on it). Tech-B fires 1–2× with alternative *shape* framings (Complex/Middle/Low/No-build).
- **Phase 1 — CHUNK.** Decompose chosen shapes into executor-sized work units. Same chunking guidelines from `shared/chunking-guidelines.md` as current /discover Phase 2. Per-chunk audit + overload signal check.
- **Phase 2 — RED-TEAM (shapes only).** Adversarial pass on shape decisions and chunk structure. Check list specific to shape-level concerns (see Section 5).
- **Phase 3 — RESEARCH (build-vs-buy).** Per-chunk + whole-problem search with the existing 6-criteria evaluation. Reverse sunk-cost check fires here.
- **Phase 4 — ARTIFACT.** Run 6 gates (G1–G6 per Section 6). Write `docs/socrates/solution/<slug>.md`.
- **Phase 5 — DISPATCH.** Sequential /superpowers per chunk in execution order. (Same logic as current /discover Phase 5; moved as-is.)

**Sub-skill /discover invocation:** during Phase 0 SHAPE-DISCOVER or Phase 2 RED-TEAM, if shape evaluation surfaces a previously-unasked outcome dimension, the agent may invoke /discover as a subagent scoped to that dimension (`Task(subagent_type="general-purpose", description="/discover --extend <slug> --on <dim>", prompt=...)`). The sub-discovery returns a delta appended to discovery.md as `## Re-discovery: <date> — <dim>`. /solution resumes with delta in hand.

**Reading:** /solution reads `shared/anti-sycophancy.md`, `shared/labeling-protocol.md`, `shared/red-team-protocol.md`, `shared/checkpoint-protocol.md`, `shared/chunking-guidelines.md` via relative paths from its SKILL.md.

---

## Section 5: RED-TEAM organization

**New file:** `plugins/socrates/shared/red-team-protocol.md`.

**Content:** the mechanics extracted from current /discover Phase 3 — mode-shift announcement template, severity classification (CRITICAL / DISCUSS / MINOR), finding format, operator response patterns (Accept / Dismiss / Defer).

**Each skill's SKILL.md RED-TEAM section** inlines its check list:

**/discover RED-TEAM checks (outcome-level):**
1. Contradictions between outcomes
2. Untested outcome-axes (assumptions not exposed during DISCOVER)
3. Missing outcome dimensions (purpose, scale, lifecycle, identity, trust, operability outcomes)
4. Future-pull contamination of outcomes (V2 features bleeding into V1 outcome statements)
5. Stop-the-clock check (what happens if we stop after /discover?)
6. Parked-shape coverage (every parked shape has an outcome-question filled in)

**/solution RED-TEAM checks (shape-level):**
1. Contradictions between shape decisions
2. Untested shape-defaults (skill-proposed strawmans that escaped Tech-D)
3. Missing concerns at shape level (auth, observability, error handling, cost, performance, deployment, testing, security, data lifecycle)
4. Scope creep — chunks bigger than they need to be
5. Dependency gaps between chunks
6. Outcome coverage — every outcome from discovery.md is addressed by ≥1 chunk
7. Existence question (shallow build-vs-buy preview before RESEARCH does the rigorous version)
8. Future-pull contamination of shapes
9. Parked-shape resolution completeness — every parked shape from /discover has a resolution path (resolved / carried-forward / dropped-with-reason)

---

## Section 6: /solution artifact + gates

**New file:** `plugins/socrates/skills/solution/references/solution-artifact-template.md`.

**Template:**

```markdown
# Solution: <slug>

**Date:** YYYY-MM-DD
**Status:** ...
**Discovery artifact:** docs/socrates/discover/<slug>.md
**Chunks:** N

## Execution order
1. Chunk 1
2. Chunks 2 + 3 (parallelizable)
...

## Framing
(recap of refined problem from /discover)

## Shape decisions
- [Constraint] <text> (source: <category> — <citation>)
- [Tested-shape] <text> — alternatives: [X rejected: reason] [Y rejected: reason]
- [Open shape] <text> — deferred because: <reason>

## Chunks
### Chunk N: <name>
(problem statement, constraints, open choices, dependencies, recommended executor)

## Red-team findings (shape-level)
- ...

## Research outcomes (build-vs-buy)
- Per chunk: candidate evaluations against 6 criteria, classifications
- Whole-problem: ...

## Discovery → Solution mapping
| Discovered outcome | Addressed by chunk(s) |
|---|---|
| Outcome A | Chunk 1, Chunk 2 |

## Parked shapes resolution
| Parked shape | Resolution | Where |
|---|---|---|
| "real-time updates" | Resolved: server-sent events | Chunk 2 |

## Discovery log (collapsed)
```

**New file:** `plugins/socrates/skills/solution/references/solution-gates.md`.

**Six write-time gates:**

- **G1 Shape-decision provenance.** Every `[Constraint]` line has `(source: <category> — <citation>)` with category from the 5-category list.
- **G2 Tested-shape alternatives.** Every `[Tested-shape]` line lists ≥1 alternative with specific rejection reason.
- **G3 Open shape-decisions justification.** Every `[Open shape]` has "deferred because: …" one-liner.
- **G4 Future-pull justification.** Same as /discover Gate 4; likely vacuous if V1-trim was rigorous.
- **G5 Outcome coverage.** Every outcome from discovery.md `## Outcomes` section appears in ≥1 chunk's problem statement. Mechanical check: enumerate discovery outcomes → verify each is referenced in some chunk.
- **G6 Parked-shapes resolution.** Every entry in discovery's WIP `## Parked shapes` list has an entry in solution.md's `## Parked shapes resolution` table. No parked shape silently disappears.

Same failure-handling pattern as /discover gates: surface failures grouped by gate; enter fixup loop; re-run all gates after each fix; only write when all pass.

---

## Section 7: JSONL hook session-id disambiguation

**Modifies:** `plugins/socrates/hooks/mirror-jsonl.sh` + `test-mirror-jsonl.sh`.

**Current behavior:** scans `<cwd>/docs/socrates/discover/.wip/*.wip.md`; acts only if exactly 1 match.

**New behavior:**

1. Read current session ID from CC hook input (provided by Claude Code in hook environment).
2. Scan both `<cwd>/docs/socrates/discover/.wip/*.wip.md` and `<cwd>/docs/socrates/solution/.wip/*.wip.md`.
3. For each WIP file, read YAML frontmatter and extract `session_id` field.
4. Match WIP whose `session_id` equals current session ID.
5. Mirror current session's JSONL to that WIP's slug directory.
6. If no WIP matches (e.g., session not yet through Phase 0): no-op.
7. If multiple WIPs match same session-id (shouldn't happen): log warning to stderr, no-op.

**WIP frontmatter change:** both /discover and /solution write `session_id: <id>` at WIP creation time (Phase 0 / SHAPE-DISCOVER respectively). The session ID is obtained from the CC session (operator-side; Claude Code exposes the current session ID to the running skill).

**Sub-skill invocation:** when /solution dispatches a /discover subagent, the subagent has its own CC session ID and creates its own WIP under `discover/.wip/` with that ID. The parent /solution's WIP keeps the parent's session ID. The hook fires for each session independently and matches correctly.

---

## Section 8: Sub-skill /discover invocation

**Modifies:** `plugins/socrates/skills/solution/SKILL.md`.

**Mechanism:** /solution's Phase 0 SHAPE-DISCOVER and Phase 2 RED-TEAM both gain an "if you find an outcome gap" branch:

```
If, while evaluating a shape, you discover that the discovery artifact
is missing a question about outcome dimension X:

1. Announce to operator: "Shape evaluation surfaced an outcome gap on
   dimension X. Want me to run a scoped /discover on X? (Y/N)"
2. If Y: invoke /discover as a subagent scoped to dimension X.
3. Subagent runs a mini-DISCOVER on dimension X only (no premise check,
   no Tech-B firing, no full red-team). Output: outcome answer.
4. Subagent's result is appended to discovery.md as
   `## Re-discovery: <date> — <dimension>` section.
5. /solution resumes with the new outcome in its working context.
```

**Subagent invocation form:**

```python
Task(
  subagent_type="general-purpose",
  description="/discover scoped re-discovery on <dim>",
  prompt="You are a /discover scoped re-discovery session. Read the
    discovery artifact at <path>. Interrogate dimension <dim> only.
    Use Tech-D verifiability rule on any shapes that surface.
    Output: 1-3 sentence outcome answer for <dim>.
    Append your output to discovery.md as
    `## Re-discovery: <date> — <dim>`. Do not write a solution artifact.
    Do not dispatch /superpowers."
)
```

The subagent's sub-discovery WIP lives at `docs/socrates/discover/.wip/<slug>-redisc-<dim>.wip.md` (or similar slug convention). The hook mirrors its JSONL to a corresponding subdir.

---

## File-by-file changes

| Path | Action |
|---|---|
| `tools-claude/.claude-plugin/marketplace.json` | Update `name` and `source` for discover→socrates rename |
| `plugins/discover/` | **Rename to `plugins/socrates/`** (git mv) |
| `plugins/socrates/.claude-plugin/plugin.json` | Update `name: socrates` |
| `plugins/socrates/skills/discover/references/anti-sycophancy.md` | **Move to `plugins/socrates/shared/anti-sycophancy.md`** + generalize per Section 2 |
| `plugins/socrates/skills/discover/references/labeling-protocol.md` | **Move to `plugins/socrates/shared/labeling-protocol.md`** |
| `plugins/socrates/skills/discover/references/checkpoint-protocol.md` | **Move to `plugins/socrates/shared/checkpoint-protocol.md`** + add `session_id` field to WIP format spec |
| `plugins/socrates/skills/discover/references/chunking-guidelines.md` | **Move to `plugins/socrates/shared/chunking-guidelines.md`** (later consumed by /solution only) |
| `plugins/socrates/shared/red-team-protocol.md` | **CREATE** — extract mechanics from current /discover Phase 3 |
| `plugins/socrates/skills/discover/SKILL.md` | Trim per Section 3 (remove CHUNK / RESEARCH / ARTIFACT / DISPATCH; keep PREMISE / DISCOVER / RED-TEAM-on-outcomes); update path references to `../../shared/...` |
| `plugins/socrates/skills/discover/references/artifact-template.md` | Trim — discovery artifact only (drops chunk/dispatch sections) |
| `plugins/socrates/skills/discover/references/artifact-gates.md` | Trim accordingly — discovery-only gates (G1-G4 unchanged) |
| `plugins/socrates/skills/discover/references/research-protocol.md` | Trim to discovery-portion only (shallow build-vs-buy check, RED-TEAM finding) |
| `plugins/socrates/skills/solution/SKILL.md` | **CREATE** — 6 phases per Section 4 |
| `plugins/socrates/skills/solution/references/solution-artifact-template.md` | **CREATE** per Section 6 |
| `plugins/socrates/skills/solution/references/solution-gates.md` | **CREATE** per Section 6 |
| `plugins/socrates/skills/solution/references/research-protocol.md` | **CREATE** — full Phase 3.5 build-vs-buy (copied/adapted from current discover research-protocol) |
| `plugins/socrates/skills/solution/references/dispatch-protocol.md` | **Move from current /discover references** (DISPATCH belongs to /solution now) |
| `plugins/socrates/hooks/mirror-jsonl.sh` | Update per Section 7 — session-id matching across both subdirs |
| `plugins/socrates/hooks/test-mirror-jsonl.sh` | Update — add test cases for /solution WIP + sub-skill scenario |
| `plugins/socrates/LIMITATIONS.md` | Mark §10 (single-WIP) as addressed in PR 2; note any new limitations introduced |
| `plugins/socrates/TODO.md` | Update — remove "Recursive /discover end-to-end test" (now covered structurally); add post-PR2 follow-ups |
| `plugins/socrates/evals/methodology.md` | Update path references; add /solution-specific dimensions if any |
| `plugins/socrates/evals/evals.json` | Refresh structural test expectations (carry-over from PR 1's known issue; this is the right time to fix) |

---

## Verification plan

1. **Plugin loads.** After rename + manifest update, refresh the plugin cache and confirm both `/discover` and `/solution` appear in Claude Code's available skills.
2. **Hook test.** Updated `test-mirror-jsonl.sh` covers (a) single /discover WIP, (b) single /solution WIP, (c) concurrent parent+sub WIPs with distinct session IDs. All three cases pass.
3. **/discover smoke test.** Fresh subagent simulates one Phase 0 turn against an over-specified prompt (similar to PR 1's smoke test). Verifies Phase 0 still works post-rename and post-trim.
4. **/solution smoke test.** Fresh subagent reads a synthetic discovery.md + parked-shapes ledger; simulates one SHAPE-DISCOVER turn. Verifies: shape-Tech-D classifies parked shapes correctly; Tech-B fires with shape-framings; outcome-coverage tracked.
5. **End-to-end Path B (Task 10 from PR 1 + PR 2 combined).** Real operator-driven full run: /discover → /solution → /superpowers per chunk. Apply `evals/methodology.md`; D3 and D7 grades should improve from May baseline (D3=C, D7=C). Pass: D3 ≥ B, D7 correction-ratio < 25%.

---

## What's NOT in scope (PR 3 candidates)

- **Operator-driven recursive /discover orchestration** beyond the sub-skill mechanism. If operators want to chain /discover sessions on the same project, they do so manually.
- **Multi-domain support / expert registry / domain-aware routing.** V1 of socrates targets one operator + one project at a time.
- **Per-node executor dispatch automation.** Currently the artifact recommends an executor per chunk as a human-readable annotation; PR 2 doesn't add automated routing to non-/superpowers executors.
- **HIPAA scaffolding / PHI primitives.** Operator's compliance posture is SOC2-only; HIPAA stays out.
- **Eval mode automation for the new behaviors.** PR 2 may refresh `evals.json` to remove stale "constraint or a choice" language, but the full N=3 validation matrix that LIMITATIONS §4 calls for is its own workstream.
- **Migration tooling for existing `docs/discovery/` artifacts.** Historical artifacts stay where they are; no rename script.
- **Phase 0 PREMISE-2 in /solution** (re-asking build-vs-buy at whole-solution level). Decided against during brainstorming — Phase 3.5 RESEARCH already fires the whole-problem search.
