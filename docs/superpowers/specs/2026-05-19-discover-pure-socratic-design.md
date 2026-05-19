# Design: `/discover` — Pure Socratic Rework

**Date:** 2026-05-19
**Status:** Design draft, pending user review

## Context

`/discover` was originally built to handle outcome-discovery upstream of `/solution`. It evolved into a multi-phase skill (PREMISE CHECK → DISCOVER → RED-TEAM) with classification protocols (Tech-D verifiability rule, parked shapes ledger, shape-language audit) and an alternative-enumeration premise check (no-build paths).

Audit of the current skill against the operator's three-phase mental model — *discovery (problem) → solution (architecture) → execution (build)* — surfaced that several constructs in `/discover` are doing solution-mode work in a discovery wrapper:

- Phase 0 Step 2 enumerates *no-build paths*. That's a build-vs-not-build decision (solution).
- Phase 1 Tech-B enumerates four complexity framings (Complex / Middle / Low / No-build). Those are *amounts of building* (solution). `/solution` already fires identical Tech-B in SHAPE-DISCOVER.
- Phase 0 Step 1.5 shape-language audit asks the operator to *categorize* phrases as externally-sourced or preference. That's labeling, not Socratic.
- Phase 1 Tech-D verifiability rule asks the operator to classify specifics in-line. Classification biases the dialogue.
- Phase 2 RED-TEAM runs structured 6-check adversarial pass with severity classification. Adversarial machinery is solution-style; pure Socratic dialogue pressure-tests via questions, not via labeled findings.

Further: tracking *parked shapes* during `/discover` is premature. Shapes are uttered relative to a problem framing that hasn't been validated yet. If the problem survives Socratic dialogue, `/solution` re-elicits shapes against the validated problem. If the problem doesn't survive, the shapes were attached to a dead framing and would only contaminate downstream solutioning via attachment effect.

The Socratic method, as it actually operates (Maieutic / Reductio / Parallel-case), is question-only: the teacher mirrors, tests with cases, walks premises, and presents parallel cases. No alternative-enumeration, no labeling, no classification. The conclusion lands on the student.

## Goal

`/discover` becomes pure Socratic dialogue on the problem statement. Its only job: pressure-test the operator's stated problem through questioning until the problem statement is stable (or productive aporia is reached). Then write a small artifact (refined problem + outcomes + reframes + transcript) and hand off.

Everything that classifies, labels, parks, enumerates alternatives, or runs structured adversarial passes is removed from `/discover`.

## Non-goals

- Not rewriting `/solution` Phases 1–5 (CHUNK / RED-TEAM / RESEARCH / ARTIFACT / DISPATCH). Only `/solution` Phase 0 changes (it no longer reads parked shapes; it elicits shapes itself).
- Not changing the labeling protocol, the JSONL-mirror hook, the checkpoint plumbing, or the WIP-resume mechanics.
- Not changing the `shared/` anti-sycophancy / red-team / labeling / checkpoint references (`/solution` still uses them).

## Design

### `/discover` skill structure

Single phase: **SOCRATIC DIALOGUE.** The agent's job description fits in one paragraph:

> Ask Socratic questions about the operator's stated problem. Use Maieutic (test with cases), Reductio (walk premises to where they lead), and Parallel-case (introduce mirrors that expose asymmetry). Do not offer alternatives. Do not label phrases. Do not classify in the open. Mirror, test, walk, parallel. Continue until the problem statement is stable or aporia is productive. Then read back and write the artifact.

Operational flow:

1. **Open** by mirroring the stated problem. *"Let me restate: you're saying [problem]. Is that right?"* — Socratic mirror, not outcome-extraction.
2. **Continuous Socratic dialogue.** Each turn, ask one question. Choose the pattern based on what surfaced:
   - Operator stated a definition or rule → test with cases (Maieutic).
   - Operator stated a premise → walk it to where it leads (Reductio).
   - Operator stated something one-sided → introduce a mirror case and ask what's different (Parallel-case).
   - Operator referenced a specific shape (named tool, pattern, technology) → Socratic question about what it gives them ("tell me about [shape] — what does that give you?", "how would you know if you were wrong about [shape]?"). Do not classify the shape.
3. **Convergence signal.** Watch internally for: problem statement is stable across 2-3 turns, operator's answers are confirming rather than refining, productive aporia (operator hits a question they can't answer and that question is now the real problem).
4. **Readback.** At convergence: *"I think the problem is stable. Here's what I'll write down: [refined problem] / [outcomes]. Want to keep digging or wrap?"*
5. **Write artifact** on wrap. Finalize WIP per checkpoint protocol.

### Response length and tone

Each operator-facing turn is **one Socratic question**, plus at most a one-sentence mirror or transition. Target turn length is 1–4 sentences. The example exchanges in `references/socratic-patterns.md` are not stylized for brevity — they model the actual target length and tone.

Specifically:

- No multi-paragraph elaborations. If a turn is more than ~4 sentences, the agent is exposition-ing instead of asking.
- No restating the same idea multiple ways. Once is enough.
- No preambles ("Great question. Let me think about this. Before I dig in..."). Get to the mirror or question.
- The mandatory labeling protocol (`§X.Y.Z`) applies but should be light. For a single-question turn, `§Q1` alone is sufficient — do not nest `§1.1.1.1` subsections inside a short turn.
- Readback at convergence may be slightly longer because it surfaces the proposed Framing + Outcomes — but those are the artifact contents, not exposition.

This is enforced as an anti-pattern in `references/socratic-patterns.md` and (lightly) graded in `evals.json` eval id=1.

### Artifact format (minimal)

`docs/socrates/discover/<topic-slug>.md`

```markdown
# Discovery: <problem title>

**Date:** YYYY-MM-DD
**Status:** Discovery complete, ready for /solution

## Framing

<The refined problem statement — what survived Socratic dialogue.
2–4 sentences. Problem-language only; no shapes, no how.>

### Original statement
> <verbatim operator input>

### Key reframes
- <what changed from the original statement and why>

## Outcomes

The pressure-tested outcomes the operator wants. *What*, not *how*.

- <outcome 1>
- <outcome 2>

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

- **Q:** <question>
  **A:** <operator answer>
  **Impact:** <how this changed the framing>

</details>
```

**Removed from current template:** `External constraints`, `Parked shapes`, `Open axes`, `Red-team findings` (Addressed + Accepted risks subsections). All four are evaluable only against a validated problem — they belong in `/solution`, not upstream of validation.

### Reference files in `/discover`

**New:**

- `references/socratic-patterns.md` — Maieutic / Reductio / Parallel-case with worked examples (the three examples the operator provided in §Q4 dialogue). Loaded at session start, alongside `labeling-protocol.md`. Replaces the operator-facing classification protocols.

**Modified:**

- `references/artifact-template.md` — strip to the minimal template above.
- `references/artifact-gates.md` — strip to two gates:
  - **G1: Framing is problem-language only.** No shape-language (named tools, patterns, technologies). If shape-language appears in the Framing or Outcomes sections, the gate fails — agent re-runs a final Socratic peel on those phrases.
  - **G2: Original statement is verbatim.** Mechanical check.

**Deleted:**

- `references/research-protocol.md` (the shallow existence check) — solution-style; lives only in `/solution`.

### `/discover` SKILL.md — sections to delete

- Phase 0 PREMISE CHECK (entire section, lines 82–148): premise check + shape-language audit + handle-response branches.
- Phase 1 Tech-B 4-option framings (lines 189–207) and all Tech-B references (line 64 "First Tech-B firing", line 194 "Before you propose moving from DISCOVER to RED-TEAM").
- Phase 1 Tech-D protocol (lines 160–187): the user-facing classification protocol + V1/future-pull sub-classification + per-fire visibility format. Tech-D moves to `/solution` only.
- Phase 1 soft-signal counters with visible 5-turn check (lines 223–242): replaced by a single convergence check at the agent's judgment.
- Phase 1 discovery-axes list (lines 261–272): becomes a teacher-side reminder in `references/socratic-patterns.md` (where Socratic questions tend to bite), never presented to the operator.
- Phase 2 RED-TEAM (entire section, lines 286–321): structured 6-check pass replaced by the readback turn in step 4 of the new flow.

### `/discover` SKILL.md — sections to keep

- Frontmatter (`name`, `description`, `when_to_use`, `allowed-tools`). Description and `when_to_use` need light updates — drop the phrases "pressure-tests the user's problem framing, applies the verifiability rule to surface untested assumptions (parking shape-decisions against their outcome-questions for later solutioning)" and replace with a Socratic-method-oriented summary.
- Response labeling section (§X.Y.Z labels) — unchanged.
- Session startup (new session / resume) — adjusted for the simpler artifact + single-phase flow.
- Closing (artifact write + handoff message) — adjusted for the minimal template.

### `/solution` changes

**The Socratic method extends into `/solution`** — applied to the *solution* space, not the *claim* space. `/discover` already validated the problem; `/solution` now pressure-tests proposed solutions. Concretely:

- *"Do you really need to build this?"* survives in `/solution` as Tech-B's No-build framing (Phase 0 SHAPE-DISCOVER, currently line 140 of `solution/SKILL.md`). This question is preserved; it just lives at the right phase (after the problem is validated, before the build commits).
- The same Socratic patterns that `/discover` uses on problem claims (mirror, test with cases, walk premises, parallel cases) are *also* appropriate when `/solution` is evaluating a shape decision — e.g., when the operator says "I want event-driven," `/solution` can Maieutically test with cases ("what about a case where you need synchronous read-after-write?") rather than just enumerating alternatives. This deeper Socratic alignment of `/solution` is out of scope for this spec but called out as a future direction: today `/solution` uses Tech-D classification and Tech-B enumeration as its primary tools, and that's preserved here unchanged.

Phase 0 SHAPE-DISCOVER opening (currently lines 71–95 of `solution/SKILL.md`):

- Drop step 2 ("Read the parked-shapes section from the discovery artifact … The parked-shapes list is the input set for Phase 0 SHAPE-DISCOVER"). After this rework, there is no parked-shapes section to read.
- Replace with: at SHAPE-DISCOVER turn 1, after reading the discovery artifact (framing + outcomes), open by asking the operator: *"Here's the validated problem and outcomes. What preferences, constraints, or specific shapes do you want to bring into solutioning?"* Tech-D fires on whatever surfaces — this is where Tech-D belongs.
- Tech-B 4-option shape spectrum firing at SHAPE-DISCOVER turn 1 (currently line 130 mandatory) becomes turn 2 instead (after the elicitation turn). The No-build framing — *"outcomes reached by adopting an existing tool / workflow change. No new code."* — is the explicit form of "do you really need to build this?" at the solution level. All other Tech-B / Tech-D mechanics unchanged.

`/solution` Phase 2 RED-TEAM check 9 (parked-shape resolution completeness, line 242) is dropped — there is no parked-shapes ledger to walk anymore. The other 8 checks remain.

`references/solution-gates.md` Gate G6 (parked-shape resolution) is dropped or rephrased as a "shapes elicited at Phase 0 turn 1 have recorded resolutions" check.

### Migration

- Existing `/discover` artifacts in `docs/socrates/discover/` may have sections (`Parked shapes`, `External constraints`, `Open axes`, `Red-team findings`) that the new template doesn't produce. They remain valid historical records. `/solution` reading an old-template artifact picks up parked-shapes from the artifact if present (backward-compat) but doesn't require them.
- Existing in-progress WIP files (`docs/socrates/discover/.wip/<slug>.wip.md`) predate the rework. On `/discover resume <slug>`, agent detects the old phase structure (presence of `## Premise check` / `## Ledgers` sections) and tells the operator: *"This WIP predates the Socratic rework — the old multi-phase protocol no longer exists. Options: (a) extract whatever framing / outcomes the WIP captured into a fresh artifact and ship as-is (skipping new Socratic dialogue), or (b) abandon the WIP and start a fresh `/discover` session."* The "finish under the old protocol" option is not offered — the old protocol's machinery is gone.

### Evals

- `plugins/socrates/skills/discover/evals/evals.json` — refresh. Today's evals grade against the structural outputs (classifications, parked shapes, red-team findings). After this rework, evals grade against Socratic-dialogue qualities: mirror present in opening turn, no alternative-enumeration in any turn, no in-line classification, artifact contains only Framing + Outcomes + reframes.
- `plugins/socrates/evals/reports/pr2-discover-smoke-test.md` — re-run after rework and update.

### Risks

1. **Agent has to be good at Socratic dialogue.** No protocol scaffolding to fall back on. Quality varies more with model capability. Mitigation: `references/socratic-patterns.md` loaded at session start, strong inline anti-patterns in SKILL.md, evals catching alternative-enumeration regressions.
2. **Shape-tracking gap during `/discover`.** Without parked-shapes ledger, `/solution` starts cold and re-elicits. If operator forgets a constraint they mentioned in `/discover`, it could be missed. Mitigation: `/solution`'s elicitation turn explicitly asks "what preferences, constraints, or shapes do you want to bring in?"; the JSONL transcript is available to `/solution` if it needs to scan for missed items.
3. **Some operators want structured outputs.** A leaner artifact may feel less "complete." Mitigation: artifact is still well-structured; just smaller. Worth surfacing in onboarding docs that less-is-more is intentional.

## Implementation surface

Files to modify:

1. `plugins/socrates/skills/discover/SKILL.md` — major rewrite (collapse phases, remove classification protocols, replace with single Socratic dialogue phase).
2. `plugins/socrates/skills/discover/references/artifact-template.md` — strip to minimal template.
3. `plugins/socrates/skills/discover/references/artifact-gates.md` — strip to G1 + G2.
4. `plugins/socrates/skills/discover/references/research-protocol.md` — delete.
5. `plugins/socrates/skills/discover/references/socratic-patterns.md` — new file (Maieutic / Reductio / Parallel-case + teacher-side reminders for where Socratic questions tend to bite).
6. `plugins/socrates/skills/solution/SKILL.md` — Phase 0 SHAPE-DISCOVER opening rewritten (elicit shapes from operator, not from `/discover` ledger). Phase 2 check 9 dropped.
7. `plugins/socrates/skills/solution/references/solution-gates.md` — G6 dropped or rephrased.
8. `plugins/socrates/skills/discover/evals/evals.json` — refresh to grade Socratic-dialogue qualities.
9. `plugins/socrates/skills/discover/evals/methodology.md` — update grading criteria.
10. `plugins/socrates/evals/reports/pr2-discover-smoke-test.md` — re-run and update after rework.
11. `plugins/socrates/TODO.md` — note the rework outcome and any deferred items it surfaces.
12. `plugins/socrates/LIMITATIONS.md` — update if it references the deleted protocols.

Out of scope for this spec (handled by `writing-plans` next):

- Exact diff sequence for SKILL.md rewrite.
- Phase-by-phase implementation order.
- Test plan for verifying no alternative-enumeration regression.
- Migration messaging text for resume of old WIPs.
