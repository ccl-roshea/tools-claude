# /discover Socratic Tightening (PR 1) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Land in-skill discipline changes to /discover — Tech-D verifiability rule, Phase 0 prompt-audit, Phase 1 peel-back rule with WIP "Parked shapes" ledger, visible soft-signals every 5 turns, and migration to `docs/socrates/discover/` paths. Foundation for PR 2 (separate plan), which extracts the split into /discover + /solution.

**Architecture:** Behavior-only modifications to existing `plugins/discover/skills/discover/` markdown files plus path updates to two hook scripts. No new files. No skill split. Each commit isolates one logical change to a small file set.

**Tech Stack:** Markdown (skill prompts, references, LIMITATIONS, TODO), bash (mirror-jsonl.sh + its test), Claude Code skill framework.

---

## Source of truth

The full design specification lives at **`docs/plans/2026-05-15-discover-socratic-tightening-design.md`** (committed at `64bc63f`). This plan is the executable counterpart — it tells you which file to modify, which region to replace, which design-doc section defines the new content, and how to verify. **Read the design-doc section before each task; it contains the full new content and rationale that this plan does not duplicate.**

Section-to-task mapping:

| Plan task | Design section | What lands |
|---|---|---|
| Task 1 | §1 Verifiability rule | `references/anti-sycophancy.md` Tech-D revision |
| Task 2 | §3 WIP ledger | `references/checkpoint-protocol.md` Parked-shapes subsection |
| Task 3 | §2 Sharpened Phase 0 | `SKILL.md` Phase 0 Step 1.5 |
| Task 4 | §3 Phase 1 peel-back | `SKILL.md` Phase 1 Tech-D framing + axes re-framing + anti-patterns |
| Task 5 | §4 Visible soft-signals | `SKILL.md` Phase 1 soft-signal cadence sub-section |
| Task 6 | Path migration (hooks) | `hooks/mirror-jsonl.sh` + `hooks/test-mirror-jsonl.sh` |
| Task 7 | Path migration (docs) | path-only string replacements in `SKILL.md` + 4 reference files |
| Task 8 | Touch-ups | `references/artifact-template.md` + `references/artifact-gates.md` minor updates |
| Task 9 | Cleanup | `LIMITATIONS.md` mark §1 + §2 addressed; `TODO.md` remove completed items |
| Task 10 | Validation | run a fresh /discover session, audit per `evals/methodology.md`, record results |

---

## DRY / YAGNI / TDD applied

- **TDD applies cleanly to Task 6** (hook scripts have a real test). Update test first → run → verify FAIL → update implementation → run → verify PASS → commit.
- **For markdown tasks (1-5, 7-9)**, "tests" don't apply but verification does: re-read the modified section, grep for absence of old phrasing and presence of new phrasing, confirm cross-file consistency. Each task lists the exact greps.
- **DRY:** the design doc is the single source of new content; this plan does not duplicate it.
- **YAGNI:** PR 2 work (skill split, /solution, sub-skill invocation) is explicitly out of scope and tasks must not anticipate it.
- **Frequent commits:** one commit per task. 10 commits total.

---

### Task 1: Tech-D verifiability rule (anti-sycophancy.md)

**Files:**
- Modify: `plugins/discover/skills/discover/references/anti-sycophancy.md` (Tech-D section, lines ~13–82)

**Steps:**

1. **Read** design-doc §1 in full. Note the five external-source categories, the citation format, the operator-facing prompt template, and the preference (peel-back) path.
2. **Read** the current Tech-D section in `anti-sycophancy.md`. Confirm baseline: classifies "constraint vs choice" using six categories with V1/future-pull sub-classification.
3. **Identify** replacement region: from heading `## Technique D — Constraints vs. choices (continuous)` through the end of the "Example (anti-pattern — don't do this)" block. Reverse sunk-cost sub-section (later in file) stays as-is.
4. **Apply** the edit. New content per design-doc §1: rule statement, 5 categories with concrete examples, citation format (external = `(source: <category> — <citation>)`; preference = no source field, ledger entry instead), operator-facing prompt template, V1/future-pull sub-classification preserved on lock-in path only, preference path, two new "good" examples (one external, one peel-back), updated anti-patterns including "classifying a shape as constraint without external source citation."
5. **Verify:**
   - `grep -n "constraint or a choice" plugins/discover/skills/discover/references/anti-sycophancy.md` — should return matches ONLY in the Reverse sunk-cost section (later in file).
   - `grep -cn "external source" plugins/discover/skills/discover/references/anti-sycophancy.md` — should return ≥3.
   - `grep -n "regulator\|contract\|deployed system\|prior empirical\|factual measurement" plugins/discover/skills/discover/references/anti-sycophancy.md` — confirm all 5 categories named at least once.
6. **Commit:**

```bash
git add plugins/discover/skills/discover/references/anti-sycophancy.md
git commit -m "feat(discover): Tech-D verifiability rule (PR1 §1)

Replaces 'constraint vs choice' with verifiability rule: lock-in
requires concrete external source citation from one of five categories.
Absence = peel back to the outcome the shape serves; record as Parked
shape (WIP ledger format lands in next commit).

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md §1"
```

---

### Task 2: WIP ledger Parked-shapes subsection (checkpoint-protocol.md)

**Files:**
- Modify: `plugins/discover/skills/discover/references/checkpoint-protocol.md`

**Steps:**

1. **Read** design-doc §3 "WIP ledger: new 'Parked shapes' subsection" — note the YAML structure with 6 fields (`shape`, `parked_at_turn`, `outcome_question`, `introduced_by`, `resolved`, `resolution`).
2. **Read** the current `checkpoint-protocol.md`. Locate the WIP file format documentation. Find where the existing ledger subsections (Constraints / Tested choices / Unclassified specifics) are described.
3. **Insert** a new subsection "Parked shapes" alongside the existing ledger subsections. Include the YAML format, field semantics, and a note that parked shapes carry through to the artifact's "Open choices" section in PR 1 (no /solution skill yet).
4. **Verify:**
   - `grep -n "Parked shapes" plugins/discover/skills/discover/references/checkpoint-protocol.md` — should return ≥2 matches (header + content reference).
   - `grep -n "outcome_question\|introduced_by" plugins/discover/skills/discover/references/checkpoint-protocol.md` — confirm field names present.
5. **Commit:**

```bash
git add plugins/discover/skills/discover/references/checkpoint-protocol.md
git commit -m "feat(discover): WIP ledger Parked-shapes subsection (PR1 §3)

Adds Parked shapes ledger format (yaml: shape, parked_at_turn,
outcome_question, introduced_by, resolved, resolution). Phase 1
peel-back rule (next commit) populates this. PR 2's /solution skill
will consume parked shapes as candidate-shape input set.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md §3"
```

---

### Task 3: Phase 0 Step 1.5 prompt audit (SKILL.md)

**Files:**
- Modify: `plugins/discover/skills/discover/SKILL.md` (Phase 0 section)

**Steps:**

1. **Read** design-doc §2 — note the Step 1.5 shape (operator-facing prompt template), audit heuristic, worked example using May 2026 prompt, caps, anti-patterns.
2. **Read** current `SKILL.md` Phase 0 section. Locate Step 1 (restate outcome) end and Step 2 (premise-check question) start.
3. **Insert** new Step 1.5 between them. Include the operator-facing prompt template, the audit heuristic ("flag phrases that name a how, tool, pattern, or non-functional shape framing"), the 5-phrase cap, the shape-clean fast path (one-sentence audit when prompt has no shape-language), and the anti-patterns ("listing every word", "accepting 'I don't know'", "skipping when prompt looks tight"). Do NOT include the worked example in SKILL.md (it lives in the design doc as derivation).
4. **Verify:**
   - `grep -n "Step 1.5" plugins/discover/skills/discover/SKILL.md` — should return ≥2 matches.
   - `grep -n "shape-language" plugins/discover/skills/discover/SKILL.md` — should return ≥3 matches (in Step 1.5 section).
   - Read SKILL.md Phase 0 end-to-end; verify flow Step 1 → Step 1.5 → Step 2 → Step 3 still reads coherently.
5. **Commit:**

```bash
git add plugins/discover/skills/discover/SKILL.md
git commit -m "feat(discover): Phase 0 Step 1.5 prompt audit (PR1 §2)

Inserts a new Step 1.5 in Phase 0: after restating the outcome, the
agent audits the operator's prompt for solution-shapes (phrases that
look like 'how' rather than 'what'), lists them back, and lets the
operator pre-authorize external lock-ins or defer all to Phase 1.
Prevents shape-smuggling at session start.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md §2"
```

---

### Task 4: Phase 1 peel-back rule + axes re-framing + anti-patterns (SKILL.md)

**Files:**
- Modify: `plugins/discover/skills/discover/SKILL.md` (Phase 1 sections: Tech-D, Discovery axes, anti-patterns)

**Steps:**

1. **Read** design-doc §3 in full — note core Tech-D change for Phase 1, the 8-axis re-framing table (3 of 8 change), and Phase 1 anti-pattern additions.
2. **Read** current `SKILL.md` Phase 1 section. Locate (a) the "Continuous: Technique D" sub-section, (b) the "Discovery axes to consider" sub-section, (c) the existing "Anti-patterns" sub-section at end of Phase 1.
3. **Apply** three edits:
   - (a) Update Tech-D framing in Phase 1 to point at the verifiability rule (cross-reference `references/anti-sycophancy.md` rather than restating the full rule). Update the inline operator-facing phrasing per design-doc §3.
   - (b) Re-frame 3 of 8 axes per design-doc §3 table: Deploy target, Operability, Communication / interaction surface — each becomes an outcome-question with a parenthetical noting the shape-counterpart that gets parked.
   - (c) Add 3 new anti-patterns to the existing list per design-doc §3.
4. **Verify:**
   - `grep -n "verifiability\|external source" plugins/discover/skills/discover/SKILL.md` — should return ≥2 matches in Phase 1.
   - `grep -n "park\|parked" plugins/discover/skills/discover/SKILL.md` — should return ≥3 matches.
   - Re-read the 3 re-framed axes; confirm they are outcome-questions, not shape-questions.
5. **Commit:**

```bash
git add plugins/discover/skills/discover/SKILL.md
git commit -m "feat(discover): Phase 1 peel-back rule + axes re-framing (PR1 §3)

Phase 1 default action becomes apply-the-verifiability-rule (defined
in anti-sycophancy.md). Shapes peel back; only externally-sourced
inputs lock in. Re-frames 3 of 8 discovery axes (deploy target,
operability, communication surface) as outcome-questions with
shape-counterparts parked. Adds 3 anti-patterns.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md §3"
```

---

### Task 5: Visible soft-signals every 5 turns (SKILL.md)

**Files:**
- Modify: `plugins/discover/skills/discover/SKILL.md` (Phase 1 §"Soft signals for 'propose moving on'")

**Steps:**

1. **Read** design-doc §4 — note cadence (N=5 turns), the two format templates (no-signals and signals-firing), the 4 anti-pattern guards.
2. **Read** current `SKILL.md` Phase 1 §"Soft signals for 'propose moving on'". Confirm baseline: signals exist, agent fires "I think [area] is sufficiently explored" prompt when triggered.
3. **Insert** a new sub-section after the existing soft-signals content: "Visible soft-signal checks (every 5 turns)." Include cadence rationale, both format templates (no-signals and signals-firing), and the 4 anti-pattern guards.
4. **Verify:**
   - `grep -n "Soft-signal check (turn" plugins/discover/skills/discover/SKILL.md` — should return ≥2 matches (template examples).
   - `grep -n "every 5 turns\|every N turns" plugins/discover/skills/discover/SKILL.md` — confirm cadence stated.
5. **Commit:**

```bash
git add plugins/discover/skills/discover/SKILL.md
git commit -m "feat(discover): visible soft-signals every 5 turns (PR1 §4)

Agent surfaces inline soft-signal counter status (revisits,
turns-since-new-theme, answer-length-trend, repetitive-question-count)
every 5 turns regardless of whether signals are firing. Predictability
lets the operator call wrap-up before the threshold hits. Closes
TODO 'Visible soft signals' iteration candidate.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md §4"
```

---

### Task 6: Path migration in hooks (TDD)

**Files:**
- Modify: `plugins/discover/hooks/test-mirror-jsonl.sh`
- Modify: `plugins/discover/hooks/mirror-jsonl.sh`

**Steps (classical TDD — test first):**

1. **Read** the design doc's "Path migration" section.
2. **Read** both hook scripts to confirm current paths use `docs/discovery/.wip/`.
3. **Update test first** — `test-mirror-jsonl.sh`: change every `docs/discovery/.wip/` to `docs/socrates/discover/.wip/`. Update test fixture paths if any.
4. **Run test** — expect **FAIL** because `mirror-jsonl.sh` still uses the old path. Capture failure output.
5. **Update implementation** — `mirror-jsonl.sh`: change every `docs/discovery/.wip/` to `docs/socrates/discover/.wip/`.
6. **Run test** — expect **PASS**. Capture pass output.
7. **Verify:**
   - `grep -n "docs/discovery" plugins/discover/hooks/*.sh` — should return ZERO matches.
   - `grep -n "docs/socrates/discover" plugins/discover/hooks/*.sh` — should return matches in both files.
8. **Commit:**

```bash
git add plugins/discover/hooks/test-mirror-jsonl.sh plugins/discover/hooks/mirror-jsonl.sh
git commit -m "feat(discover): migrate hook paths to docs/socrates/discover/ (PR1)

Updates mirror-jsonl.sh and its test to use docs/socrates/discover/.wip/
instead of docs/discovery/.wip/. Prevents collision with other plugins
sharing docs/. Test updated first (TDD); implementation follows.

Existing artifacts in docs/discovery/ stay where they are; new
sessions land under docs/socrates/discover/.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md
'Path migration'"
```

---

### Task 7: Path migration in SKILL.md + reference docs

**Files:**
- Modify: `plugins/discover/skills/discover/SKILL.md`
- Modify: `plugins/discover/skills/discover/references/checkpoint-protocol.md`
- Modify: `plugins/discover/skills/discover/references/dispatch-protocol.md`
- Modify: `plugins/discover/skills/discover/references/research-protocol.md`
- Modify: `plugins/discover/skills/discover/references/artifact-template.md`

**Steps:**

1. **Find all path references:**

```bash
grep -rn "docs/discovery" plugins/discover/skills/discover/
```

2. **Update each occurrence** from `docs/discovery/` to `docs/socrates/discover/`. Use `Edit` per-file to make changes auditable. Be careful: only path strings, not historical references in LIMITATIONS or TODO that describe past behavior.
3. **Verify:**
   - `grep -rn "docs/discovery" plugins/discover/skills/discover/` — should return ZERO matches OUTSIDE of LIMITATIONS.md and TODO.md (where historical mentions are allowed).
   - `grep -rn "docs/socrates/discover" plugins/discover/skills/discover/` — should return ≥5 matches across the 5 modified files.
4. **Commit:**

```bash
git add plugins/discover/skills/discover/SKILL.md \
        plugins/discover/skills/discover/references/checkpoint-protocol.md \
        plugins/discover/skills/discover/references/dispatch-protocol.md \
        plugins/discover/skills/discover/references/research-protocol.md \
        plugins/discover/skills/discover/references/artifact-template.md
git commit -m "feat(discover): migrate SKILL + references to docs/socrates/discover/ (PR1)

String-only update: every docs/discovery/ path reference in SKILL.md
and four reference files becomes docs/socrates/discover/. Matches
hook update from previous commit.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md
'Path migration'"
```

---

### Task 8: artifact-template + artifact-gates touch-ups

**Files:**
- Modify: `plugins/discover/skills/discover/references/artifact-template.md`
- Modify: `plugins/discover/skills/discover/references/artifact-gates.md`

**Steps:**

1. **Read** design-doc "File-by-file changes" entries for these two files.
2. **artifact-template.md:** add a note in the "Open choices" section that it accepts "Shape-candidates deferred to executor" entries carried from the WIP ledger's Parked shapes subsection.
3. **artifact-gates.md:** update Gate 1 source-annotation rule to reference the 5 external categories from the new Tech-D (e.g., "source must cite one of: regulator, contract, deployed system, prior empirical result, factual measurement"). Other gates unchanged.
4. **Verify:**
   - `grep -n "Shape-candidates" plugins/discover/skills/discover/references/artifact-template.md` — should return ≥1 match.
   - `grep -n "regulator\|contract\|deployed system" plugins/discover/skills/discover/references/artifact-gates.md` — should return ≥1 match in Gate 1 context.
5. **Commit:**

```bash
git add plugins/discover/skills/discover/references/artifact-template.md \
        plugins/discover/skills/discover/references/artifact-gates.md
git commit -m "feat(discover): artifact template + gates align with PR1 changes

artifact-template.md: 'Open choices' accepts shape-candidates carried
from Parked shapes. artifact-gates.md: Gate 1 source-annotation
references the 5 external categories from new Tech-D.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md
'File-by-file changes'"
```

---

### Task 9: LIMITATIONS + TODO cleanup

**Files:**
- Modify: `plugins/discover/skills/discover/LIMITATIONS.md`
- Modify: `plugins/discover/skills/discover/TODO.md`

**Steps:**

1. **LIMITATIONS.md:** add a one-line "Status: addressed in PR 1, 2026-05-15. See docs/plans/2026-05-15-discover-socratic-tightening-design.md §1 + §3." to §1 (strawman bypass) and §2 (soft-signal under-fire). Do NOT delete the descriptions — they remain as historical record of what the failure modes were.
2. **TODO.md:** remove the "Strawman challenge" and "Visible soft signals" iteration-candidate items. Add a one-line note: "(Both addressed in PR 1, 2026-05-15.)"
3. **Verify:**
   - `grep -n "addressed in PR 1" plugins/discover/skills/discover/LIMITATIONS.md` — should return ≥2 matches (one in §1, one in §2).
   - `grep -n "Strawman challenge\|Visible soft signals" plugins/discover/skills/discover/TODO.md` — should return ZERO matches in active items section.
4. **Commit:**

```bash
git add plugins/discover/skills/discover/LIMITATIONS.md \
        plugins/discover/skills/discover/TODO.md
git commit -m "chore(discover): mark LIMITATIONS §1 + §2 addressed in PR 1

Adds 'addressed in PR 1' status notes to LIMITATIONS §1 (strawman
bypass) and §2 (soft-signal under-fire). Removes corresponding
iteration candidates from TODO.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md"
```

---

### Task 10: Validation run + audit

**Files:**
- Create: `plugins/discover/skills/discover/evals/reports/<test-slug>.md` (the audit of the validation session)

**Steps:**

1. **Pick a test problem.** Choose a fresh problem statement different from `ai-task-guardrails-framework` and from the May Path B test 1. Single sentence or short paragraph; over-specified is best to exercise the prompt audit.
2. **Run /discover** on the test problem in a fresh repo (or fresh slug in an existing repo). Carry it through Phase 0 → Phase 1 → Phase 3 → artifact write. Do NOT dispatch Phase 5 (out of scope for validation).
3. **During the run, observe:**
   - Does Phase 0 Step 1.5 fire and list shape-language? (Section 2)
   - Does Tech-D apply verifiability rule on every shape? Does any shape escape without external-source citation? (Section 1 + 3)
   - Does the WIP ledger contain a Parked shapes subsection with outcome-questions filled in? (Section 3)
   - Do soft-signal status lines appear at turns 5, 10, 15, …? (Section 4)
4. **After the artifact is written**, apply the evaluation methodology at `plugins/discover/skills/discover/evals/methodology.md` to the session. Score D1–D7. Save the report at `evals/reports/<test-slug>.md`.
5. **Compare grades** against the May 2026 baseline (D3=C, D7=C):
   - **Pass condition:** D3 improves by at least one letter (driven by §1 + §3); D7 correction-ratio drops below 25% (driven by §4 + §2).
   - **Fail condition:** D3 stays at C or below; D7 correction-ratio stays at 35% or above. If fail, capture which discipline change isn't biting and open a follow-up issue before declaring PR 1 done.
6. **Commit the audit report:**

```bash
git add plugins/discover/skills/discover/evals/reports/<test-slug>.md
git commit -m "test(discover): validate PR 1 against fresh /discover session

Applies evals/methodology.md to a fresh session run on the new
discipline. Compares D3 + D7 grades against May 2026 baseline.

Refs: docs/plans/2026-05-15-discover-socratic-tightening-design.md
'Verification plan'"
```

---

## Plan completion checklist

- [ ] Task 1: Tech-D verifiability rule committed
- [ ] Task 2: WIP Parked-shapes subsection committed
- [ ] Task 3: Phase 0 Step 1.5 committed
- [ ] Task 4: Phase 1 peel-back + axes + anti-patterns committed
- [ ] Task 5: Visible soft-signals committed
- [ ] Task 6: Hook paths migrated (TDD) committed
- [ ] Task 7: SKILL + references paths migrated committed
- [ ] Task 8: artifact-template + artifact-gates touch-ups committed
- [ ] Task 9: LIMITATIONS + TODO cleanup committed
- [ ] Task 10: Validation report committed; D3 + D7 improvements confirmed

10 commits total. PR title suggestion: `feat(discover): Socratic tightening (PR 1 of 2 — verifiability + peel-back + visible soft-signals)`.
