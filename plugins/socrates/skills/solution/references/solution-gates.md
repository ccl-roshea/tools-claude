# Solution-Artifact Write-Time Gates

> Phase names (SHAPE-DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the solution-artifact write-time validation only.

Before writing the solution artifact to `docs/socrates/solution/<slug>.md`, the agent runs six self-validation gates against the assembled draft. Any failure blocks the write and returns the agent to a fixup loop. The mechanical check and qualitative check are separate concerns for each gate — passing the mechanical check (the line has the required token) is necessary but not sufficient; the qualitative check catches satisficing (the required token is present but the content behind it is hollow). Both checks must pass.

The gates are agent-driven self-validation in the prompt — not external tooling. The agent reads its own draft, runs the six checks, and reports its conclusions to the operator before writing.

G1–G4 are shape-analogs of `/discover`'s artifact gates, adapted to apply to the `## Shape decisions` section. G5 is NEW: it enforces the cross-artifact contract that no discovered outcome is silently lost between `/discover` and `/solution`. (G6, the parked-shape resolution gate, was removed when `/discover` stopped producing a parked-shapes ledger.)

## Gate 1: Shape-decision provenance gate

For each `[Constraint]` line under `## Shape decisions` in the assembled artifact draft, verify both:

- The line carries the `[Constraint]` label at the start.
- A source annotation is present in parens at the end of the line, citing one of the five external categories from Tech-D's verifiability rule (see `../../shared/anti-sycophancy.md`): **regulator** (compliance framework + control), **contract** (commercial agreement + clause), **deployed system** (system + version), **prior empirical result** (experiment / POC / incident + where recorded), or **factual measurement** (measured value + when taken). Format: `(source: <category> — <specific citation>)`.

**Mechanical check.** Iterate `## Shape decisions` lines; for each beginning with `[Constraint]`, verify the trailing parenthetical matches the pattern `(source: <one of the 5 categories> — <non-empty citation>)`. A `grep`-friendly form:

```
grep -n '^\s*-\s*\[Constraint\]' docs/socrates/solution/<slug>.md \
  | grep -v '(source: \(regulator\|contract\|deployed system\|prior empirical result\|factual measurement\) — '
```

Any line returned by the filtered-out form fails the gate.

**Qualitative check.** For each `[Constraint]` line that passes mechanical, read the citation. Per LIMITATIONS §9 (satisficing): a citation like `(source: deployed system — production)` mechanically passes but qualitatively fails — "production" is not a system + version. Reject vague citations. Acceptable: `(source: deployed system — billing-service v3.2 in us-east-1 prod)`. Unacceptable: `(source: deployed system — backend)`.

**Fails if:** any `[Constraint]` line lacks the label, lacks the source annotation, carries a category not in the 5-category list, or carries a citation that fails the qualitative specificity check.

**Failure handling.** Common fixups:
- Missing label → re-classify the line; it may belong as `[Tested-shape]` (operator preference with alternatives) or `[Open shape]` (deferred).
- Missing or vague source → return to SHAPE-DISCOVER for that shape; either obtain a specific citation from the operator (regulator + control number; contract + clause; system + version; etc.) or re-classify as `[Tested-shape]` / `[Open shape]`.
- Category not in the 5-category list (e.g., `source: best practice` or `source: industry standard`) → not external; re-classify as `[Tested-shape]` or `[Open shape]`.

## Gate 2: Tested-shape alternatives gate

For each `[Tested-shape]` line under `## Shape decisions`, verify both:

- The line carries the `[Tested-shape]` label at the start.
- The line lists ≥1 alternative with a specific rejection reason, in the format `alternatives: [<alt> rejected: <reason>]`.

**Mechanical check.** For each `[Tested-shape]` line, verify the substring `alternatives:` appears and at least one `[... rejected: ...]` bracket-pair follows. A `grep`-friendly form:

```
grep -n '^\s*-\s*\[Tested-shape\]' docs/socrates/solution/<slug>.md \
  | grep -v 'alternatives:\s*\[.*rejected:'
```

Any line returned by the filtered-out form fails the gate.

**Qualitative check.** For each `[Tested-shape]` line that passes mechanical, read the rejection reason. Per LIMITATIONS §9: a rejection like `[Redis rejected: not a fit]` mechanically passes but qualitatively fails — "not a fit" is a placeholder, not a reason. Reject vague rejections. Acceptable: `[Redis rejected: requires separate cluster; ops budget is shared single-Postgres]`. Unacceptable: `[Redis rejected: not needed]`, `[X rejected: TBD]`.

**Fails if:** any `[Tested-shape]` line lacks the label, lacks an `alternatives:` list, lists zero alternatives, or carries any alternative with a placeholder rejection reason.

**Failure handling.** Common fixups:
- Missing alternatives list → return to SHAPE-DISCOVER for that shape; Tech-D's candidate path requires enumerating ≥1 alternative. If no alternative was considered, the shape is untested — either run the test now or re-classify as `[Open shape]`.
- Placeholder rejection reasons → return to SHAPE-DISCOVER; ask the operator the specific functional gap or constraint conflict that ruled the alternative out.

## Gate 3: Open shape-decisions justification gate

For each `[Open shape]` line under `## Shape decisions`, verify:

- A one-liner survival justification is present, in the format `[Open shape] <shape text> — deferred because: <one-liner>`.

**Mechanical check.** For each `[Open shape]` line, verify the substring `deferred because:` appears with non-empty text following. A `grep`-friendly form:

```
grep -n '^\s*-\s*\[Open shape\]' docs/socrates/solution/<slug>.md \
  | grep -v 'deferred because:\s*\S'
```

Any line returned by the filtered-out form fails the gate.

**Qualitative check.** Per LIMITATIONS §9: a justification like `deferred because: TBD` or `deferred because: later` mechanically passes (text follows) but qualitatively fails — placeholder text is not a reason. Reject placeholders. Acceptable: `deferred because: the choice of frontend framework depends on whether Chunk 1's auth provider has an SDK in our target language — answerable only after Chunk 1 completes`. Unacceptable: `deferred because: in dispatch`, `deferred because: needs more thought`.

**Fails if:** any `[Open shape]` line lacks a deferral justification, or the justification is a placeholder without a concrete reason for why deferral produces a better solution than resolution-now.

**Failure handling.** Common fixups:
- Missing justification → ask the operator: *"Why are we deferring `<shape>` to the executor rather than resolving it now? One sentence."* Record the answer.
- Placeholder justification → ask the operator for the specific reason resolution-now is worse. If the operator can't articulate one, the shape should be tested (move to `[Tested-shape]`) or locked (move to `[Constraint]`), not left open.

## Gate 4: Future-pull justification gate

For each `[Constraint]` line under `## Shape decisions` that uses the `[future-pull, V1-justified: <reason>]` sub-label form (inherited from `/discover`'s constraint format when a constraint is future-driven but justifies a V1 decision), verify:

- The `<reason>` slot is non-empty and contains a concrete V1 impact statement (not a placeholder, not "TBD," not just "needed for V1").

**Mechanical check.** For each line matching the substring `[future-pull, V1-justified:`, verify the text inside the slot is non-empty and is not a placeholder list (`TBD`, `later`, `needed for V1`, `for V1`, `important`). A `grep`-friendly form:

```
grep -n '\[future-pull, V1-justified:' docs/socrates/solution/<slug>.md \
  | grep -i -E 'V1-justified:\s*(TBD|later|needed for V1|for V1|important|important for V1)\s*\]'
```

Any line returned fails the gate.

**Qualitative check.** Read the justification text. The reason must name a *specific V1 impact* — what concretely breaks or fails to ship in V1 if the constraint is not honored. Acceptable: `[future-pull, V1-justified: V1 launches to 3 enterprise tenants whose SSO contracts require multi-tenant key isolation at first login]`. Unacceptable: `[future-pull, V1-justified: enterprise customers will need it]`, `[future-pull, V1-justified: scale requirement]`.

**Fails if:** any future-pull label has empty or placeholder justification text, or the text fails to name a specific V1 impact.

**Failure handling.** Common fixups:
- Empty or placeholder text → ask the operator: *"This constraint is labeled future-pull. What specifically about V1 requires it?"* Record the answer.
- Vague justification ("for scale") → ask for the V1 concrete (which tenant, which contract, which deployed system, which measurement).

Likely vacuous when V1 trim was rigorous upstream in `/discover`. Run it anyway; the cost is two `grep`s, the benefit is catching the case where a future-pull label crept into a `[Constraint]` line during SHAPE-DISCOVER's reclassification.

## Gate 5: Outcome coverage gate (NEW)

For every outcome listed under `## Outcomes` in the upstream discovery artifact at `docs/socrates/discover/<slug>.md`, verify both:

- The outcome appears as a row in the solution artifact's `## Discovery → Solution mapping` table.
- The row names ≥1 chunk in its "Addressed by chunk(s)" column.

This is the cross-artifact contract that no outcome from `/discover` is silently lost in `/solution`. /discover's outcomes are the *input set* for /solution's chunks; every input must trace forward to ≥1 chunk that addresses it.

**Mechanical check.** Enumerate discovery.md outcomes, then verify each appears in the mapping table:

```
# 1. Extract discovery outcomes (each bullet under ## Outcomes).
awk '/^## Outcomes/,/^## /{if (/^- /) print}' \
  docs/socrates/discover/<slug>.md > /tmp/discover-outcomes.txt

# 2. Extract mapping-table outcome column (column 1 of each table row).
awk '/^## Discovery → Solution mapping/,/^## /{
  if (/^\|/ && !/^\|---/ && !/^\| Discovered outcome/) print
}' docs/socrates/solution/<slug>.md > /tmp/mapping-rows.txt

# 3. For each discovery outcome, verify presence in mapping-rows.txt
#    (substring or hash-match by key noun-phrase).
# 4. For each mapping row, verify column 2 ("Addressed by chunk(s)")
#    names ≥1 chunk (non-empty, not "TBD").
```

**Qualitative check.** Per LIMITATIONS §9: a mapping row that names a chunk by number but the named chunk's `Problem statement` doesn't mention the outcome qualitatively fails — the mapping is bookkeeping, not coverage. For each mapping row, read the named chunk's `Problem statement`; the outcome (or a clear referent) must appear. Acceptable: outcome `"users can sign in with company SSO"` mapped to Chunk 1 whose problem statement reads *"Implement SSO sign-in covering OIDC and SAML so users can sign in with company SSO."* Unacceptable: same outcome mapped to Chunk 1 whose problem statement reads *"Set up the auth infrastructure."*

**Fails if:** any discovery outcome lacks a row in the mapping table, any mapping row's chunk column is empty / "TBD", or any mapped chunk's problem statement doesn't qualitatively name the outcome.

**Failure handling.** Common fixups:
- Missing row → check whether the outcome was lost during SHAPE-DISCOVER or CHUNK. If lost: return to the relevant phase and add a shape decision + chunk that addresses it. If intentionally dropped: not allowed — outcomes from /discover are not droppable in /solution. If the outcome should not exist: invoke sub-skill /discover (per Phase 0 / Phase 2) to re-discover and either retract the outcome upstream or commit to it downstream.
- Mapping row with no chunk → assign the outcome to ≥1 chunk; if no chunk fits, the chunks are incomplete (return to CHUNK).
- Qualitative failure (mapping bookkeeping but chunk doesn't name outcome) → edit the chunk's problem statement to name the outcome verbatim, or split the chunk if it's serving an outcome implicitly that deserves explicit scope.

## Failure handling (cross-gate)

When any gate fails, the agent does NOT write the artifact. Instead:

1. **Surface the failures to the operator** as a single bulleted list, grouped by gate name. Format:

   ```text
   Solution artifact gate check failed. Issues:

   Shape-decision provenance gate (G1) — 1 failure:
     - "[Constraint] use Plane Cloud" — missing source annotation

   Tested-shape alternatives gate (G2) — 2 failures:
     - "[Tested-shape] FastAPI for the backend" — no alternatives listed
     - "[Tested-shape] PostgreSQL for storage — alternatives: [Redis rejected: not needed]" — placeholder rejection reason

   Outcome coverage gate (G5) — 1 failure:
     - Discovery outcome "users can export their workspace as JSON" — no row in mapping table

   Cannot write solution artifact until these are addressed.
   ```

2. **Surface a fixup loop:** for each failure, return to the relevant phase or extend the per-phase ledger to record the missing information. Common loops:
   - G1/G2/G3/G4 failures usually return to **SHAPE-DISCOVER** (Phase 0). The fix is to re-classify the shape, obtain a citation, enumerate alternatives, or articulate a deferral reason — all SHAPE-DISCOVER work.
   - G5 failures may return to **SHAPE-DISCOVER** (a shape was missed), **CHUNK** (a chunk was missed or scoped too narrowly), or trigger **sub-skill /discover** invocation (the outcome itself should be retracted upstream).

3. **Re-run all five gates after each fixup.** A single missed item is rarely the only one; re-running catches cascade failures (e.g., a fix to G1 that re-classifies a `[Constraint]` to `[Tested-shape]` will then need to pass G2's alternative-required check).

4. **Only after all five gates pass:** proceed to write the artifact to `docs/socrates/solution/<slug>.md`.

## Anti-patterns

- ❌ **Writing the artifact and then noting the failures.** Gates run BEFORE the write. The artifact must be gate-clean.
- ❌ **Treating a gate failure as advisory.** Gates block the write. If the operator wants to override, the override is recorded in the artifact (e.g., a "Gate overrides" section noting which gate was bypassed and why), and the gate is re-run after recording the override.
- ❌ **Lumping all failures into one generic complaint.** Group by gate name; cite the specific line that failed. The operator needs to know what to fix.
- ❌ **Passing the mechanical check and skipping the qualitative check.** The mechanical check catches missing tokens; the qualitative check catches satisficing (token present, content hollow). Both fire per gate. Per LIMITATIONS §9: the satisficing failure mode is exactly what the qualitative check exists to catch.
- ❌ **Stopping at G1 and skipping the rest.** Run all five gates every iteration. A fix to G1 can break G2; a fix to G5 can reveal a missing row.
- ❌ **Treating G5 as soft / informational.** G5 is a hard gate with mechanical and qualitative checks. The whole point of the /discover → /solution split is that the cross-artifact contract is enforced — G5 is the enforcement.
- ❌ **Editing discovery.md to make G5 pass.** Discovery is upstream and frozen by the time /solution runs. If discovery genuinely needs updating, invoke sub-skill /discover (per Phase 0 / Phase 2) — do not silently edit the upstream artifact to make a downstream gate pass.
