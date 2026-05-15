# Evaluation Methodology for `/discover` Sessions

A reusable scorecard for assessing the quality of a `/discover` session beyond the structural smoke tests in `evals/evals.json`.

## Why this exists

`evals/evals.json` (in the discover plugin) is, by the authors' own classification (`LIMITATIONS.md §5`), a structural smoke test: it verifies "do phases fire? does WebSearch run?" but **cannot detect the failure mode the skill is designed to prevent** (sycophantic drift, strawman defaults, weak no-build framings, vague rejection reasons). The authors say real validation requires human-operator runs (Path B). Each Path B run is expensive — N=1 in May 2026, this session as N=2. To get value from these scarce runs, we need a methodology that scores them on the dimensions the structural evals can't.

This methodology pairs a per-dimension rubric with a parallel subagent dispatch plan, so a single audit can cover all dimensions in roughly 2 hours of wall time.

## Inputs required

For any session evaluation:

- **Session JSONL transcript** (the raw turn record from Claude Code; mirror lives at `docs/discovery/<slug>/<session-id>.jsonl` after artifact commit)
- **Exported artifact** at `docs/discovery/<slug>.md`
- **Skill documentation contemporaneous with the session** — pin the version from the session date. Files: `SKILL.md`, all of `references/`, `LIMITATIONS.md`, `evals/evals.json`. Protocols evolve; auditing against current docs when the session predates them produces false negatives.

## The seven dimensions

Each dimension is grounded in something explicit from the skill's own design documents.

| # | Dimension | Source of truth | Scope |
|---|-----------|-----------------|-------|
| D1 | Phase execution and ordering | `SKILL.md` (named phases), `evals/evals.json` structural checks | Procedure compliance |
| D2 | Artifact-time gates 1–4 | `references/artifact-gates.md` | Output integrity |
| D3 | Anti-sycophancy: Tech-D firing on specifics | `references/anti-sycophancy.md`, `LIMITATIONS.md §1, §8` | Anti-drift discipline |
| D4 | Anti-sycophancy: Tech-B alternative framings | `references/anti-sycophancy.md`, `evals/evals.json` test 4 | Frame integrity |
| D5 | Research rigor (Phase 3.5) | `references/research-protocol.md` | Build-vs-buy honesty |
| D6 | Chunk decomposition quality | `references/chunking-guidelines.md` | Executor-readiness |
| D7 | Operator load and friction | `LIMITATIONS.md §3` (Path B baseline = 26 turns) | Cost/value tradeoff |

## Grading anchors

Each dimension produces a letter grade and cited evidence (transcript line refs + artifact line refs).

- **A** — protocol followed completely; behavior matches design intent
- **B** — mostly followed; one or two specific gaps that didn't materially harm the output
- **C** — partial compliance; material gaps that affected the output
- **F** — failed to fire, or fired but produced wrong outcome

Every grade requires **at least one specific evidence reference** (file + line, or transcript record number). "Looks fine" without citation is not acceptable.

## Per-dimension audit procedures

### D1 — Phase execution and ordering

**Verify each:**
1. All six phases (PREMISE / DISCOVER / CHUNK / RED-TEAM / RESEARCH / ARTIFACT) executed visibly. Phase 5 (DISPATCH) is optional — operator may stop after artifact.
2. Phase ordering matches `SKILL.md` (DISCOVER before CHUNK, CHUNK before RED-TEAM, RED-TEAM before RESEARCH, RESEARCH before ARTIFACT).
3. Each phase had ≥1 operator interaction (no silent skipping).
4. Phase-exit ledgers were surfaced and acknowledged before next phase.
5. Phase 0 (PREMISE CHECK) presented 2–3 *concrete* (not generic) no-build paths.
6. First Tech-B firing was at turn 1 immediately after Phase 0 (per `SKILL.md` mandatory rule).

**Tools:** `grep -in 'Phase [0-5]\|RED-TEAM\|premise check\|checkpoint\|ledger\|switching to red-team' <jsonl>` then sample bracketed messages.

### D2 — Artifact-time gates

Run all four gates from `references/artifact-gates.md` against the **written artifact** (not the assembled draft, since the draft isn't preserved).

- **Gate 1 (Constraints provenance):** every line under `## Confirmed constraints` has `[V1]` or `[future-pull, V1-justified: <reason>]` label AND `(source: …)` annotation.
- **Gate 2 (Tested choices alternatives):** every line under `## Tested choices` lists ≥1 alternative with specific rejection reason.
- **Gate 3 (Open choices survival justification):** every entry under `### Open choices` has a "deferred because: …" one-liner.
- **Gate 4 (Empty future-pull justification):** every `[future-pull, V1-justified: <reason>]` has a non-placeholder, concrete V1-impact reason (not "TBD", not "needed for V1", not "may be required").

**Mechanical check:** awk/grep counts violations. Each gate is binary pass/fail.

**Qualitative check (per `LIMITATIONS.md §9`):** even if a gate passes mechanically, flag entries where the contents are *vague*. The agent may satisfice. A rejection reason like "doesn't fit" passes Gate 2 mechanically but should be flagged as substantively weak.

### D3 — Tech-D firing on specifics

This is the dimension `evals.json` cannot test mechanically. The most expensive audit.

**Procedure:**
1. **Enumerate every specific** introduced in the transcript, source-tagged: operator-introduced vs. skill-introduced ("strawman default"). Specifics include named technologies, libraries, protocols, scale numbers, behavioral defaults, policy quotes (the six categories from `references/anti-sycophancy.md`).
2. For each specific, check whether Tech-D fired — visibly (asked operator) or silently (recorded in phase-exit ledger or in artifact's `[V1]` / `[future-pull, V1-justified: …]` / `[V2-driven, deferred]` labels).
3. Build a coverage matrix: rows = specifics, columns = (introduced-by, classified?, classification, source).
4. Flag specifics that escaped classification entirely.
5. **Specifically check skill-proposed strawmans** (`LIMITATIONS.md §1` known failure mode) — these are the ones that historically slip through.

**Scoring:**
- **A** — >90% of specifics classified, including all skill-proposed strawmans
- **B** — >90% classified for operator-introduced; some skill strawmans escape
- **C** — uneven firing; multiple high-stakes specifics unclassified
- **F** — specifics escape into the artifact entirely unlabeled

### D4 — Tech-B alternative framings

**Procedure:**
1. Find Tech-B invocations in transcript (look for "four ways to think about this", or numbered framings 1–4 with complexity-spectrum labels).
2. Spec calls for 2–3 firings: turn 1 (mandatory after Phase 0), at major-direction-emergence, and before move from DISCOVER to CHUNK. Verify count.
3. For each invocation, verify it presents 4 framings spanning the complexity spectrum AND includes a *credible* no-build option (not "just don't build it", not "use a spreadsheet" — see `references/anti-sycophancy.md` "weak no-build" anti-pattern).
4. Verify each frame is qualitatively distinct, not "smaller version of frame 1" (per `evals.json` test 4).

**Scoring:** A = all firings have credible 4-option spectrum; B = firings present but no-build is forced; C = fewer than 2 firings or weak frames; F = no Tech-B firing visible.

### D5 — Research rigor (Phase 3.5)

**Procedure:**
1. Count Phase 3.5 candidate evaluations (look for `Task()` dispatches with research prompts, `WebSearch`, `WebFetch`).
2. For each candidate, verify all six evaluation criteria from `references/research-protocol.md` were considered: functionality match (%), license, cost, maintenance, lock-in, integration burden.
3. Verify each candidate received a classification (Adopt fully / Adopt partially / Reject / Inspire) with a *specific* reason — not "doesn't fit our needs".
4. Verify the **reverse sunk-cost check** fired before Reject classifications: did the skill apply Tech-D to "we want to build this" when a candidate matched?
5. **Spot-audit** 3 candidates in detail (especially the lighter rejections — they're the most likely to be pattern-matched out).

**Scoring:** A = all candidates score against all 6 criteria with specific rejections + reverse sunk-cost fired; B = most criteria covered, some candidates lighter; C = pattern-matched rejections, missing reverse sunk-cost check; F = no per-chunk research, vague rejections.

### D6 — Chunk decomposition quality

**Procedure:**
1. Verify chunk count is justified (single-chunk problems should declare single-chunk; multi-subsystem should chunk).
2. Verify chunk-overload signal check (mandatory at CHUNK exit per `LIMITATIONS.md §11`) was visibly performed for each chunk.
3. Verify per-chunk audit (Step 5b in `SKILL.md`) ran — split-or-not justification + per-open-choice survival justification.
4. Verify each chunk is **self-contained**: paste-ready problem statement + constraints + open choices + dependencies + recommended executor (mental test: "if I copy this section into a fresh /superpowers session, would it work?").
5. Verify dependency annotations are *specific* ("Depends on Chunk 1 (specifically: directory layout + frontmatter conventions)" — not "Depends on Chunk 1").
6. Verify execution order with parallelism notes is present.

**Scoring:** A = self-contained chunks, specific dependencies, signal check + audit visibly ran, parallelism noted; B = mostly-self-contained, one weak chunk; C = vague dependencies or chunks that need cross-reference; F = chunks that can't stand alone.

### D7 — Operator load and friction

**Procedure:**
1. Count operator turns. Compare against `LIMITATIONS.md §3` baseline: Path B Test 1 = **26 turns**, the published "high cost" mark.
2. Classify each operator turn as one of: (a) **response-to-question** (operator answering a clarifying question the agent asked), (b) **agent-corrected** (operator pushing back on agent framing), (c) **operator-driven pivot** (operator introducing new direction the agent didn't anticipate).
3. Compute the agent-corrected ratio. High ratio = agent isn't doing the work the skill is designed to do.
4. Flag long stretches without phase-exit (per `LIMITATIONS.md §2`, soft signals should fire ~10 turns since new theme).

**Scoring:** A = ≤26 turns with low correction ratio (<20%); B = 26–50 turns, mostly agent-driven; C = 50+ turns OR correction ratio >40%; F = operator carrying the session (>60% corrections or frequent unanswered pivots).

## Parallel subagent dispatch plan

Per `general-purpose` subagent dispatched per dimension. Dispatched as one batch of 6 parallel tool calls in a single message.

| Subagent | Covers | Primary input |
|----------|--------|---------------|
| A | D1 + D2 | exported artifact + grep over transcript |
| B | D6 | exported artifact (chunk sections) |
| C | D3 | full transcript scan + artifact constraints list |
| D | D4 | transcript (Phase 1 turns) |
| E | D5 | transcript (Task() dispatches, research turns) + artifact research section |
| F | D7 | full transcript turn count + classification |

Each subagent:
- Reads the dimension's source-of-truth file in `references/` (or `LIMITATIONS.md`)
- Performs the per-dimension procedure
- Returns a structured report with grade + evidence references

The orchestrator (main thread) reads all 6 reports and writes a unified `evaluation-report.md`.

## Output deliverables

This methodology lives at `plugins/discover/skills/discover/evals/methodology.md` (alongside `evals.json`). Per-session evaluation reports live at `plugins/discover/skills/discover/evals/reports/<session-slug>.md`. The session transcript itself stays where the session generated it (`docs/discovery/<slug>/<session-id>.jsonl` in whichever repo the session ran in).

Each session report contains:

- Per-dimension grade (D1–D7) with cited evidence (artifact + transcript line refs)
- A "did well / did not" synthesis
- For each limitation in `LIMITATIONS.md`: whether this session reproduced it
- Optionally: the auditor's hypotheses from a pre-audit read, with confirm/refute notes from the audit

## Verification of the methodology

The methodology itself is sanity-checkable:

1. **Cross-check against `evals.json`** — every structural expectation in `evals.json` should map cleanly into D1 or D2. If something has no home, the methodology has a gap.
2. **Cross-check against `LIMITATIONS.md`** — every known limitation should have a corresponding audit step in some dimension. (Mapped: §1, §8 → D3; §2 → D7; §3 → D7; §5 → entire methodology exists; §9 → D2 qualitative; §11 → D6.)
3. **Spot-check correlation between grades and operator intuition** — present 2–3 strongest findings to the operator. If they match the operator's intuition, the methodology has signal.

## Limitations of this methodology

- **Manual Tech-D audit (D3) is expensive.** A 600-message transcript can take 30+ minutes for one subagent to enumerate every specific.
- **D7 turn classification is judgment-based.** Different auditors may classify "agent-corrected" vs. "response-to-question" differently. Mitigation: cite the turn so the classification is auditable.
- **No cross-session comparator.** The methodology grades one session in isolation. To know whether D7 = B is "normal," we need to grade more sessions and build a baseline distribution.
- **Doesn't measure outcome value.** Even an A-graded session may produce an artifact that turns out to be wrong in execution. The methodology audits process compliance and proxy quality, not "did the resulting design ship and work."
