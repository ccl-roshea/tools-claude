# Artifact-Time Gates

> Phase names (PREMISE CHECK, DISCOVER, RED-TEAM) and the overall flow are defined in `../SKILL.md`. This file expands the discovery-artifact write-time validation only.

Before writing the discovery artifact to `docs/socrates/discover/<slug>.md`, the agent runs three self-validation gates against the assembled draft. Any failure blocks the write and returns the agent to a fixup loop.

The gates are agent-driven self-validation in the prompt — not external tooling. The agent reads its own draft, runs the three checks, and reports its conclusions to the operator before writing.

Tested-shape alternatives are NOT gated here; that concern lives in `/solution`'s `solution-gates.md` because "tested shapes" are recorded in the solution artifact, not the discovery artifact.

## Gate 1: External constraints provenance gate

For each line under "## External constraints" in the assembled artifact draft, verify both:

- A label is present at the start of the line: either `[V1]` or `[future-pull, V1-justified: <reason>]`.
- A source annotation is present in parens at the end of the line. The source MUST cite one of the five external categories from Tech-D's verifiability rule (see `../../shared/anti-sycophancy.md`): **regulator** (compliance framework + control), **contract** (commercial agreement + clause), **deployed system** (system + version), **prior empirical result** (experiment / POC / incident + where recorded), or **factual measurement** (measured value + when taken). Format: `(source: <category> — <specific citation>)`.

**Fails if:** any line lacks the label, lacks the source annotation, or carries a source that does not cite one of the five external categories (regulator, contract, deployed system, prior empirical result, factual measurement). A bare operator quote without an external category tag fails the gate — that input belongs in the `## Parked shapes` section, not in external constraints. Lines under a separate "Deferred (V2 only)" subsection are not checked here (those use the `[V2-driven, deferred]` label format and are not V1 constraints).

## Gate 3: Open axes justification gate

For each entry under "## Open axes" in the assembled artifact draft, verify:

- A one-liner survival justification is present, in the format `<axis> — Deferred because: <one-liner>`.

**Fails if:** any open axis lacks a deferral justification, or the justification is a placeholder ("TBD," "later," "in /solution") without a concrete reason for why deferral produces a better outcome than resolution-now.

(Gate numbering preserves the historical G1/G3/G4 sequence; the historical middle gate — which checked tested shapes for recorded alternatives — moved to `/solution`'s gates because tested shapes are a solution-artifact concern.)

## Gate 4: Empty future-pull justification gate

For each line under "## External constraints" that uses the `[future-pull, V1-justified: <reason>]` label, verify:

- The `<reason>` slot is non-empty and contains a concrete V1 impact statement (not a placeholder, not "TBD," not just "needed for V1").

**Fails if:** any future-pull label has empty or placeholder justification text.

## Failure handling

When any gate fails, the agent does NOT write the artifact. Instead:

1. **Surface the failures to the operator** as a single bulleted list, grouped by gate name. Format:

   ```text
   Artifact gate check failed. Issues:

   External constraints provenance gate (2 failures):
     - "Plane Cloud is the backend" — missing [V1]/[future-pull] label
     - "Single primary operator" — missing source annotation

   Open axes justification gate (1 failure):
     - "Deploy target" — missing deferral justification

   Cannot write artifact until these are addressed.
   ```

2. **Surface a fixup loop:** for each failure, return to the relevant phase or extend the per-phase ledger to record the missing information. Common fixups:
   - Missing label → return to DISCOVER, run Tech-D's V1/future-pull sub-classification on the constraint, record the result.
   - Missing source annotation → ask the operator (or check the transcript) for the source. If no external source exists, the item is not a constraint — move it to `## Parked shapes` with an outcome-question.
   - Missing open-axis justification → ask the operator: *"Why are we deferring [axis] to /solution rather than answering it now? One sentence."*
   - Empty future-pull justification → ask the operator: *"This constraint is labeled future-pull. What specifically about V1 requires it?"*

3. **Re-run all three gates after each fixup.** A single missed item won't be the only one; re-running catches cascade failures.

4. **Only after all gates pass:** proceed to write the artifact to `docs/socrates/discover/<slug>.md`.

## Anti-patterns

- ❌ **Writing the artifact and then noting the failures.** Gates run BEFORE the write. The artifact must be gate-clean.
- ❌ **Treating a gate failure as advisory.** Gates block the write. If the operator wants to override, the override is recorded in the artifact (e.g., a "Gate overrides" section noting which gate was bypassed and why), and the gate is re-run after recording the override.
- ❌ **Lumping all failures into one generic complaint.** Group by gate name; cite the specific line that failed. The operator needs to know what to fix.
- ❌ **Skipping gates when the draft "looks fine."** The whole point of gates is to catch what looks fine but isn't. Run them every time.
- ❌ **Gating tested-shape alternatives here.** That gate (historical G2) moved to `/solution`'s `solution-gates.md`. The discovery artifact has no "tested shapes" section to gate — shapes are either parked (Tech-D peel-back) or locked in as external constraints (Tech-D verifiability), never "tested" at the /discover level.
