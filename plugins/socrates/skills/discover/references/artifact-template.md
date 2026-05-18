# Discovery Artifact Template

> Phase names (PREMISE CHECK, DISCOVER, RED-TEAM) and the overall flow are defined in `../SKILL.md`. This file expands the artifact format only.

The output document the skill writes after Phase 2 RED-TEAM exits. Every discovery session produces one artifact in this format. The artifact is *pure-outcome*: outcomes, parked shapes, open axes, and externally-sourced constraints. Chunking, build-vs-buy research, dispatch, and tested-shape decisions all live in `/solution`'s artifact, not here.

## Filename and location

`docs/socrates/discover/<topic-slug>.md`

`<topic-slug>` is a kebab-case identifier derived from the refined outcome statement. Examples: `team-agent-platform`, `auth-redesign`, `cart-graphql-migration`.

## Template

```markdown
# Discovery: <problem title>

**Date:** YYYY-MM-DD
**Status:** Discovery complete, ready for /solution

## Framing

<The refined outcome statement — what the operator actually wants,
after Socratic discovery. 3-5 sentences. This is NOT what the operator
originally typed; it's what emerged from the conversation. State the
*outcome*, not a proposed solution shape.>

### Original statement
> <verbatim operator input, preserved for reference>

### Key reframes
- <what changed from the original statement and why>

## Outcomes

The pressure-tested outcomes the operator wants. Each outcome is a *what*, not a *how*. Shapes (the *how*) belong in the WIP `## Parked shapes` ledger or, if externally sourced, in `## External constraints` below.

- <outcome 1 — 1-2 sentences>
- <outcome 2 — 1-2 sentences>
- ...

## External constraints

Each line MUST start with a label produced by Tech-D's V1/future-pull sub-classification, and end with a source annotation in the strict category-tagged form required by Gate 1 of `references/artifact-gates.md`:

- `[V1] <constraint text> (source: <category> — <specific citation>)`
- `[future-pull, V1-justified: <specific V1 impact>] <constraint text> (source: <category> — <specific citation>)`

where `<category>` is one of: `regulator`, `contract`, `deployed system`, `prior empirical result`, `factual measurement` (per Tech-D's verifiability rule in `../../shared/anti-sycophancy.md`). Operator-preference shapes do not appear here; they live in `## Parked shapes` below.

A `[V2-driven, deferred]` item is NOT a V1 constraint — record those under a separate "Deferred (V2 only)" subsection if any exist, not here.

## Parked shapes

Shapes surfaced during Phase 0 audit or Phase 1 Tech-D peel-back that lacked an external-source citation. Each entry carries the outcome-question the shape was parked against, so `/solution` can resolve the shape against its actual outcome:

- `"<parked shape>" — Outcome-question: <the outcome-question recorded when the shape was parked>. Parked at: turn N.`

If a parked shape was later resolved during Phase 1 (e.g., the operator provided an external source on a follow-up turn), it moves from `## Parked shapes` to `## External constraints` with the citation. The parked-shapes section captures only what is *still* unresolved at artifact write-time.

## Open axes

Outcome-level axes that remain genuinely open at the close of discovery — the operator is deliberately deferring resolution to `/solution` (or later) rather than forcing a premature commitment. Each open axis MUST include a one-liner justification for why deferral produces a better outcome than resolution-now. Format:

- `<axis> — Deferred because: <one-liner: why this is more answerable with solutioning context than now>`

This is distinct from `## Parked shapes`: parked shapes are *specifics* (named tools, patterns) awaiting outcome-question resolution; open axes are *outcome dimensions* (scale, deploy target, identity model) where the operator has decided not to commit yet.

## Red-team findings (outcomes)

Findings from Phase 2 RED-TEAM. All findings are recorded — addressed, accepted as risk, dismissed. **Dismissed findings still get recorded** with the dismissal reason. Future readers should see what was considered.

### Addressed

- [CRITICAL] <finding> — Resolution: <what was changed in outcomes / parked shapes / open axes>
- [DISCUSS] <finding> — Resolution: <operator decision>

### Accepted risks

- [MINOR] <finding> — Accepted because: <reason>

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

Key exchanges that shaped the framing, preserved for context
if someone revisits this artifact later.

- **Q:** <question asked>
  **A:** <operator answer>
  **Impact:** <how this changed the framing>

- **Q:** ...
  **A:** ...
  **Impact:** ...

</details>
```

## Section-by-section guidance

### Header

`Status` is always "Discovery complete, ready for /solution" at write time. If the artifact is later extended via sub-skill re-discovery from `/solution`, append a `## Re-discovery: <date> — <dimension>` section and update Status to note the extension.

### Framing

The refined outcome statement is *not* a paraphrase of the operator's input. It's what emerged after Socratic discovery — usually significantly different. The original statement is preserved separately for reference. Key reframes lists the deltas: what changed, what it means.

### Outcomes vs. external constraints vs. parked shapes vs. open axes

These are distinct sections with strict semantics:

- **Outcomes** = the *what* the operator wants. Pressure-tested by Phase 1 and Phase 2. No shape-language.
- **External constraints** = externally imposed OR derived from a V1 need, each carrying a `[V1]` or `[future-pull, V1-justified: <reason>]` label and a source annotation from one of the five external categories. Downstream `/solution` cannot challenge these.
- **Parked shapes** = specifics (named tools, patterns, non-functional shape framings) that surfaced without an external-source citation. Each carries the outcome-question it was parked against. `/solution` resolves these in SHAPE-DISCOVER.
- **Open axes** = outcome dimensions deliberately deferred. Each carries a survival justification explaining why deferral produces a better outcome than resolution-now.

### Red-team findings

Outcome-level findings only. Shape-level and chunk-level red-teaming live in `/solution`. If a Phase 2 finding suggested decomposition or shape-evaluation, it was recast as an outcome-level concern (e.g., "outcome X is underspecified for the parked shape it's meant to resolve") and recorded here; the decomposition itself happens in `/solution`.

### Discovery log

Collapsed by default. `/solution` doesn't strictly need it. The human who returns weeks later does — to understand why the framing landed where it did. Include only key exchanges (the ones that changed the framing), not the full transcript.

## When the template feels heavy

For very simple problems, the template can feel oversized. Don't shortcut it. The consistency is the point — operators and `/solution` always know where to find what. A simple problem just has shorter sections.

If a section truly has nothing in it, write `None` rather than deleting the section. Example:

```markdown
## Parked shapes

None — the prompt was outcome-clean; no shape-language surfaced during Phase 0 audit or Phase 1.
```
