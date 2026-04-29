# Dispatch Protocol

Phase 5 of the skill. After the artifact is committed, sequentially dispatch each chunk to /superpowers in dependency order.

## Sequential dispatch loop

```
For each chunk in execution order:
  1. Compose the dispatch prompt (see "Composing the prompt" below)
  2. Launch via Agent tool (foreground, main workspace)
  3. Operator interacts with /superpowers normally
  4. On completion: extract decisions, record as upstream context for downstream chunks
  5. Update artifact with link to chunk's plan output
  6. Move to next chunk
```

For MVP, even chunks that *could* run in parallel run sequentially — the operator can only interact with one /superpowers session at a time. The artifact records parallelism information for when parallel dispatch is built (deferred per memo §6).

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
