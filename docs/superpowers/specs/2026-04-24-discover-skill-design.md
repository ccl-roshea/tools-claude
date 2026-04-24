# Design: `/discover` Skill — Socratic Discovery + Chunking

**Date:** 2026-04-24
**Status:** Approved design, pending implementation plan
**Prerequisite:** Decision memo at `2026-04-23-socratic-discovery-tool-evaluation.md` (status: Go)
**Validation baseline:** Path A results at `/test-1/`, test cases at `2026-04-23-socratic-discovery-test-cases.md`

---

## Goal

A Claude Code skill that Socratically pressure-tests the user's problem framing, distinguishes constraints from choices, decomposes large problems into executor-sized chunks with dependencies, and sequentially dispatches each chunk to /superpowers or another executor.

It does not plan. It does not execute. It does the part that is currently missing upstream of /superpowers.

## Non-goals (explicitly out of MVP)

- Planning or execution (delegated to /superpowers)
- Per-node executor dispatch (the tool *recommends* an executor per chunk as a human-readable annotation; there is no automated routing logic)
- Parallel dispatch (chunks run sequentially even when independent — the operator can only interact with one /superpowers session at a time)
- Graph visualization or graph-editing UI
- Cross-session resume
- Plugin structure (standalone skill; promote to plugin later if warranted)

## File layout

```
skills/discover/
  SKILL.md                 # Main skill prompt — phased flow instructions
  references/
    artifact-template.md   # Markdown template for the discovery artifact
    chunking-guidelines.md # Heuristic signals + examples
    anti-sycophancy.md     # Technique specs (B, C, D) with examples
    dispatch-protocol.md   # How to launch /superpowers per chunk
```

## SKILL.md frontmatter

```yaml
---
name: discover
description: >
  Socratic idea discovery and chunking. Pressure-tests the user's
  problem framing, distinguishes constraints from choices, decomposes
  large problems into executor-sized chunks with dependencies, and
  sequentially dispatches each chunk to /superpowers or another executor.
  Use before /superpowers when the problem is vague, large, or the user
  isn't sure what they want.
when_to_use: >
  When the user has an idea or problem statement that needs exploration
  before planning. When the problem might be too large for a single
  /superpowers session. When the user says things like "I'm not sure
  exactly what I want" or presents a vague/ambitious goal.
allowed-tools: "Read Write Edit Bash(git *) Agent TaskCreate TaskUpdate"
---
```

`Agent` is in allowed-tools because the dispatch phase launches /superpowers sessions. `TaskCreate`/`TaskUpdate` for progress tracking during multi-chunk dispatch.

## Phases

The skill follows five sequential phases. The LLM executes them in order but can loop within phases.

### Phase 1: DISCOVER (Socratic exploration)

**Entry:** User pastes a problem statement (any length, any specificity).

**Behavior:**

- Ask one question at a time, Socratic style.
- **Technique D (constraints-vs-choices)** is active throughout: any time the user or the LLM introduces a specific implementation detail, classify it. "Is that a constraint imposed on you, or a choice you're making right now?" Choices get reopened; constraints are recorded.
- **Technique B (alternative framings)** fires 2-3 times at natural convergence points: after initial framing stabilizes, when a major architectural direction emerges, and before the tool proposes moving to chunking. Presents 2-3 fundamentally different ways to frame the problem. **Option 3 must always be a reductive (simpler) reframing** — this fights complexity bias and ensures the tool explores the full complexity spectrum equally. The right answer might be a distributed system or a single script; the Socratic process should surface which, not bias toward either.
- The tool tracks a running internal summary of: confirmed constraints, open questions, themes/concerns that have emerged, areas not yet explored.
- **Soft signals** for "propose moving on": the same area has been revisited 3+ times without new information, 10+ turns since the last new theme emerged, or the operator's answers are getting short/repetitive.
- When soft signals fire, the tool proposes: "I think [area] is sufficiently explored. Want to go deeper, or should I move on to [next area / chunking]?"

**Exit:** Operator agrees that discovery is sufficient, OR the tool proposes moving to chunking and operator approves.

### Phase 2: CHUNK (decomposition)

**Entry:** Discovery is complete. The tool has enough understanding to assess problem size.

**Behavior:**

- Assess whether the problem needs chunking using guideline-based signals (see Chunking guidelines section below).
- If no chunking needed: single chunk, proceed to Phase 3.
- If chunking needed: propose N chunks, each with a name, 2-3 sentence problem statement, confirmed constraints, open choices, and dependencies on other chunks. Compute execution order (topological sort).
- Present the proposal: "This looks like it should be N chunks. Here's how I'd split it: [chunks with dependencies and execution order]. Does this split make sense, or would you draw the lines differently?"
- Operator approves, modifies, or rejects.

**Exit:** Chunk structure approved by operator.

### Phase 3: RED-TEAM (technique C)

**Entry:** Chunks are defined (or single chunk confirmed).

**Behavior:**

- Explicit mode shift: "Switching to red-team mode. I'm going to try to break what we've concluded."
- For each chunk (or the single problem), systematically check:
  - Contradictions between chunks or between constraints
  - Assumptions that were never tested as constraints-vs-choices
  - Missing concerns that weren't explored during discovery
  - Scope creep — are chunks bigger than they need to be?
  - Dependency gaps — would chunk N actually need information from chunk M that isn't captured?
  - The "do you even need to build this?" question — is there an existing tool or simpler approach?
- Present findings as a numbered list with severity:
  - **CRITICAL** — must address before proceeding
  - **DISCUSS** — worth talking through
  - **MINOR** — noting for awareness
- Operator addresses each finding: accept (modify the chunk), dismiss (with reason), or defer.

**Exit:** All CRITICAL findings addressed. Operator approves.

### Phase 4: ARTIFACT (write the document)

**Entry:** Red-team complete, chunks finalized.

**Behavior:**

- Write the discovery artifact to `docs/discovery/<topic>.md` using the template (see Artifact template section below).
- Includes: framing, confirmed constraints, tested choices, all chunks with self-contained problem statements + dependencies + execution order, red-team findings and resolutions, collapsed discovery log.
- Commit to git.

**Exit:** Artifact written and committed.

### Phase 5: DISPATCH (launch executors)

**Entry:** Artifact committed.

**Behavior:**

- For each chunk in execution order:
  1. Compose the dispatch prompt: chunk's problem statement (verbatim from artifact) + chunk's constraints (inherited + chunk-specific) + chunk's open choices + upstream context (key decisions from completed dependency chunks).
  2. Launch via Agent tool. The agent invokes /superpowers:brainstorming with the composed prompt. The operator interacts with /superpowers normally.
  3. When the chunk's /superpowers session completes: extract key decisions made (architecture choices, tech stack, API contracts), record as upstream context for downstream chunks, update the artifact with a link to the chunk's plan.
  4. Move to next chunk in execution order.
- For parallelizable chunks: note they could run in parallel, but execute sequentially for MVP.
- If dispatch reveals the chunking was wrong (a chunk's /superpowers session surfaces something that invalidates another chunk's design): the operator interrupts dispatch, updates the discovery artifact, and re-runs from the affected chunk. This is manual for MVP.

**Exit:** All chunks have been through /superpowers. The operator has a design + plan for each.

## Anti-sycophancy techniques

Three techniques, complementary, each catching a different failure mode.

| Technique | When it fires | What it catches | Cost |
|-----------|--------------|-----------------|------|
| **D — Constraints vs. choices** | Continuously, every time a specific surfaces | Untested assumptions baked into the framing | ~0 extra turns |
| **B — Alternative framings** | 2-3 times at convergence points | Wrong problem frame, complexity bias | ~2-3 extra turns total |
| **C — Red-team pass** | Once, as its own phase (Phase 3) before handoff | Contradictions, missing concerns, scope creep, dependency gaps | ~2 extra turns |

### Technique D — Constraints vs. choices (continuous)

Any time a specific implementation detail appears (from user or LLM), ask: "Is that a constraint — something imposed on you externally — or a choice you're making right now?" Constraints are recorded. Choices trigger a brief exploration of 2-3 alternatives before the user picks.

### Technique B — Alternative framings (2-3 times)

At natural convergence points, present 2-3 fundamentally different ways to frame the problem:
1. The current frame (what we've been building toward)
2. An alternative frame (reframes the problem differently)
3. A reductive frame (what if the real problem is actually just [simpler thing]?)

**Principle: equal weight across the complexity spectrum.** The reductive frame is not a "have you considered doing less?" checkbox. It ensures the tool explores whether a simple solution is correct with the same rigor it applies to complex solutions. The right answer might be either end of the spectrum.

### Technique C — Red-team pass (Phase 3)

Explicit mode shift. The tool attempts to break what has been concluded. Findings are classified by severity. All CRITICAL findings must be addressed before proceeding. See Phase 3 above for full protocol.

## Chunking guidelines

Guideline-based signals the LLM uses to decide when to propose chunking. These are guidelines, not hard rules — the LLM uses judgment informed by these signals.

### Signals that suggest chunking is needed

1. **Multiple independent subsystems emerged.** The conversation revealed 2+ things that could be designed and built independently.
2. **Mixed tech domains.** Frontend, backend, infrastructure, data pipeline — the problem spans domains that would naturally be handled by different specialists or sessions.
3. **More than ~3-5 distinct design decisions.** If more than 5 significant architectural choices would need to be made in a single /superpowers session, the session will either go shallow on each or run so long that context degrades.
4. **Natural dependency boundaries.** Some decisions must be made before others. When dependency chains exist, the upstream decision is a natural chunk boundary.
5. **The operator signals decomposition.** Phrases like "there are two parts to this," "first we need X, then Y," "the backend and frontend are separate concerns."

### Signals that suggest chunking is NOT needed

1. **Single domain, single concern.** One tech domain, one central design decision.
2. **Tight coupling.** Every part depends on every other part; chunking would create artificial boundaries.
3. **Small scope.** Fewer than ~3 distinct design decisions.

### How the tool proposes chunks

Present: chunk names, 2-3 sentence scopes, dependencies, and execution order. The operator can approve, merge chunks, split further, or reorder.

## Artifact template

The discovery artifact uses a consistent structure regardless of chunk count.

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
> <verbatim user input>

### Key reframes
- <what changed from the original statement and why>

## Confirmed constraints
- <constraint>: <why it's a constraint, not a choice>

## Tested choices
- <choice>: <alternatives considered, why this was selected>

## Chunk 1: <name>

### Problem statement
<2-5 sentences, self-contained, paste-ready for /superpowers.
Includes enough context that an executor in a fresh session
can understand the problem without reading the rest of the artifact.>

### Constraints (inherited + chunk-specific)

### Open choices (for the executor to resolve)

### Dependencies
None | Depends on: Chunk N (specifically: <what decision is needed>)

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

## Discovery log (collapsed)
<details>
<summary>Socratic Q&A highlights</summary>

- **Q:** <question asked>
  **A:** <user answer>
  **Impact:** <how this changed the framing>
</details>
```

**Key design decisions:**

- **Chunk problem statements are self-contained.** An executor in a fresh session should understand the chunk without reading the rest of the artifact.
- **"Tested choices" are distinct from constraints.** These are choices that survived Technique D — alternatives were considered. This prevents downstream executors from re-opening decisions already pressure-tested.
- **Discovery log is collapsed.** It's for the human who returns weeks later, not for the executor.
- **Red-team findings split into addressed vs. accepted risks.** Nothing is hidden.

## Dispatch protocol

### Sequential dispatch with operator interaction

For each chunk in execution order:

1. **Compose dispatch prompt:** chunk's problem statement (verbatim) + constraints + open choices + upstream decisions from completed dependency chunks.
2. **Launch via Agent tool** (foreground, not background — the operator needs to interact with /superpowers): the agent invokes /superpowers:brainstorming with the composed prompt. The operator interacts with /superpowers normally for that chunk. The agent runs in the main workspace (not a worktree) so file writes from /superpowers are visible.
3. **On completion:** extract key decisions (architecture, tech stack, API contracts), record as upstream context for downstream chunks, update artifact with link to chunk's plan.
4. **Next chunk.**

### Upstream context format

When chunk N depends on chunk M, chunk N's dispatch prompt includes:

```markdown
## Upstream decisions (from completed chunks)

### From Chunk M: <name>
- Decided: <decision>
- Reason: <why>
- Relevant detail: <API contract, schema, protocol, etc.>
```

### When chunking turns out to be wrong

If a chunk's /superpowers session reveals that the chunking needs revision: operator interrupts dispatch, updates the discovery artifact, re-runs from the affected chunk. Manual for MVP.

### Parallelizable chunks

For MVP, even independent chunks run sequentially. The artifact notes which chunks could run in parallel, preserving the information for when parallel dispatch is built.

## Testing and validation

### Level 1: Skill-creator evals (automated, during implementation)

| Test prompt | Expected behavior |
|---|---|
| "I want to deploy agents for my team that can communicate" | Technique D fires on specifics. At least 5 of 8 expected items explored. |
| "Build me a todo app" | Full discovery + red-team. No chunking. Single-chunk artifact. |
| "We need a platform with auth, billing, a marketplace, and analytics" | Chunking proposed early. At least 3 chunks. |
| "Build a REST API using Express with Postgres and deploy to AWS ECS" | Technique D challenges at least 2 specifics. Technique B offers a simpler reframing. |

### Level 2: Path B validation (manual, against Path A baseline)

Run Test 1 prompt through `/discover` in a clean-room session per the test cases doc protocol. Feed artifact into /superpowers. Score Coverage and Correctness of Frame. Path B must beat Path A by +1 on both.

### Level 3: Additional real problems (manual)

Run 2 more real problems (different domains) through both paths. Pass = Path B wins in at least 2 of 3 total cases.

### Skill-creator workflow

1. **During implementation:** use skill-creator to write SKILL.md + reference files (correct frontmatter, conventions)
2. **Post-implementation:** use skill-creator evals for Level 1 testing
3. **Before shipping:** use skill-creator to optimize description for triggering accuracy

## Implementation notes

- **Skill-creator is the primary authoring tool.** The implementation plan should include explicit skill-creator invocations for writing the skill, running evals, and optimizing the description.
- **Approach 1 (single SKILL.md with reference files)** is the MVP architecture. If the prompt proves too long or the LLM drifts between phases, upgrade to Approach 2 (multi-skill pipeline). If hooks or settings are needed, upgrade to Approach 3 (plugin).
- **The skill is complementary to /superpowers, not competitive.** `/discover` runs upstream; /superpowers runs downstream. They share no state except the artifact.
