# Solution Artifact Template

> Phase names (SHAPE-DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the solution-artifact format only.

The output document the skill writes after Phase 4 ARTIFACT's write-time gates pass. Every solution session produces one artifact in this format. The artifact is *shape-and-chunk*: shape decisions (constraints / tested-shapes / open shapes), chunks (with dependencies and recommended executors), shape-level red-team findings, build-vs-buy research outcomes, and an explicit mapping from /discover's outcomes to the chunks that address them. Outcome discovery, outcome-level pressure-testing via Socratic dialogue, and the validated problem all live upstream in `/discover`'s discovery artifact, not here.

## Filename and location

`docs/socrates/solution/<topic-slug>.md`

`<topic-slug>` is the same kebab-case identifier used in the upstream discovery artifact at `docs/socrates/discover/<topic-slug>.md`. Examples: `team-agent-platform`, `auth-redesign`, `cart-graphql-migration`. The solution artifact and the discovery artifact share a slug 1:1.

## Template

```markdown
# Solution: <problem title>

**Date:** YYYY-MM-DD
**Status:** Solution complete, ready for /superpowers dispatch
**Discovery artifact:** docs/socrates/discover/<slug>.md
**Chunks:** N

## Execution order

1. Chunk 1: <name>
2. Chunks 2 + 3 (parallelizable — same upstream dependencies, no shared draft state)
3. Chunk 4: <name>
...

Notes on parallelism: <free-form one-paragraph note on which chunks
the artifact records as parallelizable, and why others are forced
sequential (data ownership, upstream-decision dependency, operator
attention bandwidth). MVP dispatch is sequential regardless; the
parallelism record is for downstream when parallel dispatch ships.>

## Framing

<Recap of the refined problem from /discover. 3-5 sentences. This is
the outcome statement from the discovery artifact, possibly tightened
by any `## Re-discovery: <date> — <dimension>` sections appended by
sub-skill /discover invocations during /solution's SHAPE-DISCOVER or
RED-TEAM phases. Do NOT re-state outcomes here — those live in
discovery.md; this section names the framing the chunks are written
against.>

### Re-discoveries (if any)

- `<dimension>` — Outcome answer: <1-3 sentence answer>. Fired from: `<which /solution phase surfaced the gap>`. Appended to discovery.md as `## Re-discovery: YYYY-MM-DD — <dim>`.

## Shape decisions

Each line MUST start with one of three labels (per Phase 4 gates G1–G3 in `references/solution-gates.md`):

- `[Constraint] <shape text> (source: <category> — <specific citation>)`
- `[Tested-shape] <shape text> — alternatives: [<alt 1> rejected: <reason>] [<alt 2> rejected: <reason>]`
- `[Open shape] <shape text> — deferred because: <one-liner: why deferral produces a better solution than resolution-now>`

where `<category>` for `[Constraint]` is one of: `regulator`, `contract`, `deployed system`, `prior empirical result`, `factual measurement` (per Tech-D's verifiability rule in `../../shared/anti-sycophancy.md`).

`[Constraint]` lines carry forward unchanged from /discover's `## External constraints` (the upstream Tech-D lock-ins) plus any *new* constraints SHAPE-DISCOVER locked in when re-classifying a parked shape that turned out to have an external source. `[Tested-shape]` lines record Phase 0 SHAPE-DISCOVER's Tech-D *candidate path* outcomes — shapes the operator picked over enumerated alternatives. `[Open shape]` lines record shapes deliberately deferred to the executor with a survival justification.

## Chunks

### Chunk N: <name>

**Problem statement.** <1-3 sentences scoping this chunk's work. State the outcome(s) from discovery.md this chunk addresses — name them verbatim from discovery.md's `## Outcomes` section so Phase 4 G5 (outcome coverage) can check by string match.>

**Inherited constraints.** <The `[Constraint]` lines from `## Shape decisions` above that apply to this chunk. Repeated verbatim, not paraphrased — the executor sees them as the chunk's locked-in context.>

**Open choices in this chunk.** <The `[Open shape]` lines from `## Shape decisions` above that the executor will resolve. Each carries its survival justification.>

**Dependencies.** <Other chunks (by name and number) this chunk depends on for upstream decisions. None = independent. If a parallel pair: name the pair and the shared upstream.>

**Recommended executor.** <Usually `/superpowers`; may be `/superpowers:executing-plans` if a plan exists, or another executor if the chunk is non-code (e.g., research-only).>

**Notes.** <Optional: pointers to inspire candidates from research, links to relevant prior art, anything the executor benefits from seeing.>

(repeat per chunk)

## Red-team findings (shape-level)

Findings from Phase 2 RED-TEAM. All findings are recorded — addressed, accepted as risk, dismissed. **Dismissed findings still get recorded** with the dismissal reason. Future readers should see what was considered. Outcome-level findings (if any surfaced during /solution's red-team) were handled via sub-skill /discover invocation and appear under `## Re-discoveries` in the Framing section; they do NOT appear here.

### Addressed

- [CRITICAL] <finding> — Resolution: <what was changed in shape decisions / chunks / dependencies>
- [DISCUSS] <finding> — Resolution: <operator decision>

### Accepted risks

- [MINOR] <finding> — Accepted because: <reason>

### Dismissed

- [DISCUSS] <finding> — Dismissed because: <specific reason>

## Research outcomes (build-vs-buy)

From Phase 3 RESEARCH. Two scopes: per-chunk evaluations and a whole-problem evaluation.

### Per chunk

For each chunk that ran a build-vs-buy search (not every chunk requires research; trivial chunks may skip), record candidates evaluated against the 6 criteria from `references/research-protocol.md` (functionality match %, license, cost, maintenance, lock-in, integration burden) and a classification (Adopt fully / Adopt partially / Reject / Inspire).

- **Chunk N: <name>**
  - **<Tool name>** — Adopt fully / Adopt partially / Reject / Inspire
    - URL: <link>
    - Functionality match: <%>
    - Cost: <free / paid / pricing>
    - License: <license + any concerns>
    - Maintenance: <active / stable / stale>
    - Lock-in: <low / medium / high>
    - Integration burden: <low / medium / high>
    - Reason for classification: <specific>
  - **Outcome:** <chunk modified to X | chunk eliminated | chunk replaced with integration chunk | chunk unchanged, build custom (reverse sunk-cost check fired: result)>

### Whole problem

Did any single tool credibly satisfy the *whole* outcome set (not just one chunk)? If so, the chunk structure may collapse.

- Candidates evaluated: <list>
- Outcome: <chunk structure unchanged | chunks collapsed into single integration chunk | partial collapse: <which chunks merged>>

## Discovery → Solution mapping

| Discovered outcome (verbatim from discovery.md `## Outcomes`) | Addressed by chunk(s) |
|---|---|
| <Outcome 1> | Chunk 1, Chunk 2 |
| <Outcome 2> | Chunk 3 |
| ... | ... |

Phase 4 G5 (outcome coverage) checks every row of this table has ≥1 chunk and every outcome from discovery.md `## Outcomes` appears as a row.

## Discovery log (collapsed)

<details>
<summary>Solution Q&A highlights</summary>

Key /solution-side exchanges that shaped the shape decisions, chunk
structure, and research outcomes, preserved for context if someone
revisits this artifact later. Outcome-discovery Q&A lives in
discovery.md; this log captures only the /solution-side conversation.

- **Q:** <question asked>
  **A:** <operator answer>
  **Impact:** <how this changed a shape decision / chunk / research outcome>

- **Q:** ...
  **A:** ...
  **Impact:** ...

</details>
```

## Section-by-section guidance

### Header

`Status` is "Solution complete, ready for /superpowers dispatch" at write time. During Phase 5 DISPATCH, the agent updates Status to "Dispatch in progress — Chunk M of N" and finally to "Dispatch complete" when every chunk has either been dispatched-and-completed or explicitly skipped with operator-recorded reason. `Chunks: N` is the count after research (which may have collapsed or eliminated chunks); it is the chunk count the operator will see in Phase 5 DISPATCH.

`Discovery artifact:` is a hard link, not a paraphrase. The discovery artifact is the source of truth for outcomes and the input set for parked-shapes resolution.

### Execution order

Lists chunks in topological order per `../../shared/chunking-guidelines.md`. Pairs of chunks that are parallelizable share a list position (e.g., "2. Chunks 2 + 3"). MVP dispatch runs sequentially regardless; the parallel grouping is recorded for downstream when parallel dispatch ships.

### Framing

The framing recap is a tightening, not a re-statement. If discovery.md has 5 outcomes spanning a problem, the framing names the problem; it does not repeat the outcomes. Outcomes belong in the Discovery → Solution mapping table.

If sub-skill /discover invocations fired during /solution, list them under `### Re-discoveries`. Each re-discovery is also appended to discovery.md as `## Re-discovery: YYYY-MM-DD — <dim>`; the line here is a cross-reference, not the answer itself.

### Shape decisions

Three label types correspond to the three SHAPE-DISCOVER outcomes plus carried-forward constraints:

- **[Constraint]** = externally sourced. Tech-D verifiability rule produced a citation. Inherited from discovery.md or locked in during SHAPE-DISCOVER when a parked shape turned out to have a source. The 5-category list (regulator / contract / deployed system / prior empirical result / factual measurement) is enforced by Phase 4 G1.
- **[Tested-shape]** = operator picked this shape over enumerated alternatives during Phase 0 SHAPE-DISCOVER's Tech-D candidate path. ≥1 alternative is recorded with a specific rejection reason. Enforced by G2.
- **[Open shape]** = deliberately deferred to the executor. Carries a one-liner survival justification (`deferred because: <reason>`). Enforced by G3.

A shape that SHAPE-DISCOVER classified as **default-to-test** and the test resolved to "no shape needed" does NOT appear under `## Shape decisions` — record the outcome in the WIP ledger under the relevant shape entry with `resolution: dropped: <reason>`.

### Chunks

Each chunk is independently dispatchable to /superpowers (or another executor). The four required subsections are `Problem statement`, `Inherited constraints`, `Open choices in this chunk`, `Dependencies`. `Recommended executor` and `Notes` round it out.

**Outcome naming for G5.** The `Problem statement` MUST name the discovered outcome(s) this chunk addresses using language traceable to discovery.md `## Outcomes`. Phase 4 G5 enumerates discovery.md's outcomes and checks each appears in ≥1 chunk's problem statement. Paraphrase-only ("auth stuff" for "users can sign in with their company SSO") risks G5 failure.

**Inherited constraints repeat verbatim.** The executor sees the chunk's prompt; it does not re-read the solution artifact's `## Shape decisions` section. Each chunk repeats the `[Constraint]` lines it inherits. Duplication is intentional.

### Red-team findings

Shape-level findings only. Chunk-structure findings (scope creep, dependency gaps) count as shape-level for this section. Outcome-level findings surfaced during /solution's RED-TEAM are handled by sub-skill /discover invocation and recorded under Framing → Re-discoveries; they do NOT appear in this section.

### Research outcomes

Per-chunk research records every candidate evaluated, not just the winner. Even if Chunk 2 is unchanged ("build custom"), the candidates that lost (and why) belong in the record so future readers don't re-ask. The reverse sunk-cost check (per `references/research-protocol.md`) records its result inline: if it fired and the operator stuck with build-custom despite a credible adopt-candidate, the check's specific rejection reasons (functional gaps or constraint conflicts) appear under `Reason for classification`.

Whole-problem research is the "did the whole solution collapse" check. If a single tool credibly satisfied the whole outcome set and the operator adopted it, the artifact records that — the chunk structure may shrink to a single integration chunk.

### Discovery → Solution mapping

The most load-bearing table in the artifact for downstream verification. Phase 4 G5 walks discovery.md's `## Outcomes` section line-by-line and checks each outcome appears as a row here AND that the row names ≥1 chunk. Missing rows OR rows with no chunk = G5 failure.

The mapping does NOT require 1:1 — an outcome can be served by multiple chunks; a chunk can serve multiple outcomes. The bipartite coverage is what matters.

### Discovery log

Collapsed by default. The /solution-side Q&A only — outcome-discovery Q&A lives in discovery.md's Discovery log. Include the exchanges that changed a shape decision, chunk boundary, or research outcome. Not the full transcript.

## When the template feels heavy

For solution sessions with few parked shapes and no research surprises, the template can feel oversized. Don't shortcut it. The consistency is the point — operators, /superpowers (during dispatch), and future readers always know where to find what. A simple solution just has shorter sections.

If a section truly has nothing in it, write `None` rather than deleting the section. Example:

```markdown
## Red-team findings (shape-level)

None — Phase 2 RED-TEAM surfaced zero findings above MINOR severity. (Possible smell: re-check that the red-team mode-shift fired and the operator was given the option to push back. If yes, accept the empty section.)
```

The `None` annotation should usually carry a one-liner smell check — empty sections often mean the upstream phase skipped a step.
