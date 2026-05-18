# Socrates Split (PR 2) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the in-skill discipline that PR 1 landed into two co-evolving skills under a renamed plugin — `plugins/socrates/` with `/discover` (3 phases: PREMISE, DISCOVER, RED-TEAM-on-outcomes) and `/solution` (6 phases: SHAPE-DISCOVER, CHUNK, RED-TEAM-on-shapes, RESEARCH, ARTIFACT, DISPATCH). Adds shared reference library, sub-skill invocation, session-id-aware JSONL hook.

**Architecture:** Plugin rename + new shared/ dir for cross-skill protocols + new /solution skill with its own artifact template + 6 gates + hook rewrite for session-id matching. No new code outside the bash hook; everything else is markdown prompt engineering plus file moves.

**Tech Stack:** Markdown (skill prompts, references), bash (hook + test), JSON (plugin manifest + marketplace).

---

## Source of truth

Design at **`docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md`** (committed at `2d42bc5`). Each task references a design section; read it for the full content spec.

Section → task mapping:

| Plan task | Design section | What lands |
|---|---|---|
| Task 1 | §1 | Plugin rename `discover` → `socrates` + manifest updates |
| Task 2 | §1, §2 | Create `shared/`, move 4 reference files into it |
| Task 3 | §5 | Create `shared/red-team-protocol.md` (extract mechanics from /discover Phase 3) |
| Task 4 | §2, §7 | Generalize `shared/anti-sycophancy.md`; add `session_id` to WIP format in checkpoint-protocol.md |
| Task 5 | §3 | Trim `/discover/SKILL.md` to 3 phases; update path refs to `../../shared/` |
| Task 6 | §3 | Trim /discover references (artifact-template, artifact-gates, research-protocol) to discovery-only |
| Task 7 | §1 | Move `dispatch-protocol.md` from /discover/references/ to /solution/references/ |
| Task 8 | §4, §8 | Create `/solution/SKILL.md` (6 phases + sub-skill invocation logic) |
| Task 9 | §6 | Create /solution references (`solution-artifact-template.md`, `solution-gates.md`, `research-protocol.md`) |
| Task 10 | §7 | TDD: update `test-mirror-jsonl.sh` for session-id matching + sub-skill scenario |
| Task 11 | §7 | Update `mirror-jsonl.sh` implementation (verify tests pass) |
| Task 12 | — | Update `LIMITATIONS.md` (§10 addressed), `TODO.md` (remove items, add follow-ups) |
| Task 13 | — | Refresh `evals/methodology.md` + `evals/evals.json` (remove stale "constraint or a choice" strings) |
| Task 14 | Verification | Plugin cache refresh + confirm both /discover and /solution available |
| Task 15 | Verification | /discover smoke test (fresh subagent simulates Phase 0 turn post-trim) |
| Task 16 | Verification | /solution smoke test (fresh subagent simulates SHAPE-DISCOVER turn against synthetic discovery.md) |

---

## DRY / YAGNI / TDD applied

- **TDD applies to Tasks 10-11** (hook scripts have a real test). Test-first; verify FAIL; implement; verify PASS.
- **Markdown tasks (1-9, 12-13)** use re-read + grep verification + manual coherence checks. No mock tests.
- **Smoke tests (15-16)** use fresh subagent dispatches with the loaded skill files; not full session validation (that's the operator-driven post-completion run).
- **DRY:** design doc is single source of new content; this plan tells you which file and gives the verification.
- **YAGNI:** PR 3 work (multi-domain, executor routing) is out of scope.
- **One commit per task.** 16 commits total.

---

### Task 1: Plugin rename + manifest updates

**Files:**
- Modify: `.claude-plugin/marketplace.json` (in repo root) — change plugin name `discover` → `socrates`, source `./plugins/discover` → `./plugins/socrates`
- Move: `plugins/discover/` → `plugins/socrates/` (use `git mv`)
- Modify: `plugins/socrates/.claude-plugin/plugin.json` — change `name` field to `socrates`

**Steps:**

1. **Read** the marketplace manifest at `.claude-plugin/marketplace.json` and the plugin manifest at `plugins/discover/.claude-plugin/plugin.json` to confirm current values.
2. **Rename the plugin directory:** `git mv plugins/discover plugins/socrates`.
3. **Update the plugin manifest:** in `plugins/socrates/.claude-plugin/plugin.json`, change `"name": "discover"` → `"name": "socrates"`. Leave description/version as appropriate; minor description tweak optional ("two-skill plugin for Socratic discovery + solution shaping").
4. **Update the marketplace manifest:** in `.claude-plugin/marketplace.json`, change the plugin entry's `name` and `source` fields per the design doc §1.
5. **Verify:**
   - `find plugins/socrates -name "*.md" | head -3` — confirm directory exists with files in it.
   - `grep -n '"name": "socrates"' plugins/socrates/.claude-plugin/plugin.json` — match.
   - `grep -n '"discover"' .claude-plugin/marketplace.json plugins/socrates/.claude-plugin/plugin.json` — should return only matches inside DESCRIPTION strings or skill names (`"name": "discover"` for the /discover skill is fine), not as the plugin name.
   - `ls plugins/discover 2>&1 | grep -q "No such"` — confirm old path is gone.
6. **Commit:**

```bash
git add -A
git commit -m "feat(socrates): rename plugin from discover to socrates (PR2 §1)

git mv plugins/discover -> plugins/socrates. Update marketplace.json
and plugin.json manifest names. Single-skill 'discover' plugin
becomes the two-skill 'socrates' plugin (discover + solution skills
added in subsequent commits).

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §1"
```

---

### Task 2: Create shared/ dir + move 4 reference files

**Files:**
- Create: `plugins/socrates/shared/` directory
- Move (`git mv`): four files from `plugins/socrates/skills/discover/references/` to `plugins/socrates/shared/`:
  - `anti-sycophancy.md`
  - `labeling-protocol.md`
  - `checkpoint-protocol.md`
  - `chunking-guidelines.md`

**Steps:**

1. `mkdir plugins/socrates/shared` (or use `git mv` directly which creates the target dir).
2. `git mv plugins/socrates/skills/discover/references/anti-sycophancy.md plugins/socrates/shared/anti-sycophancy.md` (and similar for the other three).
3. **Verify:**
   - `ls plugins/socrates/shared/` shows all 4 files.
   - `ls plugins/socrates/skills/discover/references/` no longer shows those 4 files (should still show artifact-template, artifact-gates, dispatch-protocol, research-protocol).
4. **Commit:**

```bash
git add -A
git commit -m "feat(socrates): create shared/ dir and move 4 cross-skill references (PR2 §1)

Moves anti-sycophancy.md, labeling-protocol.md, checkpoint-protocol.md,
and chunking-guidelines.md from skills/discover/references/ to
plugins/socrates/shared/. These will be referenced by both /discover
and /solution skills via relative paths from their SKILL.md files.

Skill file path updates (cross-references) land in Tasks 5 and 8.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §1"
```

---

### Task 3: Create shared/red-team-protocol.md by extraction

**Files:**
- Create: `plugins/socrates/shared/red-team-protocol.md`
- Will modify in Task 5: `plugins/socrates/skills/discover/SKILL.md` (Phase 3 → trim mechanics, cite shared protocol)

**Steps:**

1. **Read** current `plugins/socrates/skills/discover/SKILL.md` Phase 3 (RED-TEAM) section. The mechanics include: mode-shift announcement (the "Switching to red-team mode..." block), severity classification (CRITICAL/DISCUSS/MINOR with definitions), finding format, operator response patterns (Accept/Dismiss/Defer), exit criteria.
2. **Extract** those mechanics into `plugins/socrates/shared/red-team-protocol.md`. Skill-independent: don't reference outcomes or shapes specifically — describe the protocol as "red-team checks the conclusions of a phase that produced a structured artifact." Note that each consuming skill provides its own check list.
3. **Verify:**
   - File exists with sections: mode-shift, severity, finding format, response patterns, exit criteria.
   - `grep -n "outcomes\|shapes" plugins/socrates/shared/red-team-protocol.md` should be sparse or absent — file is skill-independent.
4. **Commit:**

```bash
git add plugins/socrates/shared/red-team-protocol.md
git commit -m "feat(socrates): create shared red-team-protocol.md (PR2 §5)

Extracts the mechanics from current /discover Phase 3 (mode-shift
announcement, CRITICAL/DISCUSS/MINOR severity, finding format,
operator response patterns, exit criteria) into a skill-independent
protocol file. Both /discover (red-team-on-outcomes) and /solution
(red-team-on-shapes) reference this protocol; each provides its own
check list inline in its SKILL.md.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §5"
```

---

### Task 4: Generalize anti-sycophancy.md + add session_id to WIP format

**Files:**
- Modify: `plugins/socrates/shared/anti-sycophancy.md`
- Modify: `plugins/socrates/shared/checkpoint-protocol.md`

**Steps:**

1. **anti-sycophancy.md:** per design §2, generalize the Tech-D rule statement and operator-facing prompt template to be skill-agnostic. The rule itself ("EXTERNAL → lock in; PREFERENCE → skill-specific handling") stays. Each skill's specialization (peel-back for /discover; classify-as-candidate for /solution) is noted as a cross-reference to the consuming skill's SKILL.md. Tech-B framings get a note: "/discover's Tech-B fires on alternative outcome framings; /solution's Tech-B fires on alternative shape framings."
2. **checkpoint-protocol.md:** add a `session_id` field to the WIP frontmatter spec. Document that the skill writes the CC session ID into this field at WIP creation time. The hook (Task 10-11) uses this field for disambiguation.
3. **Verify:**
   - `grep -n "session_id" plugins/socrates/shared/checkpoint-protocol.md` returns ≥2 matches (field spec + semantics note).
   - `grep -n "/discover\|/solution" plugins/socrates/shared/anti-sycophancy.md` returns matches in the Tech-D PREFERENCE-path section and Tech-B section — the file is now aware of both consuming skills.
4. **Commit:**

```bash
git add plugins/socrates/shared/anti-sycophancy.md \
        plugins/socrates/shared/checkpoint-protocol.md
git commit -m "feat(socrates): generalize anti-sycophancy + add session_id WIP field (PR2 §2, §7)

anti-sycophancy.md: generalizes Tech-D rule statement and Tech-B
framing to be skill-aware (notes /discover and /solution specializations
of the preference-path and framings). Each consuming skill specializes
in its own SKILL.md.

checkpoint-protocol.md: adds session_id field to WIP frontmatter format.
Skills write CC session ID at WIP creation; hook uses this for
multi-WIP disambiguation (LIMITATIONS §10 fix in Tasks 10-11).

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §2, §7"
```

---

### Task 5: Trim /discover SKILL.md to 3 phases

**Files:**
- Modify: `plugins/socrates/skills/discover/SKILL.md`

**Steps:**

1. **Read** the current SKILL.md to confirm current phase structure (Phase 0, 1, 2, 3, 3.5, 4, 5).
2. **Apply edits** per design §3:
   - Keep Phase 0 (PREMISE CHECK) as-is.
   - Keep Phase 1 (DISCOVER) as-is.
   - **Remove** Phase 2 (CHUNK), Phase 3.5 (RESEARCH), Phase 4 (ARTIFACT — the chunked-artifact version), Phase 5 (DISPATCH).
   - **Renumber** old Phase 3 (RED-TEAM) → new Phase 2. Update internal cross-references (Phase 3 → Phase 2).
   - Update Phase 2 RED-TEAM section: reference `../../shared/red-team-protocol.md` for mechanics; inline the check list specific to outcomes (per design §5 /discover RED-TEAM checks list).
   - Update file path references throughout: `references/anti-sycophancy.md` → `../../shared/anti-sycophancy.md`; same for labeling-protocol, checkpoint-protocol, chunking-guidelines (note: chunking-guidelines won't be referenced by /discover anymore — drop the reference).
   - Update the closing handoff: instead of "dispatch /superpowers per chunk", say "Outcomes captured. To proceed to solutioning, run `/solution <slug>`."
   - **Discovery artifact** now writes to `docs/socrates/discover/<slug>.md` with discovery-only template (Task 6 trims the template).
3. **Verify:**
   - `grep -n "^## Phase [0-5]\|^### Phase" plugins/socrates/skills/discover/SKILL.md` — should show Phase 0, Phase 1, Phase 2. No Phase 3, 4, 5.
   - `grep -n "shared/" plugins/socrates/skills/discover/SKILL.md` — should show ≥3 matches (anti-sycophancy, labeling, checkpoint, red-team-protocol).
   - `grep -n "chunking-guidelines\|CHUNK\|/superpowers" plugins/socrates/skills/discover/SKILL.md` — should return zero / very few matches (CHUNK is the removed phase; /superpowers is dispatched by /solution now).
4. **Commit:**

```bash
git add plugins/socrates/skills/discover/SKILL.md
git commit -m "feat(socrates): trim /discover SKILL.md to 3 phases (PR2 §3)

Removes Phase 2 (CHUNK), Phase 3.5 (RESEARCH), Phase 4 (ARTIFACT
with chunks), Phase 5 (DISPATCH) — these move to /solution.
Renumbers old Phase 3 (RED-TEAM) to new Phase 2. Updates path
references to ../../shared/ for cross-skill protocols. Updates
closing handoff to direct operator to /solution.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §3"
```

---

### Task 6: Trim /discover references (artifact-template, artifact-gates, research-protocol)

**Files:**
- Modify: `plugins/socrates/skills/discover/references/artifact-template.md`
- Modify: `plugins/socrates/skills/discover/references/artifact-gates.md`
- Modify: `plugins/socrates/skills/discover/references/research-protocol.md`

**Steps:**

1. **artifact-template.md:** strip chunk sections, execution-order section, dispatch sections. Keep: header, framing, outcomes, parked shapes, external constraints, red-team findings (outcome-level), discovery log (collapsed). Discovery artifact is now ~150 lines of structure; pure-outcome.
2. **artifact-gates.md:** keep G1 (provenance), G3 (open choices justification — now "open axes justification" for /discover), G4 (future-pull). Drop G2 (tested choices alternatives — moves to /solution gates) since /discover doesn't record tested-choice shapes (those are parked or peeled back; not "tested").
3. **research-protocol.md:** trim to discovery-portion only — the shallow build-vs-buy check that fires during RED-TEAM as a finding ("existence question"). Drop the full 6-criteria evaluation methodology; that lives in /solution's research-protocol.md.
4. **Verify:**
   - `grep -n "Chunk\|## Tested choices\|build-vs-buy" plugins/socrates/skills/discover/references/artifact-template.md` — should be zero or minimal.
   - `grep -n "Gate 2" plugins/socrates/skills/discover/references/artifact-gates.md` — zero matches; G2 removed.
   - `grep -n "functionality match\|6 criteria" plugins/socrates/skills/discover/references/research-protocol.md` — zero matches; full evaluation moved out.
5. **Commit:**

```bash
git add plugins/socrates/skills/discover/references/
git commit -m "feat(socrates): trim /discover references to discovery-only (PR2 §3)

artifact-template.md: drops chunk/execution-order/dispatch sections;
keeps header, framing, outcomes, parked shapes, external constraints,
red-team findings, discovery log. Pure-outcome artifact.

artifact-gates.md: keeps G1 (provenance), G3 (open axes justification),
G4 (future-pull). Drops G2 (tested-choice alternatives) — that gate
moves to /solution where 'tested shapes' are recorded.

research-protocol.md: trims to discovery-portion (shallow build-vs-buy
existence check in RED-TEAM). Full 6-criteria evaluation moves to
/solution's research-protocol.md (created in Task 9).

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §3"
```

---

### Task 7: Move dispatch-protocol.md from /discover to /solution

**Files:**
- Move (`git mv`): `plugins/socrates/skills/discover/references/dispatch-protocol.md` → `plugins/socrates/skills/solution/references/dispatch-protocol.md`

**Steps:**

1. Ensure `plugins/socrates/skills/solution/references/` exists (`mkdir -p`).
2. `git mv plugins/socrates/skills/discover/references/dispatch-protocol.md plugins/socrates/skills/solution/references/dispatch-protocol.md`
3. **Verify:**
   - `ls plugins/socrates/skills/solution/references/dispatch-protocol.md` — exists.
   - `ls plugins/socrates/skills/discover/references/dispatch-protocol.md 2>&1 | grep -q "No such"` — old path gone.
4. **Commit:**

```bash
git add -A
git commit -m "feat(socrates): move dispatch-protocol to /solution (PR2 §1)

dispatch-protocol.md describes how to launch /superpowers per chunk —
that responsibility lives in /solution Phase 5 (DISPATCH) under the
split. Mechanics unchanged; just relocates to the consuming skill's
references/.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §1"
```

---

### Task 8: Create /solution SKILL.md

**Files:**
- Create: `plugins/socrates/skills/solution/SKILL.md`

**Steps:**

1. **Read** design §4 (six phases), §5 (RED-TEAM check list for shapes), §8 (sub-skill invocation mechanics).
2. **Write** the new SKILL.md. Structure (parallels /discover's SKILL.md):
   - YAML frontmatter (`name: solution`, `description: ...`, `when_to_use: ...`, `allowed-tools: ...`)
   - Reference files section (point at `../../shared/anti-sycophancy.md` etc. + local `references/...`)
   - Response labeling section (cite `../../shared/labeling-protocol.md`)
   - Session startup (similar to /discover; reads discovery.md as input)
   - **Six phases**:
     - Phase 0 — SHAPE-DISCOVER (reads parked shapes; Tech-D classifies each as constraint/candidate/default-to-test; Tech-B fires 1-2× with shape-framings)
     - Phase 1 — CHUNK (per `../../shared/chunking-guidelines.md`; per-chunk audit + overload signal check)
     - Phase 2 — RED-TEAM (cite `../../shared/red-team-protocol.md` for mechanics; inline /solution check list per design §5)
     - Phase 3 — RESEARCH (per `references/research-protocol.md` — created in Task 9)
     - Phase 4 — ARTIFACT (per `references/solution-artifact-template.md` + `references/solution-gates.md` — both in Task 9)
     - Phase 5 — DISPATCH (per `references/dispatch-protocol.md` — moved in Task 7)
   - **Sub-skill /discover invocation** subsection in Phase 0 and Phase 2 per design §8
   - Closing instructions
3. Match /discover's voice and structure. Use the labeling protocol's §X.Y.Z format throughout if natural.
4. **Verify:**
   - `grep -n "^## Phase [0-5]" plugins/socrates/skills/solution/SKILL.md` — 6 phases (0-5).
   - `grep -n "shared/" plugins/socrates/skills/solution/SKILL.md` — ≥4 matches (anti-sycophancy, labeling, red-team, checkpoint, chunking).
   - `grep -n "Task(subagent_type" plugins/socrates/skills/solution/SKILL.md` — ≥1 match (sub-skill invocation example).
   - `grep -n "SHAPE-DISCOVER\|parked shape" plugins/socrates/skills/solution/SKILL.md` — multiple matches.
5. **Commit:**

```bash
git add plugins/socrates/skills/solution/SKILL.md
git commit -m "feat(socrates): create /solution SKILL.md (6 phases) (PR2 §4, §8)

Six phases: SHAPE-DISCOVER (parked shape evaluation + Tech-B
shape-framings), CHUNK, RED-TEAM (shapes only), RESEARCH (full
build-vs-buy), ARTIFACT (writes solution.md), DISPATCH (/superpowers
per chunk). Sub-skill /discover invocation in SHAPE-DISCOVER and
RED-TEAM phases for scoped re-discovery when shape evaluation
surfaces an outcome gap. Cross-references shared/ for anti-sycophancy,
labeling, red-team mechanics, checkpoint, chunking.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §4, §8"
```

---

### Task 9: Create /solution references

**Files:**
- Create: `plugins/socrates/skills/solution/references/solution-artifact-template.md`
- Create: `plugins/socrates/skills/solution/references/solution-gates.md`
- Create: `plugins/socrates/skills/solution/references/research-protocol.md`

**Steps:**

1. **solution-artifact-template.md:** per design §6 template. Sections: header (links to discovery artifact), execution order, framing recap, shape decisions, chunks, red-team findings, research outcomes, discovery→solution mapping, parked shapes resolution, discovery log.
2. **solution-gates.md:** per design §6 — six gates (G1 provenance, G2 alternatives, G3 open-shape justification, G4 future-pull, G5 outcome coverage, G6 parked-shapes resolution). Each with format, mechanical check, qualitative check, failure handling pattern (same as /discover gates).
3. **research-protocol.md:** full 6-criteria build-vs-buy from the current /discover research-protocol.md. Adapt phrasing to /solution context (per-chunk + whole-problem search; reverse sunk-cost with verifiability framing inherited from PR 1 addendum).
4. **Verify:**
   - All 3 files exist with the documented section structure.
   - `grep -n "G[1-6]\|Gate [1-6]" plugins/socrates/skills/solution/references/solution-gates.md` — at least 6 distinct gate references.
   - `grep -n "functionality match\|license\|cost\|maintenance\|lock-in\|integration burden" plugins/socrates/skills/solution/references/research-protocol.md` — all 6 criteria present.
5. **Commit:**

```bash
git add plugins/socrates/skills/solution/references/
git commit -m "feat(socrates): create /solution reference files (PR2 §6)

solution-artifact-template.md: structure for solution.md including
shape-decisions / chunks / discovery-solution mapping / parked-shapes
resolution sections.

solution-gates.md: 6 write-time gates. G1-G4 are analogs of /discover
gates adapted to shapes; G5 (outcome coverage) and G6 (parked-shapes
resolution) are NEW gates that enforce the discovery -> solution
contract (no outcome lost, no parked shape orphaned).

research-protocol.md: full Phase 3.5 build-vs-buy methodology with
6-criteria evaluation. Adapted from previous /discover research-protocol
to /solution context (reverse sunk-cost inherits PR 1 verifiability
framing).

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §6"
```

---

### Task 10: TDD — update test-mirror-jsonl.sh for session-id matching

**Files:**
- Modify: `plugins/socrates/hooks/test-mirror-jsonl.sh`

**Steps:**

1. **Read** the current test to confirm existing test cases.
2. **Read** design §7 for the new hook behavior.
3. **Update test cases:**
   - **Case 1 (existing, adapt):** single /discover WIP with `session_id: <id1>` in frontmatter; current session env has matching id; hook mirrors to discover slug.
   - **Case 2 (new):** single /solution WIP with `session_id: <id2>`; hook mirrors to solution slug under `docs/socrates/solution/.wip/<slug>/`.
   - **Case 3 (new, the sub-skill scenario):** TWO WIPs simultaneously — one in `discover/.wip/` with `session_id: <id-sub>`, one in `solution/.wip/` with `session_id: <id-parent>`. Current session env has `<id-parent>`; hook must mirror ONLY to the solution slug, not the discover slug.
   - **Case 4 (existing, preserved):** no WIP exists; hook is no-op.
4. Each test case creates fake WIP files with `session_id` frontmatter, fakes the current session ID via env var or argv, invokes the hook, asserts the JSONL landed at the expected path (and nowhere else).
5. **Run the updated test** — expect **FAIL** because `mirror-jsonl.sh` still scans single subdir / doesn't match session-id. Capture failure output.
6. **Commit (test-only, expected to fail until Task 11):**

```bash
git add plugins/socrates/hooks/test-mirror-jsonl.sh
git commit -m "test(socrates): add session-id matching test cases for hook (PR2 §7, TDD test-first)

Updates test-mirror-jsonl.sh with 4 cases: single /discover WIP,
single /solution WIP, concurrent parent+sub WIPs with distinct
session_id frontmatter (sub-skill scenario), and no-WIP no-op.

Tests currently FAIL — mirror-jsonl.sh still uses single-subdir scan.
Implementation lands in next commit (Task 11) per TDD discipline.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §7"
```

---

### Task 11: Update mirror-jsonl.sh implementation

**Files:**
- Modify: `plugins/socrates/hooks/mirror-jsonl.sh`

**Steps:**

1. **Read** the current hook to confirm behavior.
2. **Implement** per design §7:
   - Read current session ID from CC hook environment (verify the exact env var name CC provides — common candidates: `CLAUDE_SESSION_ID`, `CC_SESSION_ID`, or via hook input args).
   - Scan both `<cwd>/docs/socrates/discover/.wip/*.wip.md` and `<cwd>/docs/socrates/solution/.wip/*.wip.md`.
   - For each WIP file, parse YAML frontmatter for `session_id` field. Use simple grep/awk; don't shell out to a YAML parser.
   - Match WIP whose `session_id` equals current session ID.
   - If exactly 1 match: mirror current session's JSONL to that WIP's slug directory.
   - If 0 matches: no-op (skill hasn't created its WIP yet).
   - If multiple matches: log warning to stderr; no-op.
3. **Run test** — expect **PASS** on all 4 cases. Capture pass output.
4. **Verify:**
   - All test cases pass.
   - `grep -n "session_id" plugins/socrates/hooks/mirror-jsonl.sh` — at least 1 match.
5. **Commit:**

```bash
git add plugins/socrates/hooks/mirror-jsonl.sh
git commit -m "feat(socrates): hook session-id matching (PR2 §7, addresses LIMITATIONS §10)

Hook now reads current session ID from CC env, scans WIPs across
discover/.wip/ and solution/.wip/, matches by session_id frontmatter
field, mirrors current session's JSONL to the matched WIP's slug dir.
Handles sub-skill scenario (parent /solution + sub /discover with
distinct session IDs) correctly.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md §7"
```

---

### Task 12: LIMITATIONS + TODO cleanup

**Files:**
- Modify: `plugins/socrates/skills/discover/LIMITATIONS.md` (if it stays in /discover) OR move to `plugins/socrates/LIMITATIONS.md` (shared, if appropriate)
- Modify: `plugins/socrates/skills/discover/TODO.md` (or shared)

**Steps:**

1. **Decide placement.** LIMITATIONS that span both skills (e.g., §10 hook) → `plugins/socrates/LIMITATIONS.md` (shared). Skill-specific → keep under each skill. Same for TODO. Pragmatic call: move both files to `plugins/socrates/` root (shared) since most items now apply to the plugin as a whole.
2. **LIMITATIONS.md:** mark §10 (JSONL single-WIP) as "addressed in PR 2, 2026-05-15" with reference to the design doc §7. Note any NEW limitations introduced by the split (e.g., "/solution depends on /discover having produced a discovery.md first; no graceful handling if invoked standalone — operator must run /discover first").
3. **TODO.md:** remove "Recursive /discover end-to-end test" iteration candidate (sub-skill invocation makes this structurally tested). Add post-PR 2 follow-ups: "PR 3 candidates" section with multi-domain support, executor routing automation, HIPAA scaffolding.
4. **Verify:**
   - `grep -n "addressed in PR 2" plugins/socrates/LIMITATIONS.md` (or wherever it landed) — ≥1 match.
   - `grep -n "Recursive /discover end-to-end" plugins/socrates/TODO.md` — zero matches.
5. **Commit:**

```bash
git add -A
git commit -m "chore(socrates): LIMITATIONS + TODO cleanup post-PR2 (PR2)

Marks LIMITATIONS §10 (JSONL single-WIP) as addressed in PR 2 via
session-id matching. Adds new limitations introduced by the split
(/solution requires upstream discovery.md). Removes 'Recursive
/discover end-to-end test' TODO (now structurally tested via
sub-skill invocation). Adds PR 3 candidates section.

If files were moved to plugins/socrates/ root for shared scope,
that move is part of this commit.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md"
```

---

### Task 13: Refresh evals/methodology.md + evals/evals.json

**Files:**
- Modify: `plugins/socrates/evals/methodology.md` (or wherever it lives post-shared-move)
- Modify: `plugins/socrates/evals/evals.json`

**Steps:**

1. **methodology.md:** update path references to `plugins/socrates/` instead of `plugins/discover/`. Add a brief note about /solution dimensions: the 7 existing dimensions (D1-D7) apply to /discover sessions; for /solution sessions, add D8 (Outcome-coverage gate enforcement) and D9 (Parked-shapes resolution completeness). Keep the dimension definitions short — design lives in §6 of the PR 2 design doc.
2. **evals.json:** refresh the structural test expectations. Remove or rewrite test cases that reference "constraint or a choice" phrasing — that vocabulary is dead post-PR 1. Replace with verifiability-rule equivalents ("the skill asks for the external source for [X]"). For /solution-relevant tests, add expectations like "Phase 0 SHAPE-DISCOVER processes parked shapes via Tech-D classification."
3. **Verify:**
   - `grep -n "constraint or a choice" plugins/socrates/evals/evals.json` — zero matches.
   - `grep -n "external source\|verifiability" plugins/socrates/evals/evals.json` — multiple matches.
   - `grep -n "D8\|D9\|outcome coverage\|parked.shapes.resolution" plugins/socrates/evals/methodology.md` — ≥1 match each.
4. **Commit:**

```bash
git add plugins/socrates/evals/
git commit -m "chore(socrates): refresh evals for PR 2 architecture

methodology.md: path refs updated; adds D8 (outcome coverage) and D9
(parked-shapes resolution completeness) for /solution sessions; keeps
D1-D7 for /discover sessions.

evals.json: removes 'constraint or a choice' test expectations
(vocabulary dead post-PR 1); replaces with verifiability-rule and
SHAPE-DISCOVER expectations for the new architecture.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md"
```

---

### Task 14: Plugin loads — refresh cache + verify both skills available

**Files:**
- No code changes; verification + cache management

**Steps:**

1. **Refresh the plugin cache:**

```bash
rm -rf /home/ro/.claude/plugins/cache/tools-claude/discover/
rm -rf /home/ro/.claude/plugins/cache/tools-claude/socrates/ 2>/dev/null
# Re-install via the user's normal mechanism, e.g.:
# claude plugin install tools-claude/socrates
# Or manual copy:
mkdir -p /home/ro/.claude/plugins/cache/tools-claude/socrates/1.0.0
cp -r /home/ro/repos/tools-claude/plugins/socrates/* \
      /home/ro/.claude/plugins/cache/tools-claude/socrates/1.0.0/
```

2. **Open a fresh Claude Code session.** In the session, check available skills — both `/discover` and `/solution` should appear (look for `socrates:discover` and `socrates:solution` in the skill list).
3. **No commit needed** — this is operator-side cache management. Document the procedure in the LIMITATIONS or TODO if not already there.
4. **Mark as complete** in TaskUpdate; proceed to smoke tests.

---

### Task 15: /discover smoke test (post-trim)

**Files:**
- May create: `plugins/socrates/evals/reports/pr2-discover-smoke-test.md` (the smoke test output)

**Steps:**

1. **Dispatch fresh subagent** simulating /discover Phase 0 turn against an over-specified test prompt (similar to PR 1's smoke test). Use a NEW test prompt (not the dotfiles-summary one from PR 1).
2. **Verify** the response shows:
   - Phase 0 Step 1 (outcome restatement) — present, separates outcome from solution.
   - Phase 0 Step 1.5 (prompt audit) — lists shape-language.
   - Phase 0 Step 2 (premise check) — 2-3 concrete no-build paths.
   - §X.Y.Z addressing.
   - **NO Phase 2 CHUNK** mentioned (proves trim is effective — old phase numbers don't leak through).
3. **Save the smoke test output** to `evals/reports/pr2-discover-smoke-test.md` for the record.
4. **Commit:**

```bash
git add plugins/socrates/evals/reports/pr2-discover-smoke-test.md
git commit -m "test(socrates): /discover smoke test post-PR2 trim

Single-turn smoke test confirms /discover Phase 0 still works after
the trim. Phase 0 Step 1/1.5/2 all fire; no Phase 2 CHUNK / Phase 3.5
RESEARCH / Phase 4 ARTIFACT / Phase 5 DISPATCH leakage. Trim is clean.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md
'Verification plan'"
```

---

### Task 16: /solution smoke test (SHAPE-DISCOVER turn)

**Files:**
- Create test fixture: synthetic discovery.md + parked-shapes ledger entry
- May create: `plugins/socrates/evals/reports/pr2-solution-smoke-test.md`

**Steps:**

1. **Create fixture:** a synthetic discovery.md (~30 lines) with 2-3 outcomes and a corresponding WIP-style ledger entry with 2-3 parked shapes.
2. **Dispatch fresh subagent** simulating /solution SHAPE-DISCOVER turn against the fixture. Provide the discovery.md + parked-shapes ledger inline in the subagent prompt.
3. **Verify** the response shows:
   - SHAPE-DISCOVER phase identified.
   - Tech-D applied to each parked shape (classification as constraint/candidate/default-to-test).
   - Tech-B fires with 4 alternative shape framings.
   - §X.Y.Z addressing.
   - No /discover Phase 0 / Phase 1 leakage (proves /solution doesn't try to re-do discovery).
4. **Save smoke test output** to `evals/reports/pr2-solution-smoke-test.md`.
5. **Commit:**

```bash
git add plugins/socrates/evals/reports/pr2-solution-smoke-test.md
git commit -m "test(socrates): /solution smoke test (SHAPE-DISCOVER turn)

Single-turn smoke test against synthetic discovery.md fixture
confirms /solution SHAPE-DISCOVER fires correctly. Tech-D classifies
each parked shape (constraint/candidate/default-to-test); Tech-B
presents 4 alternative shape framings; no /discover-phase leakage.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-pr2-design.md
'Verification plan'"
```

---

## Plan completion checklist

- [ ] Task 1: Plugin rename + manifests
- [ ] Task 2: shared/ dir + move 4 references
- [ ] Task 3: Create shared/red-team-protocol.md
- [ ] Task 4: Generalize anti-sycophancy + session_id WIP field
- [ ] Task 5: Trim /discover SKILL.md
- [ ] Task 6: Trim /discover references
- [ ] Task 7: Move dispatch-protocol to /solution
- [ ] Task 8: Create /solution SKILL.md
- [ ] Task 9: Create /solution references
- [ ] Task 10: TDD test-first for hook session-id matching
- [ ] Task 11: Hook implementation passes tests
- [ ] Task 12: LIMITATIONS + TODO cleanup
- [ ] Task 13: Refresh evals
- [ ] Task 14: Plugin cache refresh + both skills load
- [ ] Task 15: /discover smoke test
- [ ] Task 16: /solution smoke test

16 commits total. PR title suggestion: `feat(socrates): split discover into discover + solution skills (PR 2 of 2)`.

Final reviewer dispatch + finishing-a-development-branch after all 16 tasks complete.

---

## Risks and mitigations

- **Risk:** Plugin rename (Task 1) breaks Claude Code's plugin loading. **Mitigation:** marketplace and plugin manifest changes are minimal; cache refresh restores known state.
- **Risk:** Hook session-id matching depends on CC providing the session ID via env or hook args; the exact mechanism isn't verified in design. **Mitigation:** Task 10's TDD step will surface this — if the env var isn't available, the test setup will fail and we'll need to investigate CC's hook input spec before proceeding.
- **Risk:** /solution SKILL.md is the largest new artifact; risk of voice/coverage drift from /discover. **Mitigation:** Task 8 explicitly says "match /discover's voice and structure"; spec + code-quality review of the resulting file.
- **Risk:** The dispatch-protocol move + path references (Tasks 5-7) might leave orphan references. **Mitigation:** verification greps at each task; final code review across the whole PR will catch any drift.
