# Artifact-Time Gates

> Phase names (DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the Phase 4 write-time validation only.

Before writing the discovery artifact to `docs/discovery/<slug>.md`, the agent runs four self-validation gates against the assembled draft. Any failure blocks the write and returns the agent to a fixup loop.

The gates are agent-driven self-validation in the prompt — not external tooling. The agent reads its own draft, runs the four checks, and reports its conclusions to the operator before writing.

## Gate 1: Constraints provenance gate

For each line under "## Confirmed constraints" in the assembled artifact draft, verify both:

- A label is present at the start of the line: either `[V1]` or `[future-pull, V1-justified: <reason>]`.
- A source annotation is present in parens at the end of the line: `(source: <operator quote / external source / inherited from chunk N>)`.

**Fails if:** any line lacks the label or lacks the source annotation. Lines under a separate "Deferred (V2 only)" subsection are not checked here (those use the `[V2-driven, deferred]` label format and are not V1 constraints).

## Gate 2: Tested choices alternatives gate

For each line under "## Tested choices" in the assembled artifact draft, verify:

- The line lists at least one alternative considered.
- Each alternative includes a specific rejection reason.

**Fails if:** any "Tested choices" entry is missing alternatives, or lists alternatives without rejection reasons.

## Gate 3: Open choices survival justification gate

For each entry under "### Open choices (for the executor to resolve)" inside any chunk section, verify:

- A one-liner survival justification is present, in the format produced by Phase 2's per-chunk audit (Step 5b).

**Fails if:** any open choice lacks a survival justification.

## Gate 4: Empty future-pull justification gate

For each line under "## Confirmed constraints" that uses the `[future-pull, V1-justified: <reason>]` label, verify:

- The `<reason>` slot is non-empty and contains a concrete V1 impact statement (not a placeholder, not "TBD," not just "needed for V1").

**Fails if:** any future-pull label has empty or placeholder justification text.

## Failure handling

When any gate fails, the agent does NOT write the artifact. Instead:

1. **Surface the failures to the operator** as a single bulleted list, grouped by gate name. Format:

   ```text
   Artifact gate check failed. Issues:

   Constraints provenance gate (2 failures):
     - "Plane Cloud is the backend" — missing [V1]/[future-pull] label
     - "Single primary operator" — missing source annotation

   Open choices survival justification gate (1 failure):
     - Chunk 1 → "Internal module layout within core/" — missing survival justification

   Cannot write artifact until these are addressed.
   ```

2. **Surface a fixup loop:** for each failure, return to the relevant phase or extend the per-phase ledger to record the missing information. Common fixups:
   - Missing label → return to DISCOVER, run Tech-D's V1/future-pull sub-classification on the constraint, record the result.
   - Missing source annotation → ask the operator (or check the transcript) for the source.
   - Missing alternatives → return to DISCOVER, ask the operator what alternatives were considered for the choice.
   - Missing survival justification → return to CHUNK Step 5b, run the per-open-choice self-challenge for the affected chunk.
   - Empty future-pull justification → ask the operator: *"This constraint is labeled future-pull. What specifically about V1 requires it?"*

3. **Re-run all four gates after each fixup.** A single missed item won't be the only one; re-running catches cascade failures.

4. **Only after all gates pass:** proceed to write the artifact to `docs/discovery/<slug>.md`.

## Anti-patterns

- ❌ **Writing the artifact and then noting the failures.** Gates run BEFORE the write. The artifact must be gate-clean.
- ❌ **Treating a gate failure as advisory.** Gates block the write. If the operator wants to override, the override is recorded in the artifact (e.g., a "Gate overrides" section noting which gate was bypassed and why), and the gate is re-run after recording the override.
- ❌ **Lumping all failures into one generic complaint.** Group by gate name; cite the specific line that failed. The operator needs to know what to fix.
- ❌ **Skipping gates when the draft "looks fine."** The whole point of gates is to catch what looks fine but isn't. Run them every time.
