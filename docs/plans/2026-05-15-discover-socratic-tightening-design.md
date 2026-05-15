# Design: /discover Socratic tightening (PR 1 of 2)

**Date:** 2026-05-15
**Status:** Design approved, ready for implementation plan
**Sequence:** PR 1 of 2 (PR 2 will split /discover into two skills + extract /solution; designed separately)
**Repo:** tools-claude
**Affects:** `plugins/discover/skills/discover/` and `plugins/discover/hooks/`

## Context

The audit at `plugins/discover/skills/discover/evals/reports/ai-task-guardrails-framework.md` graded the May 12–14 /discover session B/C average. Six of eleven items in `LIMITATIONS.md` reproduced. The strongest reproductions were §1 (skill-introduced "strawman" defaults bypass anti-sycophancy) and §2 (soft-signal "propose moving on" check under-fires on long sessions).

The brainstorming session that produced this design surfaced a structural defect the audit underweighted: the skill does not help the operator drop *solution-bias* when their prompt arrives with smuggled solution-shapes. Phase 0 restates the outcome but does not audit the prompt itself for shapes pretending to be requirements. Tech-D fires on named specifics (technologies, libraries) but not on solution-shaped *abstractions* ("comprehensive task instructions with guardrails", "real-time updates"). Both are categorical gaps, not procedural ones.

The longer-term answer is to split /discover into two skills: /discover (Socratic on outcomes) + /solution (Socratic on shapes). PR 1 lands the in-skill discipline changes that make the split meaningful. PR 2 extracts the split. Doing PR 1 first validates the new discipline (verifiability rule, prompt audit, peel-back) in the existing skill before the architectural change. If the discipline has a bug we catch it before refactoring.

## Scope (PR 1)

Four behavioral changes to /discover, one infrastructure change. No skill split yet.

1. **Verifiability rule** — Tech-D revision: lock-in requires a concrete external source citation; absence of citation = peel back.
2. **Sharpened Phase 0** — new Step 1.5 audits the operator's prompt for solution-shapes and lists them back before premise check.
3. **Phase 1 peel-back rule** — when a solution-shape surfaces (operator or skill), peel back to the outcome it serves; record in WIP ledger as a "Parked shape" with its outcome-question.
4. **Visible soft-signals** — every 5 turns the agent reports its soft-signal counter status inline.

Plus path migration: `docs/discovery/` → `docs/socrates/discover/`. Update `mirror-jsonl.sh` accordingly. Existing artifacts stay where they are (no historical migration).

---

## Section 1: Verifiability rule

**Modifies:** `references/anti-sycophancy.md` Tech-D.

**Rule.** When a specific surfaces, classify as either:

- **EXTERNAL** — verifiable via a specific external source from the categories below. Lock in as a constraint.
- **PREFERENCE / SHAPE** — no external source. Peel back to the outcome it serves; do not classify the shape itself.

**External source categories** (five concrete kinds):

1. **Regulator / compliance framework** — SOC2, HIPAA, PCI-DSS, etc. Cite framework + the specific control.
2. **Contract / commercial agreement** — enterprise contract, vendor SLA. Cite contract + clause.
3. **Deployed system** — infrastructure already running. Cite system + version.
4. **Prior empirical result** — previous experiment, POC, or production incident with documentation. Cite result + where recorded.
5. **Factual measurement** — headcount, revenue, scale numbers from observed reality. Cite measurement + when taken.

If the proposed source doesn't fit one of these, treat as preference.

**Source citation format** (tightens the existing `(source: …)` field; no new field):

- External: `(source: <category> — <specific citation>)` — e.g., `(source: regulator — SOC2 CC6.1: logical access controls)`
- Preference: no source field; record under "Parked shapes" in the WIP ledger instead.

**Operator-facing prompt** (replaces current Tech-D phrasing in Phase 1):

> "[X] surfaced. What's the external source? Specifically: is there a (regulator, contract, deployed system, prior empirical result, factual measurement) that mandates this? If yes, cite it and I'll record as constraint. If no, this is a design preference — I'll park it with the outcome-question it raises."

**V1/future-pull sub-classification stays.** After lock-in (external path only), still ask "V1-driven or future-pull?" — unchanged from current.

---

## Section 2: Sharpened Phase 0 (prompt audit)

**Modifies:** `SKILL.md` Phase 0. Adds a new Step 1.5 between current Step 1 (restate outcome) and Step 2 (premise-check question).

**Step 1.5 shape.** After restating the outcome, the agent says:

> "Your prompt also contains shape-language — phrases that look like solutions ('the how') rather than outcomes ('the what'):
>
> - "<quoted phrase>" — looks like <how / tool / pattern / process>
> - …
>
> In Phase 1 each will be put on trial: what outcome does it serve? Want to flag any as definitely-external (regulator, contract, deployed system, prior empirical result, factual measurement)? If so, cite the source and I'll lock it in now. Otherwise I'll park them all for Phase 1."

**Audit heuristic.** Flag phrases that name a how (process, workflow), a tool/technology, a pattern (architectural, behavioral, interaction style), or a non-functional requirement framed as a shape ("first-class citizen", "comprehensive", "primary tool"). Pure outcomes ("juniors execute reliably", "PM legwork off my plate") are not flagged.

**Worked example using the May 2026 session prompt.** Restated outcome (Step 1, unchanged): *"PM legwork off your plate so juniors can execute reliably under SOC2-grade audit."*

Step 1.5 audit:
- "comprehensive task instructions with guardrails" — looks like a how (process)
- "verification and approvals" — looks like a how (process)
- "auditability and compliance as a first-class citizen" — looks like a non-functional shape (auditability traces to SOC2; "first-class citizen" is shape framing)
- "Claude code /cowork as a primary working tool" — looks like a tool choice

**Caps to prevent friction:**

- At most 5 shape-phrases listed; if more, show 5 most load-bearing and note "+N more — will surface in Phase 1."
- Don't list trivial phrases (a noun like "juniors" isn't shape-language; "task instructions with guardrails" is).
- If the prompt has NO shape-language: one-sentence audit ("Prompt is shape-clean. Moving to premise check.").

**Anti-patterns:**

- ❌ Listing every word as a potential shape — be conservative.
- ❌ Accepting "I don't know if it's a constraint" — push to external-with-source or park.
- ❌ Skipping the audit when the prompt looks tight — that's exactly when shape-smuggling happens most.

---

## Section 3: Phase 1 peel-back rule + WIP ledger "Parked shapes"

**Modifies:** `SKILL.md` Phase 1, `references/anti-sycophancy.md` Tech-D, `references/checkpoint-protocol.md` WIP format.

**Core Tech-D change in Phase 1.** Default action becomes "apply the verifiability rule from Section 1." External = lock in with source citation; preference = peel back to outcome and park.

The agent does NOT classify the shape itself on the preference path; it surfaces the outcome-question and adds a WIP-ledger entry.

**WIP ledger: new "Parked shapes" subsection** (added to `checkpoint-protocol.md`):

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

In PR 1 (no /solution skill yet), parked shapes carry through to the artifact's "Open choices" section as "Shape-candidates deferred to executor." PR 2 will hand them to /solution as the candidate-shape input set. The `resolved` field lets later turns convert a parked shape into a tested-choice once its outcome-question is answered.

**Discovery axes re-framing.** The 8 axes in `SKILL.md` Phase 1 are mostly outcome-dimensions; 3 currently allow shape-talk and need re-framing:

| Axis | Re-framed (outcome-only) |
|---|---|
| Purpose / audience | unchanged |
| Scale | unchanged |
| Deploy target | "Where does this need to run, and why?" (operator's "AWS" gets parked unless externally sourced) |
| Lifecycle | unchanged |
| Identity / trust model | unchanged |
| Operability | "What auth / observability / cost / error-handling *outcomes* do you need?" (specific tools — Datadog, OAuth — get parked) |
| Communication / interaction surface | "How is it invoked, how does it respond, who sees output?" (REST/GraphQL/message-bus get parked) |
| Constraints from outside | unchanged |

**What stays stable in PR 1 (revisited in PR 2):**

- **Tech-B (alternative framings).** Still fires 2–3 times. Frames stay roughly as-is for PR 1; deeper re-shape lands in PR 2 with /solution.
- **Phase 3 (RED-TEAM).** Still red-teams what /discover produced. In the new framing that's outcomes + parked-shapes + external constraints. No chunks (those move to /solution in PR 2). Mostly stable; light editing.
- **Per-fire visibility for high-stakes specifics.** Stays — but the inline message changes: "here's the outcome-question I'm parking this shape against — does that capture what you actually want to know?"

**Phase 1 anti-patterns (additions):**

- ❌ Classifying a shape as constraint without external source. Default to peel-back; only lock in with concrete source citation.
- ❌ Accepting a parked-shape's outcome-question as "obvious". Record it explicitly.
- ❌ Letting a parked shape escape Phase 1 unresolved without an outcome-question. Every parked entry has an outcome-question filled in.

---

## Section 4: Visible soft-signals

**Modifies:** `SKILL.md` Phase 1 §"Soft signals for 'propose moving on'". Adds a new sub-section. Satisfies the existing `TODO.md` item.

**Cadence: every 5 turns.** First check at turn 5; subsequent every 5 turns. Picked because the existing soft-signal threshold is 10+ turns since a new theme — a 5-turn cadence gives the operator 2 visibility checks before a signal fires.

**Format.** Single inline line at the appropriate turn.

When no signals firing:

> **Soft-signal check (turn 5):** revisits=0, turns-since-new-theme=3, answer-length-trend=stable, repetitive-question-count=0. No signal firing — continuing.

When ≥1 signal firing:

> **Soft-signal check (turn 15):** revisits=2, turns-since-new-theme=10 ⚠️, answer-length-trend=shortening ⚠️, repetitive-question-count=1. Two signals firing on [substrate selection]. Want to converge or keep digging?

**Anti-pattern guards:**

- ❌ Firing more often than every N turns — N=5 is the floor.
- ❌ Suppressing visibility when no signals fire — show the zero-state. Predictability is the point.
- ❌ Treating the visibility check as a pause for response — it's a status line; no mandatory acknowledgment.
- ❌ Stale counters — increment per-turn before producing the status line.

---

## Path migration

- `docs/discovery/` → `docs/socrates/discover/` for new artifacts going forward.
- WIP path: `docs/discovery/.wip/<slug>.wip.md` → `docs/socrates/discover/.wip/<slug>.wip.md`.
- Mirror path: `docs/discovery/.wip/<slug>/<session-id>.jsonl` → `docs/socrates/discover/.wip/<slug>/<session-id>.jsonl`.
- Existing historical artifacts (e.g., `agent-pm/docs/discovery/ai-task-guardrails-framework.md`) stay where they are. No migration script.
- `mirror-jsonl.sh` and `test-mirror-jsonl.sh` updated to use the new path.

---

## File-by-file changes

| File | Change |
|---|---|
| `plugins/discover/skills/discover/SKILL.md` | Phase 0: add Step 1.5 (prompt audit). Phase 1: update Tech-D framing, re-frame 3 of 8 axes, add visible soft-signal sub-section, add Phase-1 anti-patterns. Update path references throughout to `docs/socrates/discover/`. |
| `plugins/discover/skills/discover/references/anti-sycophancy.md` | Tech-D revision: verifiability rule, five external-source categories, source citation format, operator-facing prompt template. Preserve Tech-B and Tech-C unchanged. |
| `plugins/discover/skills/discover/references/checkpoint-protocol.md` | Add "Parked shapes" subsection format with the 5 fields (shape, parked_at_turn, outcome_question, introduced_by, resolved, resolution). Update path references to `docs/socrates/discover/`. |
| `plugins/discover/skills/discover/references/artifact-template.md` | Minor: "Open choices" section accepts "Shape-candidates deferred to executor" carried from Parked shapes. Update path references. |
| `plugins/discover/skills/discover/references/labeling-protocol.md` | No change. |
| `plugins/discover/skills/discover/references/dispatch-protocol.md` | Path-only update to `docs/socrates/discover/`. |
| `plugins/discover/skills/discover/references/research-protocol.md` | Path-only update. |
| `plugins/discover/skills/discover/references/chunking-guidelines.md` | No content change in PR 1 (chunking moves to /solution in PR 2). |
| `plugins/discover/skills/discover/references/artifact-gates.md` | Minor: Gate 1 source-annotation rule references the 5 external categories. |
| `plugins/discover/skills/discover/LIMITATIONS.md` | Mark §1 (strawman bypass) and §2 (soft-signal under-fire) as "addressed in PR 1, 2026-05-15." |
| `plugins/discover/skills/discover/TODO.md` | Remove "Strawman challenge" and "Visible soft signals" iteration candidates (now done). |
| `plugins/discover/hooks/mirror-jsonl.sh` | Update path from `docs/discovery/.wip/` to `docs/socrates/discover/.wip/`. |
| `plugins/discover/hooks/test-mirror-jsonl.sh` | Update test paths. |

No new files in PR 1.

---

## Verification plan

1. **Hook unit test.** Run `test-mirror-jsonl.sh` with the new path; confirm hook fires correctly against a mock cwd containing `docs/socrates/discover/.wip/<slug>.wip.md`.
2. **Path A re-baseline.** Run /superpowers alone on a fresh test problem (different domain from agent-pm); record baseline Coverage + Correctness.
3. **Path B test session.** Run /discover on the same test problem with the new discipline. Specifically confirm:
   - Phase 0 prompt-audit fires and lists shape-language back to operator (Section 2 working).
   - Tech-D applies verifiability rule on every shape-looking input; no shape gets locked-in without a concrete external source citation (Sections 1 + 3 working).
   - WIP ledger contains "Parked shapes" subsection with outcome-questions filled in for each parked entry (Section 3 working).
   - Soft-signal status lines appear at turns 5, 10, 15, … (Section 4 working).
4. **Apply evaluation methodology** at `plugins/discover/skills/discover/evals/methodology.md` to the test session. Compare D3 + D7 grades against the May 2026 session baseline (D3=C, D7=C). **Target:** D3 improves by at least one letter (driven by Section 1 + 3); D7 correction-ratio drops below 25% (driven by Section 4 + 2).
5. **Manual review of LIMITATIONS.md.** Confirm §1 (strawman bypass) is *structurally* addressed — Phase 1 cannot lock in a shape without a source citation; therefore skill-proposed strawmans cannot escape.

---

## What's NOT in scope (PR 2)

These are explicitly deferred to a separate design doc for PR 2:

- Splitting /discover into /discover + /solution skills.
- Plugin renaming (`plugins/discover/` → `plugins/socrates/`).
- Sub-skill /discover invocation from /solution (scoped re-discovery).
- LIMITATIONS §10 fix (JSONL hook slug-passing for sub-skill scenario).
- Solution artifact template + gates (`docs/socrates/solution/<slug>.md`).
- Tech-B re-shape (alternative outcome-framings vs. shape-framings split).
- Phase 3 RED-TEAM re-shape (red-team only outcomes in /discover, red-team only shapes in /solution).
- Dispatch ownership move (currently /discover → /superpowers; will move to /solution → /superpowers).
- Shared anti-sycophancy library extraction.

PR 1 is intentionally a behavior-only change to the existing skill. The shape (one skill) does not change; the discipline does.
