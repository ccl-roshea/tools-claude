# Discovery Artifact Template

> Phase names (DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the artifact format only.

The output document the skill writes in Phase 4. Every discovery session produces one artifact in this format, regardless of chunk count. Single-chunk problems get the same template — sections just stay short.

## Filename and location

`docs/socrates/discover/<topic-slug>.md`

`<topic-slug>` is a kebab-case identifier derived from the refined problem statement. Examples: `team-agent-platform`, `auth-redesign`, `cart-graphql-migration`.

## Template

```markdown
# Discovery: <problem title>

**Date:** YYYY-MM-DD
**Status:** Discovery complete, ready for execution
**Chunks:** N (or "single chunk — no decomposition needed")

## Execution order

1. Chunk 1: <name> (no dependencies)
2. Chunk 2: <name> (depends on: Chunk 1)
3. Chunk 3: <name> (depends on: Chunk 1)
   Note: Chunks 2 and 3 can run in parallel after Chunk 1.

## Framing

<The refined problem statement — what the user actually wants,
after Socratic discovery. 3-5 sentences. This is NOT what the user
originally typed; it's what emerged from the conversation.>

### Original statement
> <verbatim user input, preserved for reference>

### Key reframes
- <what changed from the original statement and why>

## Confirmed constraints

Each line MUST start with a label produced by Tech-D's V1/future-pull sub-classification, and end with a source annotation:

- `[V1] <constraint text> (source: <operator quote / external source / inherited from chunk N>)`
- `[future-pull, V1-justified: <specific V1 impact>] <constraint text> (source: ...)`

A `[V2-driven, deferred]` item is NOT a V1 constraint — record those under a separate "Deferred (V2 only)" subsection if any exist, not here.

## Tested choices

Each line MUST list the alternatives that were considered and the specific rejection reason for each:

- `<choice> (alternatives: <alt 1> [rejected: <reason>], <alt 2> [rejected: <reason>])`

A "Tested choices" entry without alternatives recorded fails the artifact gate.

## Chunk 1: <name>

### Problem statement

<2-5 sentences, self-contained, paste-ready for /superpowers.
Includes enough context that an executor in a fresh session
can understand the problem without reading the rest of the artifact.>

### Constraints (inherited + chunk-specific)

Inherited constraints carry their `[V1]` / `[future-pull, V1-justified: ...]` labels and source annotations verbatim from the top-level "Confirmed constraints" section. Chunk-specific constraints follow the same labeling rule.

- `[V1] <constraint text> (source: ...)`
- `[future-pull, V1-justified: <reason>] <constraint text> (source: ...)`

### Open choices (for the executor to resolve)

Each open choice MUST include a one-liner survival justification produced during the per-chunk audit (Phase 2 Step 5b). Format:

- `<choice> — Deferred because: <one-liner: why this is more answerable with executor context than now>`

### Dependencies

None | Depends on: Chunk N (specifically: <what decision is needed and why>)

### Recommended executor

/superpowers (or other, with rationale)

## Chunk 2: <name>
...

## Red-team findings

### Addressed

- [CRITICAL] <finding> — Resolution: <what was changed>
- [DISCUSS] <finding> — Resolution: <operator decision>

### Accepted risks

- [MINOR] <finding> — Accepted because: <reason>

## Research outcomes (build-vs-buy)

### Overall problem

- **Searched for:** <query>
- **Candidates evaluated:** <tool A>, <tool B>, <tool C>
- **Outcome:** <Adopt fully | Adopt partially | Reject all | Inspire>
- **Effect on chunks:** <none | chunks N reduced/eliminated | new integration chunk added>

### Chunk N

- **Searched for:** <query>
- **Candidates evaluated:**
  - **<Tool name>** — Adopt fully / Adopt partially / Reject / Inspire
    - URL: <link>
    - Functionality match: <%>
    - Cost: <free / paid / pricing>
    - License: <license>
    - Maintenance: <active / stable / stale>
    - Lock-in: <low / medium / high>
    - Integration burden: <low / medium / high>
    - Reason: <specific>
- **Outcome:** <chunk modified to ... | chunk eliminated | chunk unchanged, build custom>

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

Key exchanges that shaped the framing, preserved for context
if someone revisits this artifact later.

- **Q:** <question asked>
  **A:** <user answer>
  **Impact:** <how this changed the framing>

- **Q:** ...
  **A:** ...
  **Impact:** ...

</details>
```

## Section-by-section guidance

### Header

`Status` is always "Discovery complete, ready for execution" at write time. If the artifact is ever updated post-dispatch (e.g., a chunk's /superpowers session revealed the chunking was wrong), update Status to reflect that and add a "Revisions" section.

### Execution order

Computed via topological sort. Always show:
1. Numbered list in execution order
2. Dependency annotation per item
3. Parallelism notes ("Chunks 2 and 3 can run in parallel after Chunk 1")

### Framing

The refined statement is *not* a paraphrase of the user's input. It's what emerged after Socratic discovery — usually significantly different. The original statement is preserved separately for reference. Key reframes lists the deltas: what changed, what it means.

### Confirmed constraints vs. tested choices

These are distinct sections, not interchangeable.

- **Constraints** = externally imposed OR derived from a V1 need. Each carries a `[V1]` or `[future-pull, V1-justified: <reason>]` label and a source annotation. Downstream executors cannot challenge these. The V1/future-pull label is mandatory; an unlabeled constraint blocks the artifact gate.
- **Tested choices** = surfaced as choices, alternatives explored, this one selected. Each line records the alternatives considered. Downstream executors should NOT re-open these — the alternatives were already considered.
- **Open choices** (per-chunk) = decisions deferred to the executor. Each carries a survival justification explaining why deferral produces a better outcome than resolution-now.

### Chunks

Each chunk's **problem statement** must be self-contained. Test: if you copy that section alone into a fresh /superpowers session, would the executor have enough to design well? If not, expand it.

The **dependencies** section is explicit — not just "Depends on Chunk 1," but "Depends on Chunk 1 (specifically: API contract from Chunk 1's communication design)." The executor needs to know *what* to look for in upstream output.

### Red-team findings

All findings are recorded — addressed, accepted as risk, dismissed. **Dismissed findings still get recorded** with the dismissal reason. Future readers should see what was considered.

### Research outcomes

This section holds the build-vs-buy evaluation. Even rejected candidates are recorded with reasons (so future readers don't re-evaluate the same options). If no research was done (e.g., the problem is so domain-specific that no external tools apply), record that fact: "No research performed because [reason]."

### Discovery log

Collapsed by default. The executor doesn't need it. The human who returns weeks later does — to understand why the framing landed where it did. Include only key exchanges (the ones that changed the framing), not the full transcript.

## When the template feels heavy

For very simple problems, the template can feel oversized. Don't shortcut it. The consistency is the point — operators and downstream executors always know where to find what. A simple problem just has shorter sections.

If a section truly has nothing in it, write `None` rather than deleting the section. Example:

```markdown
## Tested choices

None — no choices required testing in this discovery; the problem was tightly constrained from the start.
```
