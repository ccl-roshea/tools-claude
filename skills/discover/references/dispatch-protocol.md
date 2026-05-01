# Dispatch Protocol

> Phase names (DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the dispatch protocol only.

Phase 5 of the skill. After the artifact is committed, sequentially dispatch each chunk to /superpowers in dependency order.

## Sequential dispatch loop

```
For each chunk in execution order:
  0. Assess chunk complexity for recursion (see "Chunk-complexity assessment" below)
       — if 2+ signals fire, propose recursive /discover; operator decides
  1. Compose the dispatch prompt (see "Composing the prompt" below)
  2. Launch via Agent tool (foreground, main workspace)
  3. Operator interacts with /superpowers normally
  4. On completion: extract decisions, record as upstream context for downstream chunks
  5. Update artifact with link to chunk's plan output
  6. Move to next chunk
```

For MVP, even chunks that *could* run in parallel run sequentially — the operator can only interact with one /superpowers session at a time. The artifact records parallelism information for when parallel dispatch is built (deferred per memo §6).

## Chunk-complexity assessment (step 0)

Before dispatching each chunk, check whether it's well-scoped for /superpowers or whether it would benefit from its own /discover pass first. The parent /discover pressure-tested the *root* framing, but chunks can still be too large or multi-decision for a single /superpowers session.

### Signals

For each chunk, count how many of these fire:

1. **Open-choice density.** Does the "Open choices" list have 3 or more independent items?
2. **Lingering vagueness.** Does the problem statement still feel vague or multi-faceted when read aloud — would a fresh /superpowers session still need clarification on basic intent?
3. **Sub-domain spread.** Does the chunk span multiple sub-domains (e.g., "Portal" = UX + auth + APIs)? Distinct sub-domains often deserve distinct framings.
4. **Red-team flag.** Did Phase 3's red-team mark this chunk as scope-creep-prone or with unresolved untested specifics?

### Decision rule

- **0–1 signals fire:** proceed directly to dispatch. Do *not* surface a "should we run /discover?" prompt — that's operator fatigue. The point is to flag chunks that genuinely need it, not to ask about every chunk.
- **2+ signals fire:** propose recursion to the operator:

  > "Chunk N (<name>) looks like it might still need its own discovery pass before /superpowers can plan it well. The signals: [cite which fired and why]. Want to run /discover on this chunk first, or proceed straight to /superpowers?"

### Operator response handling

- **Operator chooses /discover.** Recursively invoke the /discover skill on the chunk's problem statement, inheriting the parent's confirmed constraints. The output is a sub-discovery artifact at `docs/discovery/<parent-slug>/<chunk-slug>.md`. Then dispatch the sub-chunks via the same Phase 5 logic (which itself includes step 0 — recursion can compound, operator-driven).
- **Operator declines /discover.** Proceed straight to dispatch with the chunk as-is. Record the operator's response in the artifact's "Phase 5 — Chunk-complexity assessment" section.
- **Operator says "ask me later" or similar:** treat as decline for now; revisit if downstream chunks reveal the chunking was wrong.

### Honesty about borderline calls

If you assess 2 signals but think the recursion is unnecessary anyway (e.g., the sub-domains integrate within a known pattern, the choices are well-bounded with clear criteria), say so in your proposal:

> "Chunk N fires 2 signals (1 and 3). Honest take: borderline — [reason]. Recommend proceed with /superpowers unless you see specific framing risk I'm missing."

Don't pretend every borderline case is a real recursion candidate. The operator's time is limited.

### Anti-patterns

- ❌ **Surfacing the prompt on every chunk.** That's not assessment, that's outsourcing the decision.
- ❌ **Auto-recursing without operator approval.** Recursion compounds — uncontrolled depth blows the token budget and operator attention.
- ❌ **Skipping the assessment because "the parent already discovered."** The parent discovery pressure-tested the root framing; chunks can still be too large.
- ❌ **Treating 2 signals as automatic recursion.** 2 is a *threshold for surfacing*, not for recursing.

## Composing the dispatch prompt

The dispatch prompt fed to /superpowers consists of four sections:

### 1. Chunk problem statement (verbatim)

Copy from the artifact's chunk section. This is paste-ready by design.

### 2. Constraints (inherited + chunk-specific)

Combine:
- All "Confirmed constraints" from the artifact's top-level section (these apply to every chunk)
- All chunk-specific constraints from this chunk's section

Format as a bullet list under a "## Constraints (do not re-open)" heading. The "do not re-open" framing tells /superpowers these are settled.

### 3. Open choices

Copy from the chunk's "Open choices (for the executor to resolve)" section. These are the things /superpowers should help the operator decide.

### 4. Upstream decisions (if any)

Only included if this chunk has dependencies. Extracted from completed dependency chunks' /superpowers output (see "Extracting decisions" below). Format:

```markdown
## Upstream decisions (from completed chunks)

### From Chunk M: <name>
- Decided: <decision>
- Reason: <why>
- Relevant detail for this chunk: <API contract, schema, protocol, etc.>
```

## Launching via Agent tool

Use the Agent tool with these parameters:

- `subagent_type`: `general-purpose` (default — works for most cases)
- `description`: short summary, e.g., `"Plan chunk N: <chunk name>"`
- `prompt`: the composed dispatch prompt above
- `run_in_background`: false (foreground — operator needs to interact)

**Critical:** the agent runs in the *main workspace*, not a worktree. /superpowers writes design docs and plans; those need to be visible in the operator's working tree. If the spec mentioned worktrees, that was for /superpowers' own internal use, not for our wrapper.

The agent's job is just to invoke /superpowers:brainstorming with the prompt. It's not generating code itself — it's launching a sub-skill flow that the operator drives.

## Extracting decisions from /superpowers output

After a chunk's /superpowers session completes, /superpowers will have produced:
- A design doc at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- An implementation plan at `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`

The skill reads these and extracts decisions relevant to downstream chunks. Specifically:
- Architecture choices (e.g., "decided: message bus over direct calls")
- Tech stack picks
- API contracts (especially formats, endpoints, schemas)
- Data models that downstream chunks will consume

The extraction is summarization — the skill should produce a concise summary, not paste the full design.

Format the extraction into the "Upstream decisions" section that gets fed to downstream chunks (see above).

## Updating the artifact

After each chunk's session completes, update the artifact:

1. Add a link to the chunk's design doc and plan in the chunk's section
2. Optionally add a "Decisions made" subsection summarizing what was decided
3. Commit the artifact update

This creates a paper trail — anyone reading the artifact later can navigate from the discovery to the actual designs and plans produced.

## When chunking turns out to be wrong

A /superpowers session may surface that the chunking was wrong. Examples:
- "We can't design Chunk 2 because the constraints from Chunk 1 are wrong."
- "Chunks 2 and 3 should have been one chunk — they're heavily entangled."
- "This chunk needs a sub-decision that wasn't anticipated."

Protocol:
1. Operator interrupts dispatch (just stops the current /superpowers session and notifies the skill).
2. Skill stops the dispatch loop.
3. Operator updates the discovery artifact: revise chunks, dependencies, execution order. Add a "Revisions" section noting what changed and why.
4. Skill resumes dispatch from the affected chunk (or from earlier if upstream chunks are also affected).

This is manual for MVP. No automatic re-planning.

## When the operator wants to skip a chunk

If, mid-dispatch, the operator decides a chunk is no longer needed:
1. Mark it in the artifact: `Status: skipped — <reason>`
2. Skip the dispatch step for that chunk
3. Re-evaluate downstream chunks: do they still depend on this chunk's outputs? If so, what's the new plan?

## Anti-patterns

- ❌ **Auto-dispatching in background.** /superpowers is interactive. Backgrounding it means the operator can't answer its questions.
- ❌ **Running in a worktree by default.** /superpowers' artifacts need to be in the main tree.
- ❌ **Not feeding upstream decisions.** Each chunk needs its dependency chunks' decisions as context. Without them, /superpowers re-litigates settled decisions.
- ❌ **Auto-resuming after a chunking-was-wrong revision.** Revisions are operator-driven. Don't automate around the operator's control.
