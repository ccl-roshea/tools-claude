# /discover Anti-Sycophancy Hardening — Design

**Date:** 2026-05-04
**Status:** Design approved, ready for implementation plan
**Implementation shape:** Surgical additions (Shape A — extend existing files, add one new reference, do not do a global prose-tightening pass)

## Motivation

A discovery run on a "PM agent" project produced a coherent artifact (`/tmp/pm-agent.md`) but post-hoc review surfaced consistent anti-sycophancy failures across the existing techniques (B, C, D). The failure pattern is not "the agent agreed with everything" — the operator drove several real reframes — but "the agent's anti-sycophancy was reactive rather than proactive, infrequent rather than continuous, and invisible rather than auditable."

Specifically, the review identified five failure modes, all judged by the operator to apply:

1. **Premise drift.** The agent never asked "do you actually need to build this?" The reductive frame in Tech-B fired but only as one of three options, after the framing had already stabilized inside the build assumption.
2. **Quote-as-constraint.** Operator one-liners (e.g., *"we don't want a PM agent without expertise..."*) became load-bearing design defaults (default-ON it-ops consultation in Phase A) without Tech-D pressure. Tech-D's trigger list (named technologies, protocols, libraries, numbers) didn't recognize policy quotes as specifics.
3. **V2-into-V1 leakage.** Constraints driven by an unbuilt remote V2 (e.g., *"core/ has no Claude-runtime-specific imports"*, choice of `structlog` over stdlib *"to avoid migration when the orchestrator arrives"*) were treated as today's V1 constraints. Tech-D didn't sub-classify constraints by scope-of-origin.
4. **Constraints/choices conflation.** The "Confirmed constraints" section mixed real constraints (Plane Cloud is the backend) with untested operator choices (single primary operator, all writes confirmation-gated). Tech-D ran in conversation but didn't enforce its results in the artifact, and the operator had no way to audit what was classified.
5. **Chunk overstuffing + escape hatches.** Chunk 1 of the PM agent discovery was demonstrably oversized; the agent self-flagged ("consider running /discover recursively on this chunk") but did not act, treating the flag as a dispatch-time suggestion rather than a CHUNK-phase requirement. The "Open choices for the executor" section punted foundational decisions (module layout, error policy, idempotency state file schema) without justification.

The interventions in this design target each failure mode with a specific mechanism, plus a layered visibility strategy so that anti-sycophancy work is observable to the operator (per-fire for high-stakes specifics, audit-ledger at phase boundaries, write-time gates at artifact time).

## Goals

1. The agent must challenge the build premise itself before any framing-internal questions — once, mandatorily, with concrete no-build alternatives.
2. The Tech-B alternative-framings step must cover the full complexity spectrum, including a credible no-build option, and must fire early enough to matter.
3. The Tech-D constraint/choice classification must catch behavioral defaults and policy quotes, not only named technologies.
4. Every recorded constraint must be sub-classified by scope-of-origin (V1-driven vs out-of-scope/future-pull), and future-pull constraints must justify their V1 impact or be dropped.
5. The operator must be able to audit, at every phase exit, what has been classified as a constraint vs a tested choice vs an unclassified specific.
6. Chunks that trip overload signals must be decomposed in the CHUNK phase, not punted to dispatch-time-maybe-recursion.
7. Open choices deferred to the executor must each justify why deferral produces a better outcome than resolution-now.
8. The artifact write must be gated on provenance, alternatives, and justifications being present — the artifact cannot ship with these missing.

## Non-goals

- A full prose-tightening pass on existing /discover content. The PM agent failure was specific-discipline-missing, not generally-soft-prose. We strengthen imperative voice in new and modified sections only.
- Changes to /superpowers itself or to its sub-skills (writing-plans, executing-plans, etc.). Those tools are downstream of /discover and not implicated by this failure pattern.
- Changes to the dispatch protocol beyond the move of the chunk-overload self-flag from dispatch-time to CHUNK-phase-exit.
- Restructuring `references/anti-sycophancy.md` around when techniques fire. The current organization (by technique) stays.
- Automated enforcement infrastructure (linters, CI checks). The artifact gate is implemented as agent-driven self-validation in the prompt, not external tooling.

## The intervention

The design adds nine specific mechanisms grouped into three layers (per-fire visible / phase-boundary auditable / artifact-time enforced), plus one new reference file.

### Mechanism 1: Phase 0 — Mandatory premise check

**Where:** new top-level section in `SKILL.md`, before Phase 1 (DISCOVER).

**Entry:** the user has pasted a problem statement. The statement may be vague or specific.

**What the agent does (single mandatory turn):**

1. Restate the highest-level outcome the operator is asking for. *Not* the proposed solution — the *outcome*. (Example: for a "build a PM agent for Plane" input, restate as "you want PM legwork off your plate", not "you want a Plane-integrated agent.")
2. Ask one question with this exact shape:

   > "Before I start asking questions about how to build this, one premise check: is there a path where this outcome gets reached *without building anything new*? Possible no-build paths I can see: [enumerate 2-3 specific ones — adopting an existing tool, changing a workflow, accepting the current pain]. Have you considered these and ruled them out, or is the build premise still open?"

**Operator response paths:**

- **"Considered and ruled out"** — record the ruling reason in the WIP file under a new `Premise check` section. Move to Phase 1.
- **"Open / haven't considered"** — proceed to a brief no-build exploration (1-3 turns). If the no-build path proves viable, suggest stopping the discovery and pursuing it. If not, record what was considered and why building wins. Move to Phase 1.
- **"Don't ask me this"** (operator override) — record the override and the operator's reason. Move to Phase 1.

**Anti-pattern guard:** the agent MUST NOT enumerate generic no-build paths ("just don't build it"). The 2-3 paths must be *concrete to the operator's stated outcome* — for the PM agent input, that would mean "use Plane's MCP directly from your Claude installs," "improve the markdown POC instead of greenfield," "accept that you do PM in Plane manually with a small skill set."

**Exit:** premise check recorded in WIP. Phase advances to DISCOVER.

### Mechanism 2: Tech-B becomes 4-option, first firing at turn 1

**Where:** `references/anti-sycophancy.md` (Tech-B section), and the corresponding section in `SKILL.md`'s Phase 1.

**Updated prompt:**

> "Before we go further, four ways to think about this problem:
>
> 1. **[Complex frame]** — what we've been building toward. Full custom system.
> 2. **[Middle-build frame]** — same outcome, smaller surface. Reuse more, build less.
> 3. **[Low-build frame]** — minimal new code. Glue + configuration over existing tools.
> 4. **[No-build frame]** — outcome reached without writing code. Workflow change, existing tool adoption, accepting the pain.
>
> Which resonates, or is the answer a mix?"

**Critical principle update:** the no-build frame is not a formality. It must be a plausible, concrete path the operator could actually take — same bar as the other three frames. If the agent cannot construct a credible no-build frame for the problem, that is itself a signal the framing is too narrow and needs reconsideration.

**First-firing change:** the first Tech-B firing moves from "after initial framing stabilizes (turns 3-5)" to **"at turn 1, immediately after Phase 0 completes"**. Subsequent firings stay at the existing convergence points (when a major architectural direction emerges; before exiting DISCOVER).

**Rationale:** by turn 3, the operator has typed multiple paragraphs inside the original frame. Firing at turn 1 surfaces alternatives while the cost of switching is still low.

### Mechanism 3: Tech-D — Trigger expansion (sixth category)

**Where:** `references/anti-sycophancy.md` (Tech-D section).

**Existing trigger categories:** named technologies, protocols/patterns, architectural choices, libraries/frameworks, unjustified concrete numbers.

**New sixth category — behavioral defaults / policy quotes:**

- "default-ON [X]", "always [Y] before [Z]", "never [W]", "[X] is the source of truth"
- Operator-quoted rationale that becomes the support for a design rule (e.g., *"we don't want a PM agent without expertise..."* → "default-ON it-ops consultation")
- Any rule about agent behavior whose only support is operator preference, not external constraint

**Trigger phrasing for this category:**

> "You stated [Q]. The rule it justifies is [R]. Is [R] a constraint — something imposed externally — or a preference that should be pressure-tested? Alternatives to [R]: ..."

### Mechanism 4: Tech-D — Constraint sub-classification (V1 vs future-pull)

**Where:** `references/anti-sycophancy.md` (Tech-D section).

When an item is classified as a *constraint* (under any of the now-six trigger categories), the agent immediately asks a follow-up:

> "Is [constraint] driven by V1 needs, or by out-of-scope/future needs (V2 features, hypothetical scale, undeployed systems)?"

**Two outcomes:**

- **V1-driven** → record as `[V1] constraint: ...` Move on.
- **Future-pull** → challenge: *"What specifically about V1 requires this? Would V1 work without it?"* The operator must either:
  - Articulate a concrete V1 impact → recorded as `[future-pull, V1-justified: <reason>] constraint: ...`
  - Acknowledge it's V2-driven → either dropped from V1 design, or recorded as `[V2-driven, deferred] note: ...` (not as a V1 constraint)

**Anti-pattern guard:** the agent MUST run sub-classification on every constraint, not only ones that "feel" V2-ish. The PM agent example shows future-pull constraints often look reasonable on first encounter — they reveal themselves only when the question is asked explicitly.

### Mechanism 5: Per-phase ledger (visibility/audit)

**Where:** added discipline to each phase in `SKILL.md` (DISCOVER through ARTIFACT). Ledger entry format added to `references/checkpoint-protocol.md` so resume reconstruction sees the ledgers.

At every phase exit (before the agent commits the WIP file with the new `phase:` value), the agent surfaces a structured ledger to the operator and waits for acknowledgement.

**Ledger format** (compact, not narrative):

```
─── Phase exit: DISCOVER → CHUNK ───
Constraints (4):
  [V1] Plane Cloud is the backend (source: operator, "we use Plane")
  [V1] Single primary operator (source: operator, "solo CTO")
  [future-pull, V1-justified: structlog avoids migration when orchestrator arrives] structlog logging
  [V1] Python for both surfaces (source: operator, locked turn 11)
  [V2-driven, deferred] note: orchestrator log shipping (V2 only — not a V1 constraint)

Tested choices (3):
  Same agent / two execution surfaces (alternatives: distinct agents, reductive Plane+skills)
  Adopt plane-sdk + thin domain layer (alternatives: pure MCP, custom httpx wrapper, fork SDK)
  JIT roadmap building (alternatives: full upfront, hybrid)

Unclassified specifics that surfaced this phase (1):
  "default-ON it-ops consultation" — needs Tech-D before phase exits

Want to address the unclassified item now, or proceed to CHUNK?
```

**The "Unclassified specifics" line is load-bearing.** If the agent's running record contains anything unclassified, that block is shown explicitly. The operator can opt to skip ("proceed anyway") but the unclassified items are recorded in the WIP and carried into RED-TEAM as automatic CRITICAL findings.

**Per-fire visibility (the "(a) layer" from the visibility decision):** for *high-stakes specifics only*, Tech-D's classification result is shown inline in the same turn rather than batched into the next ledger. Definition of "high-stakes": specifics that, if wrong, would invalidate multiple downstream chunks (named foundational technology, behavioral default that affects every operation). All other classifications happen silently and surface in the next ledger.

### Mechanism 6: Chunking — Mandatory action on self-flag

**Where:** `SKILL.md` Phase 2 (CHUNK), and `references/chunking-guidelines.md`.

**Removes:** the current "consider recursive /discover at dispatch time" suggestion in `SKILL.md` Phase 5 (DISPATCH).

**Adds:** the same chunk-overload signals (3+ open choices, vague problem statement, multi-sub-domain, red-team-flagged) are checked at **end of CHUNK phase**, not at dispatch. If 2+ signals fire, the agent presents a sub-decomposition *now*, in-line, before moving to RED-TEAM:

> "Chunk N as written has [list signals]. Here's how I'd split it into 2-3 sub-chunks: [proposal]. Want me to apply this split, or override and keep it as one chunk?"

Operator can override, but the override is recorded in the artifact as an explicit decision (a one-liner under the chunk's section: *"This chunk was flagged for split (signals: X, Y); operator overrode with reason: Z"*). No more punting to dispatch-time-maybe-recursion.

### Mechanism 7: Per-chunk audit + per-open-choice self-challenge

**Where:** `SKILL.md` Phase 2 (CHUNK), and `references/chunking-guidelines.md`.

Before declaring chunks final (at the same workflow point as Mechanism 6's signal check, but this audit runs unconditionally — whether or not Mechanism 6's signals fired), the agent reads each chunk back to itself and answers two questions, written into the WIP:

1. *"Could this chunk be split into 2-3 chunks with cleaner boundaries? If yes, propose. If no, justify."*
2. *For each open choice in this chunk: "Is this genuinely more answerable with executor context than now? If yes, why? If no, resolve it."*

**Outcomes for open choices:**

- **Survives self-challenge** → kept under "Open choices (for the executor to resolve)" with a one-liner survival justification (e.g., *"deferred because the SDK's `requests` adapter may already cover retry; verifying in-chunk is cheaper than re-litigating here"*).
- **Does not survive** → resolved in this phase. Result moves to "Tested choices" (with alternatives if any were considered) or to "Constraints" (if it turns out to be a derived constraint).

### Mechanism 8: RED-TEAM — Future-pull contamination check

**Where:** `SKILL.md` Phase 3 (RED-TEAM), and `references/anti-sycophancy.md` (Tech-C section).

Add a new finding type to the RED-TEAM checklist: **future-pull contamination.** For each chunk and each constraint, the agent asks: *"Is any design element here driven by features, scale, or systems that aren't in V1 scope?"*

**Severity guidance for this finding type:**

- **CRITICAL** — the future-pull element materially shapes the chunk's architecture (e.g., the `core/` runtime-agnostic constraint shapes how every module in `core/` is structured).
- **DISCUSS** — the future-pull element adds friction without shaping (e.g., choosing structlog now means an extra dependency for V1 with no V1-specific benefit).
- **MINOR** — small choices with future-pull rationale that don't propagate.

**Expectation:** by the time RED-TEAM runs, future-pull contamination should be rare because Mechanism 4 (Tech-D's V1/future-pull sub-classification) caught it inline. If RED-TEAM finds many instances, that is itself a signal that Tech-D's sub-classification is being skipped in DISCOVER.

### Mechanism 9: Artifact-time gates

**Where:** new file `references/artifact-gates.md`. Referenced from `SKILL.md` Phase 4 (ARTIFACT). `references/artifact-template.md` updated to require the corresponding fields.

Before writing the artifact to `docs/discovery/<slug>.md`, the agent reads the assembled artifact draft and verifies four conditions. Any failure blocks the write and returns the agent to a fixup loop.

**Gate 1: Constraints provenance.** Every line under "Confirmed constraints" has:
- A `[V1]` or `[future-pull, V1-justified: <reason>]` label.
- A source annotation in parens (operator quote / external source / inherited from chunk N).

**Gate 2: Tested choices alternatives.** Every line under "Tested choices" lists the alternatives considered and the specific rejection reason for each.

**Gate 3: Open choices survival justification.** Every entry under "Open choices (for the executor to resolve)" has the one-liner survival justification produced by Mechanism 7.

**Gate 4: No empty future-pull justifications.** A `[future-pull, V1-justified: ]` label with empty justification text fails the gate.

**Failure mode:** if the gate fails, the agent does NOT write the artifact. It announces the failures to the operator, surfaces a fixup loop (return to the relevant phase or extend the ledger), and re-runs the gate after each fixup. The artifact write is the terminal step.

**Implementation note:** the gate is an agent-driven self-validation step in the prompt, not external tooling. The agent reads the draft, runs the four checks, and reports its own conclusions. We accept the standard reliability profile of in-prompt self-validation; if real-world use shows the agent skipping gates, this design moves from "agent reads its own draft" to a more mechanical check.

## File changes

| File | Change | Sections affected |
|---|---|---|
| `skills/discover/SKILL.md` | Add Phase 0 section. Update Phase 1 (DISCOVER) for Tech-B at turn 1, per-fire visibility for high-stakes specifics, ledger discipline at phase exits. Update Phase 2 (CHUNK) for mandatory action on self-flag + per-chunk audit + per-open-choice self-challenge. Update Phase 3 (RED-TEAM) for future-pull checklist item. Update Phase 4 (ARTIFACT) to invoke the artifact gate before write. Remove the dispatch-time recursive-/discover prompt from Phase 5. | new "Phase 0", "Phase 1", "Phase 2", "Phase 3", "Phase 4", "Phase 5" |
| `skills/discover/references/anti-sycophancy.md` | Tech-B becomes 4-option; first firing at turn 1. Tech-D adds sixth trigger category (behavioral defaults / policy quotes) and the V1/future-pull sub-classification step. Tech-C section adds future-pull as an explicit check item. | Tech-B, Tech-D, Tech-C |
| `skills/discover/references/chunking-guidelines.md` | Documents the per-chunk audit + per-open-choice self-challenge. The mandatory-action-on-self-flag rule. | new sections |
| `skills/discover/references/artifact-template.md` | Adds required fields: provenance + V1/future-pull labels for constraints, alternatives for tested choices, survival justification for open choices. | template body |
| `skills/discover/references/artifact-gates.md` | **NEW.** Defines the four write-time validation checks and the fixup loop. | entire file |
| `skills/discover/references/checkpoint-protocol.md` | Adds the per-phase ledger entry shape to the WIP file format, so resume reconstruction sees the ledgers. | WIP format section |
| `skills/discover/LIMITATIONS.md` | Update to reflect new disciplines and the standard reliability profile of in-prompt self-validation for the artifact gate. Note known limits: Phase 0 may add a turn that doesn't surface a real alternative for tightly-scoped problems (operator override is the escape hatch); per-fire visibility is by definition limited to high-stakes specifics, so subtle drift in low-stakes items still relies on the per-phase ledger to catch. | additions only |

**Out of scope for this design:** full prose-tightening pass on existing phases. We strengthen imperative voice in new and modified sections only.

## Validation strategy

The design has no automated test target. Validation is empirical: re-run a discovery on a known-failed input (the PM agent problem statement, or a similarly over-specified input) and inspect:

- Did Phase 0 fire and produce a recorded premise check?
- Did Tech-B fire at turn 1 with a credible no-build frame?
- Did Tech-D's sixth-category trigger catch operator quotes that became design rules?
- Did each constraint receive V1/future-pull sub-classification?
- Did the per-phase ledger surface unclassified specifics before phase exit?
- Did chunking decompose any chunk that tripped 2+ signals?
- Did each open choice receive a survival justification?
- Did RED-TEAM produce future-pull findings (or convincingly demonstrate none existed)?
- Did the artifact gate produce the labeled output?

If any of these fail in the re-run, the corresponding mechanism's prompt needs strengthening.

## Open questions for the implementation plan

These are deferred to the implementation plan (writing-plans), not resolved here:

- Exact wording of the Phase 0 prompt (above is the shape; final phrasing is a plan-level choice).
- Whether the per-phase ledger is rendered as a code block, a table, or a custom format. The example uses a fenced text block; alternatives are viable.
- The artifact-gate failure-message format (one bulleted list of failures, or one message per failure).
- Whether `references/artifact-gates.md` cross-references the four gates by number or by name.
- Migration: the existing PM agent discovery artifact at `/tmp/pm-agent.md` will not be re-run; new disciplines apply to future discoveries only. No backfill.
- Resume interaction: when `/discover resume <slug>` is invoked, does Phase 0 re-run? Default assumption is no (the premise check is recorded in the WIP from the original session), but the implementation should state this explicitly and handle the edge case of resuming a session whose WIP predates the Phase 0 discipline.
