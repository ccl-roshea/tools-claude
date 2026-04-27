# `/discover` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `/discover` skill — a Socratic discovery + chunking tool that pressure-tests problem framing, classifies constraints vs. choices, decomposes large problems into executor-sized chunks, performs build-vs-buy research, and dispatches each chunk to /superpowers in dependency order.

**Architecture:** Standalone Claude Code skill at `skills/discover/`. Single `SKILL.md` prompt file with five reference documents under `references/`. Skill-creator handles eval authoring, run, and final description optimization. Validation against Path A baseline at `/test-1/transcript.md`.

**Tech Stack:** Markdown (skill files). Skill-creator skill for evals and optimization. WebSearch + WebFetch for the research phase. Agent tool for dispatch. No traditional code or test runner — "tests" are skill-creator eval cases that check expected behaviors fire on representative prompts.

**Spec:** `docs/superpowers/specs/2026-04-24-discover-skill-design.md`
**Decision memo:** `docs/superpowers/specs/2026-04-23-socratic-discovery-tool-evaluation.md`
**Path A baseline transcript:** `/test-1/transcript.md`
**Path A artifacts:** `/test-1/docs/plans/`

**Key principle for this plan:** every reference-file task contains the *full file content* in code blocks. The engineer copies content directly. No "fill in the details" steps anywhere.

---

## Phase 0 — Setup

### Task 0.1: Create skill directory structure

**Files:**
- Create: `skills/discover/` (directory)
- Create: `skills/discover/references/` (directory)

- [ ] **Step 1: Create directories**

```bash
mkdir -p /workspace/skills/discover/references
ls /workspace/skills/discover/
```

Expected output: empty directory listing of `references/`.

- [ ] **Step 2: Verify the existing `skills/` layout convention**

```bash
ls /workspace/skills/example-greet/
cat /workspace/skills/example-greet/SKILL.md
```

Expected: confirms convention — `SKILL.md` lives directly inside the skill directory, with YAML frontmatter and body.

- [ ] **Step 3: Commit empty structure**

```bash
cd /workspace
git add skills/discover/
git status
# Note: empty directories don't track in git. We'll commit after the first file.
```

No commit yet — wait until first file is added.

---

## Phase 1 — Reference files

The reference files are written first because they hold the heavy content the SKILL.md will reference. Writing them first prevents SKILL.md from bloating with content that should live in references.

### Task 1.1: Write `references/anti-sycophancy.md`

**Files:**
- Create: `skills/discover/references/anti-sycophancy.md`

- [ ] **Step 1: Write the full reference file**

Write file `/workspace/skills/discover/references/anti-sycophancy.md` with this exact content:

````markdown
# Anti-Sycophancy Techniques

Three techniques the skill uses to prevent the LLM from drifting into agreeable summarization. Each catches a different failure mode and runs at different points in the flow.

| Technique | When it fires | What it catches | Cost |
|-----------|--------------|-----------------|------|
| **D — Constraints vs. choices** | Continuously, every time a specific surfaces | Untested assumptions baked into the framing | ~0 extra turns |
| **B — Alternative framings** | 2-3 times at convergence points in Phase 1 | Wrong problem frame, complexity bias | ~2-3 extra turns total |
| **C — Red-team pass** | Once, as Phase 3 (its own phase) | Contradictions, missing concerns, scope creep, dependency gaps | ~2 extra turns |

---

## Technique D — Constraints vs. choices (continuous)

**When to fire:** Any time a specific implementation detail appears in the conversation. The detail can come from the user's input, the user's answer to a question, or the LLM's own suggestion.

Examples of "specific implementation details":
- A named technology ("Postgres", "AWS", "Next.js", "Azure")
- A protocol or pattern ("REST", "GraphQL", "event-driven")
- A architectural choice ("microservices", "monorepo", "serverless")
- A library or framework ("React", "FastAPI", "Tailwind")
- A concrete number that wasn't justified ("3-week MVP", "$500/month budget")

**The prompt:**

> "You mentioned [X]. Is that a constraint — something imposed on you externally (company policy, existing infra, compliance, team decision) — or a choice you're making right now? If it's a choice, I want to explore alternatives before we lock it in."

**If constraint:** record it in the running constraints list. Note who/what imposed it and why it can't be changed. Move on.

**If choice:** briefly present 2-3 alternatives covering the realistic option space. The user picks one or keeps the original — but now it's a *tested* choice, not an untested assumption. Record the alternatives considered in the "Tested choices" list.

### Example (good)

User: "I want to build it on AWS."
Skill: "Is AWS a constraint (company is on AWS, IT mandates it, existing infra) or a choice you're making? If choice, alternatives might include: GCP if you want managed AI services, a small VPS like Hetzner or Fly.io if you want simpler ops, or even running on a single server if scale is small."
User: "Constraint — we have an enterprise AWS contract."
Skill: [records constraint] "Got it. Locked in. Moving on."

### Example (good — choice surfaced and tested)

User: "Each agent will be a Python microservice."
Skill: "Is 'microservice per agent' a constraint or a choice? Alternatives: a single multi-agent process with concurrency, a serverless function per agent, or even just classes inside one app."
User: "Hm, I assumed microservices but actually a single process is fine for our scale."
Skill: [records as tested choice: single process selected, microservices rejected because scale doesn't warrant it]

### Example (anti-pattern — don't do this)

User: "I want to use Postgres."
Skill: "Great choice, Postgres is excellent. Moving on."

This is the failure mode. Specifics get adopted without testing. Always classify.

### Reverse sunk-cost check (Phase 3.5 only)

In the research phase, when an existing tool was found that satisfies a chunk, apply Technique D to the operator's stated preference for building:

> "Is 'we want to build this ourselves' a constraint or a choice? If choice, the bar for rejecting [tool name] must be specific functional gaps or constraint conflicts — not preference."

This fights the inverse failure mode: dismissing a good existing tool because the operator is emotionally invested in building.

---

## Technique B — Alternative framings (2-3 times per Phase 1)

**When to fire:** At natural convergence points in Phase 1 (DISCOVER). Specifically:

1. After the initial problem framing stabilizes (typically turns 3-5)
2. When a major architectural direction emerges
3. Before the tool proposes moving from DISCOVER to CHUNK

The LLM should not fire this every turn. It should sense when the conversation is *settling* on a frame and use that as the cue.

**The prompt:**

> "Before we go further, let me offer three different ways to think about this problem:
>
> 1. [Current frame] — what we've been building toward
> 2. [Alternative frame] — reframes the problem as [X]
> 3. [Reductive frame] — what if the real problem is actually just [simpler thing]?
>
> Which resonates, or is the real answer a mix?"

**Critical principle: equal weight across the complexity spectrum.** Option 3 (reductive) must always be present, but it is not a "have you considered doing less?" checkbox. The reductive frame must be evaluated with the same rigor as the complex frames. The right answer might be "yes, this really is a distributed system" or "actually, a single shell script does it."

The bias the LLM must fight: Socratic exploration tends to expand problems. Without the reductive frame, conversations drift toward bigger, more architected solutions. Including the reductive frame keeps the full complexity space honest.

### Example (good reframings for "deploy agents for my team")

1. **Current frame:** A multi-service platform with a portal, orchestrator, and specialist agents communicating via A2A.
2. **Alternative frame:** A shared chat workspace where each "agent" is just a Claude Code skill team members invoke via slash commands. No platform. No orchestrator. Just shared skills in a git repo.
3. **Reductive frame:** A shared bookmark folder pointing to a few well-crafted prompts the team can paste into ChatGPT/Claude as needed. No code at all.

The user might pick frame 2, or pick a hybrid of 1 and 2, or realize frame 3 is genuinely sufficient. All three deserve serious consideration.

### Anti-pattern: weak reductive frame

Don't write: "3. A simpler version of frame 1." That's not a real alternative — it's a hedge. The reductive frame must be *qualitatively different* in approach, not just a smaller version of the complex one.

---

## Technique C — Red-team pass (Phase 3, its own phase)

**When to fire:** Once, as Phase 3 of the skill flow. Not optional. Not skippable. Even single-chunk simple problems get a red-team pass.

**Mode shift signal:** the LLM announces explicitly that it is shifting to red-team mode. This signals the operator that the next round is adversarial, not collaborative.

> "Switching to red-team mode. I'm going to try to break what we've concluded. For each finding I'll note severity: CRITICAL (must address before proceeding), DISCUSS (worth talking through), or MINOR (noting for awareness)."

### What the red-team checks

For each chunk (or the single problem):

1. **Contradictions** — between chunks, between constraints, between constraints and chunk goals.
2. **Untested specifics** — assumptions that surfaced but were never classified as constraints-vs-choices. (This catches Technique D misses.)
3. **Missing concerns** — domains/topics that should have been explored but weren't. Cross-reference common architectural concerns: auth, observability, error handling, cost, performance, deployment, testing, security, data lifecycle.
4. **Scope creep** — chunks bigger than they need to be. Could a chunk be split? Is a chunk pulling in concerns that belong elsewhere?
5. **Dependency gaps** — would chunk N actually need information from chunk M that isn't captured in chunk M's outputs? If so, the dependency arrow is wrong or the upstream chunk is incomplete.
6. **Existence question** — "do you even need to build this?" Is there an existing tool or simpler approach? (This is shallow check from training data — Phase 3.5 does the active research.)
7. **Stop-the-clock check** — what happens if you stop here? What would be lost vs. what would be gained?

### Severity classification

- **CRITICAL** — must be addressed before proceeding. Examples: a contradiction between two chunks, a missing dependency that would invalidate a chunk's design, a constraint that conflicts with the chosen approach.
- **DISCUSS** — worth talking through. The operator decides whether to act. Examples: scope creep that's borderline, a missing concern that may or may not matter for MVP.
- **MINOR** — noting for awareness. No action required, but recorded. Examples: opinion-based concerns, future risks not relevant to current scope.

### Operator response per finding

- **Accept** — modify the chunk to address the finding. Record the change.
- **Dismiss** — record the finding and the operator's reason for dismissing. Future readers should see why this concern was raised and rejected.
- **Defer** — record as a known issue for V2. Not in MVP scope.

### Exit criteria

All CRITICAL findings must be either Accepted (chunk modified) or Dismissed with explicit reason. DISCUSS and MINOR findings are recorded regardless. Operator approves before phase exits.

---

## How the techniques interact

- **Technique D feeds Technique C.** Specifics that *should* have been classified by D but weren't are exactly what C catches. If C is finding lots of unclassified specifics, the LLM is failing at D and should improve.
- **Technique B feeds Technique D.** Choosing a frame in B makes some specifics constraints (locked in by the framing) and others choices (still open). D operates on both.
- **Technique C is the safety net.** B and D run during exploration; C runs at commitment. By the time C runs, B and D should have caught most issues — C catches what they missed.

If C is finding a lot of CRITICAL issues, it means B and D are weak. That's a signal the skill prompt needs improvement, not a sign that C is doing its job well.
````

- [ ] **Step 2: Verify file content**

```bash
wc -l /workspace/skills/discover/references/anti-sycophancy.md
head -20 /workspace/skills/discover/references/anti-sycophancy.md
```

Expected: ~150 lines. First lines show the title and intro paragraph.

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add skills/discover/references/anti-sycophancy.md
git commit -m "feat(discover): add anti-sycophancy reference"
```

### Task 1.2: Write `references/chunking-guidelines.md`

**Files:**
- Create: `skills/discover/references/chunking-guidelines.md`

- [ ] **Step 1: Write the full reference file**

Write `/workspace/skills/discover/references/chunking-guidelines.md`:

````markdown
# Chunking Guidelines

Heuristic signals the LLM uses in Phase 2 (CHUNK) to decide whether to propose decomposition. These are guidelines, not hard rules. The LLM uses judgment informed by these signals.

## Goal of chunking

A chunk is a unit of work scoped for a single executor session (typically `/superpowers`). The right chunk size is whatever can be designed and planned in one focused session without context exhaustion or shallow coverage. Roughly: one major architectural concern, ~3 design decisions, one tech domain.

Chunks form a directed acyclic graph (DAG) where edges represent dependencies — a chunk's design must wait for its upstream chunks' decisions.

## Signals that suggest chunking is needed

The LLM should propose chunking when 2 or more of these are present:

### 1. Multiple independent subsystems emerged

The conversation revealed 2 or more things that could be designed and built independently. Examples:
- A web portal + an agent runtime + a communication layer
- A user-facing API + a background worker + a notification system
- A data ingestion pipeline + a query interface + a monitoring layer

### 2. Mixed tech domains

The problem spans frontend + backend + infra, or different language/framework ecosystems, or different specialist concerns (UX vs. distributed systems vs. data engineering). These would naturally be handled in different sessions.

### 3. More than ~3-5 distinct design decisions

If the operator would need to make more than 5 significant architectural choices in a single /superpowers session, the session will go shallow on each (the Path A failure mode) or run so long that context degrades. Chunking redistributes decision load.

### 4. Natural dependency boundaries

Some decisions must be made before others. "What's the communication protocol?" must be answered before "What does the portal's API client look like?" When dependency chains are visible, the upstream decision is a natural chunk boundary.

### 5. The operator signals decomposition

Phrases like:
- "There are two parts to this..."
- "First we need X, then Y..."
- "The backend and frontend are separate concerns..."
- "I want to do A but also B..."

The operator is already chunking mentally. The tool should formalize the split.

## Signals that suggest chunking is NOT needed

The LLM should NOT propose chunking when 2 or more of these are present:

### 1. Single domain, single concern

The problem lives in one tech domain and has one central design decision. Example: "add retry logic to the API client" — one chunk.

### 2. Tight coupling

Every part of the problem depends on every other part. Chunking would create artificial boundaries and force premature decisions. Example: "design the database schema for this feature" — the tables relate to each other and must be designed together.

### 3. Small scope

Fewer than ~3 distinct design decisions. A single /superpowers session handles this comfortably.

## Edge cases

### "It feels chunkable but the chunks are tightly coupled"

This is a sign the chunk boundaries are wrong, not that the problem is one chunk. Look for a different cut. Common reframings:
- Cut by data ownership (which chunk owns what data?)
- Cut by user-facing surface (each external interface is a chunk)
- Cut by failure domain (what fails together, stays together)

### "It feels small but might grow"

Don't chunk preemptively. Chunk when chunking is needed *now*, not when it might be needed later. The skill can be re-invoked on a chunk that grew unexpectedly.

### "The operator wants chunks but the problem is small"

Push back gently. Apply Technique B's reductive frame: is there a simpler solve that wouldn't need chunking? If the operator confirms they want chunks, propose them. The operator has final say.

## How to propose chunks

Once chunking is justified, present the proposal:

> "This looks like it should be N chunks. Here's how I'd split it:
>
> 1. **[Chunk name]** — [2-3 sentence scope]. Dependencies: none.
> 2. **[Chunk name]** — [2-3 sentence scope]. Dependencies: Chunk 1 (specifically: what decision/output is needed).
> 3. **[Chunk name]** — [2-3 sentence scope]. Dependencies: Chunk 1.
>
> Execution order: 1, then 2 and 3 in parallel.
>
> Does this split make sense, or would you draw the lines differently?"

### Each chunk needs

- **Name** — short, descriptive, distinct from the others
- **Scope** — 2-3 sentences capturing what's in and what's out
- **Dependencies** — explicit list of which other chunks this depends on, AND the specific decision/output it needs from them
- **Recommended executor** — usually `/superpowers:brainstorming`, but the artifact can recommend others (e.g., a frontend-design skill if one exists)

### Computing execution order

Topological sort by dependencies:
1. Find all chunks with no dependencies — these can run first.
2. After those complete, find chunks whose dependencies are all complete — those can run next.
3. Repeat until all chunks are ordered.
4. Note which chunks at each level can run in parallel.

For MVP, even parallelizable chunks run sequentially — the operator can only interact with one /superpowers session at a time. The artifact records parallelism information for when parallel dispatch is built.

## Examples

### Example 1: clear chunking needed

Problem: "I want a team agent platform with a portal, agent runtime, and Slack integration."

Chunks:
1. **Agent runtime** — how agents execute, what their interface is, how they receive jobs. No dependencies.
2. **Portal** — web UI for team members. Depends on Chunk 1 (needs agent invocation API contract).
3. **Slack integration** — bot that proxies between Slack and the runtime. Depends on Chunk 1 (same reason).

Execution: 1, then 2 and 3 in parallel.

### Example 2: tight coupling, no chunking

Problem: "Design the schema for orders, line items, and discounts in our e-commerce app."

This is one tightly-coupled chunk. Order ↔ line item is a 1:N relationship; discounts apply to both lines and order totals. Splitting these would force the operator to invent interfaces between chunks that don't exist in reality.

### Example 3: operator signals chunking

User: "I want to redesign the checkout flow, AND while we're at it, switch from REST to GraphQL for the cart API."

Operator already said "AND while we're at it." Two chunks:
1. **Cart API: REST to GraphQL** — schema, resolvers, migration plan. No dependencies.
2. **Checkout flow redesign** — UX flow, component changes. Depends on Chunk 1 (new API shape changes how checkout fetches cart state).

Execution: 1, then 2.
````

- [ ] **Step 2: Verify file content**

```bash
wc -l /workspace/skills/discover/references/chunking-guidelines.md
```

Expected: ~120 lines.

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add skills/discover/references/chunking-guidelines.md
git commit -m "feat(discover): add chunking guidelines reference"
```

### Task 1.3: Write `references/research-protocol.md`

**Files:**
- Create: `skills/discover/references/research-protocol.md`

- [ ] **Step 1: Write the full reference file**

Write `/workspace/skills/discover/references/research-protocol.md`:

````markdown
# Research Protocol (Build-vs-Buy)

Phase 3.5 of the skill. After red-team and before artifact commit, actively research existing tools that might satisfy chunks. Replaces training-data intuition with current web evidence.

## Why this phase exists

Phase 3 (red-team) checks "is there an existing tool?" using only the LLM's training data. Training data has cutoff issues and recency problems. The LLM also tends to reject existing tools without rigorous evaluation. The Path A test demonstrated this: AutoGen, LangGraph, Microsoft Agent Framework, and Claude Agent SDK were all named, then all rejected in favor of build-it-yourself, with no actual evaluation.

This phase replaces "I think there might be a tool" with "I searched and evaluated three candidates."

## Search strategy

### Per-chunk search

For each chunk, run at least one targeted search. The query is constructed from the chunk's problem statement and confirmed constraints. Examples:

- Chunk: "Auth for a B2B SaaS app, multi-tenant, SSO required"
  Query: `"multi-tenant SSO auth provider B2B SaaS"` and follow-ups for top results

- Chunk: "Background job runner with retry and observability"
  Query: `"background job queue Python retry observability"`

- Chunk: "Real-time collaboration cursor + presence"
  Query: `"real-time collaboration cursor presence library"`

### Overall problem search

In addition to per-chunk searches, run one **whole-problem search**. Sometimes the right answer is to skip all chunks and adopt one platform. Example:

- Problem: "I want a team agent platform"
  Query: `"team agent platform Claude" OR "multi-agent framework"` — surfaces AutoGen, LangGraph, Claude Agent SDK, etc.

If the whole-problem search finds a strong match, propose adopting it across multiple chunks. The chunk structure may collapse.

### Tools to use

- **WebSearch** — primary discovery. Use for finding candidates.
- **WebFetch** — fetch specific pages (homepage, pricing, docs) to evaluate candidates.
- **`mcp__plugin_context7_context7__resolve-library-id`** + **`mcp__plugin_context7_context7__query-docs`** — when evaluating a specific library, get current authoritative docs.

### When search results look thin

If the first search returns weak results:
1. Refine the query — add domain terms, remove specifics that may be too narrow.
2. Try alternative framings — "tool" vs. "library" vs. "framework" vs. "service".
3. Search for the *category* — "what are the leading X solutions in 2026?"

If after 2-3 refinements still no good candidates: that's a real signal there's no obvious existing tool. Move on. Don't search forever.

## Evaluation criteria

For each candidate, evaluate against ALL of:

### 1. Functionality match (%)

What percentage of the chunk's requirements does this candidate cover? Be specific — list what it does and what it doesn't. Don't round up.

### 2. License compatibility

- Open source license — MIT/Apache/BSD are usually fine, GPL/AGPL may have implications
- Commercial — pricing model, lock-in clauses
- Patent grants and contributor terms
- Compatibility with the operator's company policies (note as a constraint to verify if unknown)

### 3. Cost

- Free? Paid? Freemium?
- If paid: pricing model (per-user, per-request, per-MB, flat)
- For freemium: where does the free tier end? Is the free tier sustainable for the operator's expected scale?
- Include hidden costs: hosting if self-hosted, training time, integration burden

### 4. Maintenance status

- Last release date
- Open issues, PR turnaround
- Contributor activity (single maintainer? Active community?)
- Recent breaking changes
- Clear roadmap?

A tool with active maintenance is much more valuable than one with marginally better functionality but stale maintenance.

### 5. Lock-in / dependency risk

- How hard is it to swap out later?
- Does it require significant rewrites of *your* code to integrate?
- Are there standard interfaces (e.g., OAuth, S3 API, OpenAPI) that make replacement easier?
- Is the tool itself dependent on a single vendor that could disappear?

### 6. Integration burden

- Auth requirements (API keys, OAuth, mTLS)
- Data format expectations
- Runtime requirements (Python version, Docker, K8s)
- Network/firewall implications
- Documentation quality

## Classification

Each candidate is classified into exactly one of four buckets:

### Adopt fully

The candidate covers the entire chunk's scope. The chunk is *replaced* with a much smaller "evaluate, install, configure, integrate" chunk. The original build-from-scratch chunk is deleted.

Example: chunk was "build OAuth provider"; candidate is Auth0; chunk becomes "integrate Auth0 — set up tenant, configure callbacks, wire to app."

### Adopt partially

The candidate covers part of the chunk's scope. The chunk *shrinks* to cover only the gap. The artifact records what the existing tool covers vs. what's still being built.

Example: chunk was "build agent orchestration"; candidate is LangGraph; chunk becomes "build agent orchestration on top of LangGraph (using LangGraph for state machine and tool routing; building custom: persistence layer, multi-tenancy, billing-aware rate limiting)."

### Reject

The candidate doesn't fit. The candidate's name, version, and rejection reason are recorded in the artifact. **This is important** — future readers should see which alternatives were considered and why they were rejected. Without this, every future engineer will re-ask the same question.

Reasons should be specific:
- "Auth0 free tier ends at 7,500 users; we need to support 50k+ at MVP"
- "Temporal requires running a separate cluster; ops budget doesn't allow"
- "AutoGen is Python-only; our backend is TypeScript"

Vague reasons are red flags: "doesn't fit our needs" is not a rejection reason — it's a placeholder.

### Inspire

Don't adopt, but the candidate has architecture or interface ideas worth borrowing. Note as a reference link in the chunk's notes for the executor.

## Reverse sunk-cost check

Before classifying any candidate as Reject, apply Technique D to the operator's stated preference for building:

> "Is 'we want to build this ourselves' a constraint (e.g., must be self-hosted, must be open-source-only) or a choice? If choice, what specific functional gaps or constraint conflicts make [tool name] unacceptable? Pricing? Lock-in? Integration burden? Be specific."

If the operator can't articulate a specific reason, the rejection is suspect. Either find a real reason or reconsider Adopt/Adopt partially.

## Soft limits

Don't research forever:

- **Per chunk:** evaluate ~3-5 candidates. After that, classify the rest as Reject (not evaluated, no obvious fit) and move on.
- **Per session:** ~30 minutes of research total. Beyond that, the operator should call it.
- **Stop early when:** a clear winner emerges (Adopt fully) — don't keep evaluating just for completeness.

## Output format

Findings get folded into the artifact in Phase 4. Each finding includes:

```markdown
- **<Tool name>** — Adopt fully / Adopt partially / Reject / Inspire
  - URL: <link>
  - Functionality match: <%>
  - Cost: <free / paid / pricing>
  - License: <license + any concerns>
  - Maintenance: <active / stable / stale>
  - Lock-in: <low / medium / high>
  - Integration burden: <low / medium / high>
  - Reason for classification: <specific>
```

Then per-chunk outcome:

```markdown
- **Outcome:** <chunk modified to ... | chunk eliminated | chunk replaced with integration chunk | chunk unchanged, build custom>
```

## Anti-patterns

- ❌ **Searching once, skimming the first result, declaring "no good options."** Always evaluate at least 2-3 candidates against the criteria.
- ❌ **Vague rejection reasons.** "Doesn't fit" is a placeholder. Specify what doesn't fit.
- ❌ **Skipping the reverse sunk-cost check.** When you find a candidate that matches the chunk and the operator says "let's build anyway," apply Technique D before recording Reject.
- ❌ **Pricing-page hand-waving.** If a candidate is paid, check the actual pricing page. Don't guess.
- ❌ **Researching forever.** Soft limits exist for a reason. After 3 candidates without a clear winner, move on.
````

- [ ] **Step 2: Verify file content**

```bash
wc -l /workspace/skills/discover/references/research-protocol.md
```

Expected: ~150 lines.

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add skills/discover/references/research-protocol.md
git commit -m "feat(discover): add research protocol reference"
```

### Task 1.4: Write `references/artifact-template.md`

**Files:**
- Create: `skills/discover/references/artifact-template.md`

- [ ] **Step 1: Write the full reference file**

Write `/workspace/skills/discover/references/artifact-template.md`:

````markdown
# Discovery Artifact Template

The output document the skill writes in Phase 4. Every discovery session produces one artifact in this format, regardless of chunk count. Single-chunk problems get the same template — sections just stay short.

## Filename and location

`docs/discovery/<topic-slug>.md`

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

- <constraint>: <why it's a constraint, not a choice>
- <constraint>: ...

## Tested choices

- <choice>: <alternatives considered, why this was selected>
- <choice>: ...

## Chunk 1: <name>

### Problem statement

<2-5 sentences, self-contained, paste-ready for /superpowers.
Includes enough context that an executor in a fresh session
can understand the problem without reading the rest of the artifact.>

### Constraints (inherited + chunk-specific)

- <constraint>
- <constraint>

### Open choices (for the executor to resolve)

- <choice>
- <choice>

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
  - **<Tool name>** — Adopt / Adopt partially / Reject / Inspire
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

- **Constraints** = externally imposed (company policy, existing infra, compliance, team decision). These cannot be challenged downstream.
- **Tested choices** = surfaced as choices, alternatives explored, this one selected. Downstream executors should NOT re-open these — the alternatives were already considered.

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
````

- [ ] **Step 2: Verify file content**

```bash
wc -l /workspace/skills/discover/references/artifact-template.md
```

Expected: ~150 lines.

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add skills/discover/references/artifact-template.md
git commit -m "feat(discover): add artifact template reference"
```

### Task 1.5: Write `references/dispatch-protocol.md`

**Files:**
- Create: `skills/discover/references/dispatch-protocol.md`

- [ ] **Step 1: Write the full reference file**

Write `/workspace/skills/discover/references/dispatch-protocol.md`:

````markdown
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
````

- [ ] **Step 2: Verify file content**

```bash
wc -l /workspace/skills/discover/references/dispatch-protocol.md
```

Expected: ~120 lines.

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add skills/discover/references/dispatch-protocol.md
git commit -m "feat(discover): add dispatch protocol reference"
```

---

## Phase 2 — SKILL.md

### Task 2.1: Write SKILL.md (frontmatter + intro + Phase 1)

**Files:**
- Create: `skills/discover/SKILL.md`

- [ ] **Step 1: Write the file with frontmatter, intro, and Phase 1 (DISCOVER)**

Write `/workspace/skills/discover/SKILL.md`:

````markdown
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
allowed-tools: "Read Write Edit Bash(git *) Agent TaskCreate TaskUpdate WebSearch WebFetch"
---

# Discover — Socratic Discovery + Chunking

You are running the `/discover` skill. Your job is to take a user's problem statement (any vagueness, any specificity) and produce a discovery artifact that downstream tools like /superpowers can consume.

You do NOT plan. You do NOT execute. You do the part that is currently missing upstream of /superpowers: pressure-test the framing, classify constraints vs. choices, research existing solutions, decompose into executor-sized chunks, and dispatch each chunk in dependency order.

## Reference files

When you need detailed guidance, read the relevant reference file:

- `references/anti-sycophancy.md` — Techniques B, C, D with examples and prompts
- `references/chunking-guidelines.md` — When to chunk, how to chunk, edge cases
- `references/research-protocol.md` — Build-vs-buy search and evaluation
- `references/artifact-template.md` — The output document format
- `references/dispatch-protocol.md` — How to launch /superpowers per chunk

You should read these on demand, not all at once at session start.

## The six phases

You execute the following phases in order. Within each phase you can loop, but you don't skip ahead. Each phase has explicit entry and exit criteria.

1. **DISCOVER** — Socratic exploration with continuous Technique D (constraints vs. choices) and 2-3 invocations of Technique B (alternative framings)
2. **CHUNK** — Decompose into executor-sized chunks if needed; compute execution order
3. **RED-TEAM** — Adversarial pass on the conclusions (Technique C)
4. **RESEARCH** (Phase 3.5) — Active build-vs-buy research; restructure chunks based on findings
5. **ARTIFACT** — Write and commit the discovery document
6. **DISPATCH** — Sequentially launch /superpowers for each chunk

The flow is: gather understanding → decompose → attack → research → write → execute. Each phase narrows commitment from "open exploration" to "executor-ready problem statements."

## Phase 1: DISCOVER

**Entry:** User pastes a problem statement. The statement may be a single sentence or multiple paragraphs. It may be vague ("I want to deploy agents for my team") or over-specified ("Use Express, Postgres, deploy to ECS"). Both are valid inputs.

**Exit:** The operator agrees that discovery is sufficient, OR you propose moving on and the operator approves.

### What you do in this phase

Ask one question at a time. Socratic style — probe the framing, surface assumptions, classify specifics. Never ask multi-part compound questions; if you have multiple things to ask, ask them in sequence.

### Continuous: Technique D (constraints vs. choices)

Read `references/anti-sycophancy.md` for the full Technique D protocol if you haven't already.

**Trigger:** any time a specific implementation detail appears in the conversation. The detail can come from the user's input, an answer they give, or a suggestion you make.

**Action:** classify it. Ask:

> "You mentioned [X]. Is that a constraint — something imposed on you externally — or a choice you're making right now?"

Constraints get recorded. Choices get briefly explored (2-3 alternatives) and then either confirmed or replaced.

**Do not skip this.** The Path A test demonstrated that adopting specifics without classification produces shallow architectures. This is your most important continuous discipline.

### Periodic: Technique B (alternative framings)

Fire 2-3 times per session at natural convergence points:
1. After the initial framing stabilizes (typically turns 3-5)
2. When a major architectural direction emerges
3. Before you propose moving from DISCOVER to CHUNK

**Action:** present 3 framings of the entire problem:

> "Before we go further, let me offer three different ways to think about this problem:
>
> 1. [Current frame] — what we've been building toward
> 2. [Alternative frame] — reframes the problem as [X]
> 3. [Reductive frame] — what if the real problem is actually just [simpler thing]?"

**Critical:** option 3 must be a *qualitatively different, simpler* approach — not "a smaller version of option 1." The reductive frame fights complexity bias. The right answer might be a distributed system or a single shell script; you must explore the full complexity spectrum with equal rigor.

### Soft signals for "propose moving on"

Watch for:
- The same area has been revisited 3+ times without new information surfacing
- 10+ turns since a new theme emerged
- Operator's answers are getting short or repetitive
- You're asking questions whose answers don't change anything

When any signal fires, propose:

> "I think [area] is sufficiently explored. Want to go deeper, or should I move on to [next area / chunking]?"

The operator decides. You don't terminate unilaterally.

### What you track internally

Maintain a running summary in your own working memory:
- Confirmed constraints (with sources/reasons)
- Tested choices (with alternatives considered)
- Themes/concerns that have emerged
- Areas explored vs. not yet explored
- Soft-signal counters per area

You don't need to surface this summary every turn — but you can show it when proposing to move on, so the operator sees what you've captured.

### Anti-patterns

- ❌ **Asking compound questions.** "What's your scale and what's your tech stack?" — split into two questions.
- ❌ **Accepting specifics without classifying.** Every named technology, protocol, or pattern triggers Technique D.
- ❌ **Sycophantic summarization.** "Great choice!" "That makes sense!" — don't validate, classify.
- ❌ **Over-asking.** If you've explored an area and the answers are repetitive, propose moving on. Don't dig forever.
- ❌ **Skipping Technique B.** Without alternative framings, the conversation drifts toward the first frame that emerged. Fire B at convergence points.

[Phases 2-5 continue in subsequent sections — see Tasks 2.2 and 2.3]
````

- [ ] **Step 2: Verify file content**

```bash
wc -l /workspace/skills/discover/SKILL.md
head -20 /workspace/skills/discover/SKILL.md
```

Expected: ~120 lines so far. Frontmatter and Phase 1 visible.

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add skills/discover/SKILL.md
git commit -m "feat(discover): SKILL.md frontmatter + Phase 1 (DISCOVER)"
```

### Task 2.2: Append Phases 2, 3, 3.5 to SKILL.md

**Files:**
- Modify: `skills/discover/SKILL.md`

- [ ] **Step 1: Append phases 2 (CHUNK), 3 (RED-TEAM), and 3.5 (RESEARCH)**

Use the Edit tool to replace the placeholder line `[Phases 2-5 continue in subsequent sections — see Tasks 2.2 and 2.3]` with this content:

````markdown
## Phase 2: CHUNK

**Entry:** Discovery is complete. You have a refined problem statement, confirmed constraints, tested choices, and a sense of the problem's scope.

**Exit:** Chunk structure approved by operator (or "no chunking needed" approved).

### What you do in this phase

Read `references/chunking-guidelines.md` for full signals and examples.

**Step 1: assess.** Decide whether the problem needs chunking. Apply the guideline-based signals:

Signals for chunking:
- Multiple independent subsystems emerged
- Mixed tech domains
- More than ~3-5 distinct design decisions
- Natural dependency boundaries
- The operator signaled decomposition

Signals against chunking:
- Single domain, single concern
- Tight coupling — every part depends on every other part
- Small scope (fewer than ~3 distinct decisions)

**Step 2: if no chunking needed:** declare a single-chunk problem and move to Phase 3. The artifact will still be the full template; it'll just have one chunk section.

**Step 3: if chunking needed:** propose chunks.

For each chunk, define:
- Name (short, descriptive)
- Scope (2-3 sentences — what's in, what's out)
- Constraints (which top-level constraints apply, plus any chunk-specific ones)
- Open choices (what the executor will resolve)
- Dependencies (which other chunks this depends on, and *what specific decision/output* it needs from them)
- Recommended executor (usually `/superpowers:brainstorming`)

Then compute the execution order via topological sort. Note parallelism (which chunks at each level can run in parallel).

**Step 4: present the proposal:**

> "This looks like it should be N chunks. Here's how I'd split it:
>
> 1. **[Chunk name]** — [scope]. Dependencies: none.
> 2. **[Chunk name]** — [scope]. Dependencies: Chunk 1 (specifically: [what]).
> ...
>
> Execution order: 1, then 2 and 3 in parallel.
>
> Does this split make sense, or would you draw the lines differently?"

**Step 5: iterate** with the operator until they approve. They may merge chunks, split further, reorder, or rename.

### Anti-patterns

- ❌ **Chunking just because the problem looks complex.** Apply the signals. Tight coupling is a reason NOT to chunk.
- ❌ **Vague dependency annotations.** "Depends on Chunk 1" is not enough. Specify what's needed: "Depends on Chunk 1 (specifically: the API contract from the communication design)."
- ❌ **Forgetting parallelism.** Even when running sequentially in MVP, note which chunks could parallelize.

## Phase 3: RED-TEAM

**Entry:** Chunks are defined (or single chunk confirmed).

**Exit:** All CRITICAL findings addressed. Operator approves.

### What you do in this phase

Read `references/anti-sycophancy.md` for full Technique C protocol.

**Step 1: announce mode shift.** Tell the operator explicitly:

> "Switching to red-team mode. I'm going to try to break what we've concluded. For each finding I'll note severity: CRITICAL (must address before proceeding), DISCUSS (worth talking through), or MINOR (noting for awareness)."

**Step 2: systematically check** for each chunk (or the single problem):

1. Contradictions between chunks or between constraints
2. Untested specifics — assumptions not classified by Technique D
3. Missing concerns — auth, observability, error handling, cost, performance, deployment, testing, security, data lifecycle
4. Scope creep — chunks bigger than they need to be
5. Dependency gaps — would chunk N actually need information from chunk M that isn't captured?
6. Existence question — is there an existing tool? (shallow check; Phase 3.5 does the active research)
7. Stop-the-clock check — what would happen if we stopped here?

**Step 3: present findings as a numbered list** with severity per finding. Include reasoning. Examples:

> **Finding 1 [CRITICAL]:** Chunk 2 (Portal) depends on Chunk 1 (Communication model), but Chunk 1's "Open choices" doesn't include the API contract that Chunk 2 needs. If we run Chunk 1's /superpowers session and it doesn't surface the API contract, Chunk 2 will be blocked.
>
> **Finding 2 [DISCUSS]:** We classified "Azure" as a constraint but never asked about cost tier. If the team is on a free Azure tier, Container Apps may not be available. Worth confirming.
>
> **Finding 3 [MINOR]:** The chunking puts auth as part of Chunk 2 (Portal) rather than its own chunk. This is fine for MVP but if multiple chunks need auth, it'll be hard to factor out later.

**Step 4: operator addresses each finding:**
- **Accept** — modify the chunk to address the finding. Record the change.
- **Dismiss** — record the finding and the operator's reason. Future readers should see why this concern was raised and rejected.
- **Defer** — record as known issue for V2. Not in MVP scope.

**Step 5: exit when** all CRITICAL findings are Accepted (chunk modified) or Dismissed (with explicit reason). DISCUSS and MINOR findings are recorded regardless of action.

### Anti-patterns

- ❌ **Skipping the mode shift announcement.** The operator needs to know you're now adversarial, not collaborative.
- ❌ **Mild findings only.** If everything is MINOR, you're not actually red-teaming. Push harder. Find at least one DISCUSS or CRITICAL — if there genuinely isn't one, the framing is exceptionally clean (rare).
- ❌ **Letting CRITICAL findings be dismissed without specific reason.** "Operator said it's fine" isn't enough. Record what reason they gave.

## Phase 3.5: RESEARCH (build-vs-buy)

**Entry:** Red-team complete. Chunks pressure-tested.

**Exit:** All chunks classified for build-vs-buy. Operator approves classifications. Chunks restructured.

### What you do in this phase

Read `references/research-protocol.md` for full search strategy, evaluation criteria, and classification rules.

**Step 1: search per chunk.** For each chunk, run at least one targeted search using `WebSearch`. Construct queries from the chunk's problem statement and constraints. Refine if results are thin.

**Step 2: search the whole problem.** Run one additional overall search: "is there a tool that does this entire problem?" Sometimes the right answer is to skip all chunks and adopt one platform.

**Step 3: evaluate candidates.** For each candidate, use `WebFetch` (and context7 if it's a library) to evaluate against the criteria:
- Functionality match (%)
- License compatibility
- Cost
- Maintenance status
- Lock-in / dependency risk
- Integration burden

**Step 4: classify** each candidate into one of four buckets:
- **Adopt fully** — chunk is replaced with an integration chunk
- **Adopt partially** — chunk shrinks to cover the gap
- **Reject** — record candidate name and *specific* rejection reason
- **Inspire** — note as reference link, build custom

**Step 5: reverse sunk-cost check.** Before classifying any candidate as Reject, apply Technique D:

> "Is 'we want to build this ourselves' a constraint or a choice? If choice, what specific functional gaps or constraint conflicts make [tool name] unacceptable?"

If the operator can't articulate a specific reason, the rejection is suspect.

**Step 6: respect soft limits.** Per chunk, ~3-5 candidates max. Per session, ~30 minutes total research. Stop early when a clear winner emerges.

**Step 7: present findings** to operator and get approval per classification.

**Step 8: restructure chunks** based on adoptions:
- Adopt fully: replace the chunk with a much smaller integration chunk
- Adopt partially: shrink the chunk to cover only the gap
- Reject: chunk unchanged
- Inspire: chunk unchanged, note added

### Anti-patterns

- ❌ **One search, skim first result, declare "no good options."** Always evaluate at least 2-3 candidates against the criteria.
- ❌ **Vague rejection reasons.** "Doesn't fit our needs" is a placeholder. Specify what doesn't fit.
- ❌ **Skipping the reverse sunk-cost check.** When a candidate matches and operator says "let's build anyway," apply Technique D.
- ❌ **Pricing-page hand-waving.** Check actual pricing pages for paid candidates.
- ❌ **Researching forever.** Soft limits exist. After 3 candidates without a clear winner, move on.
````

- [ ] **Step 2: Verify the file**

```bash
wc -l /workspace/skills/discover/SKILL.md
grep -c "^## Phase" /workspace/skills/discover/SKILL.md
```

Expected: ~280 lines total. 4 `## Phase` headings (Phase 1, 2, 3, 3.5).

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add skills/discover/SKILL.md
git commit -m "feat(discover): SKILL.md phases 2, 3, 3.5"
```

### Task 2.3: Append Phases 4 and 5 to SKILL.md

**Files:**
- Modify: `skills/discover/SKILL.md`

- [ ] **Step 1: Append phases 4 (ARTIFACT) and 5 (DISPATCH) to the end of SKILL.md**

Use the Edit tool to append (after the last line of Phase 3.5):

````markdown

## Phase 4: ARTIFACT

**Entry:** Red-team complete, research done, chunks finalized.

**Exit:** Artifact written to `docs/discovery/<topic>.md` and committed.

### What you do in this phase

Read `references/artifact-template.md` for the full template and section guidance.

**Step 1: choose a topic slug.** Derive a kebab-case identifier from the refined problem statement. Examples: `team-agent-platform`, `auth-redesign`, `cart-graphql-migration`. Confirm with operator if ambiguous.

**Step 2: write the artifact.** Use the template from `references/artifact-template.md`. Fill in every section:

- Header (date, status, chunk count)
- Execution order (with parallelism notes)
- Framing (refined statement + original + key reframes)
- Confirmed constraints
- Tested choices
- Each chunk (with self-contained problem statement, constraints, open choices, dependencies, recommended executor)
- Red-team findings (addressed, accepted risks, dismissed)
- Research outcomes (per chunk and overall)
- Discovery log (collapsed `<details>` block — only key exchanges)

**Step 3: review for self-containment.** Each chunk's problem statement must be self-contained. Test mentally: if you copied that section alone into a fresh /superpowers session, would the executor have enough? If not, expand it before saving.

**Step 4: write to file** at `docs/discovery/<topic-slug>.md`. Create the `docs/discovery/` directory if it doesn't exist.

**Step 5: commit:**

```bash
git add docs/discovery/<topic-slug>.md
git commit -m "docs(discovery): add discovery artifact for <topic>"
```

**Step 6: tell the operator** the artifact is written, with the file path. Ask if they want to review it before dispatch.

### Anti-patterns

- ❌ **Skipping sections that "don't apply."** Write `None` instead of deleting. Consistency matters.
- ❌ **Pasting full transcripts into the discovery log.** Only key exchanges that shaped the framing. Keep it tight.
- ❌ **Forgetting to commit.** The artifact is the durable output. Always commit.

## Phase 5: DISPATCH

**Entry:** Artifact committed. Operator approved or skipped review.

**Exit:** All chunks have been through /superpowers (or operator stops dispatch).

### What you do in this phase

Read `references/dispatch-protocol.md` for full sequential dispatch logic, prompt composition, and decision extraction.

**Step 1: announce dispatch.** Tell the operator:

> "Dispatching N chunks in execution order. I'll launch chunk 1 first; you'll interact with /superpowers normally. When that chunk completes, I'll capture the key decisions and feed them forward to chunk 2."

**Step 2: for each chunk in execution order:**

a. **Compose the dispatch prompt.** Combine:
- The chunk's problem statement (verbatim from artifact)
- A "## Constraints (do not re-open)" section with all top-level constraints + chunk-specific constraints
- The chunk's "Open choices (for the executor to resolve)" section
- An "## Upstream decisions (from completed chunks)" section IF this chunk has dependencies — populated from the prior chunks' /superpowers outputs

b. **Launch via Agent tool:**
- `subagent_type`: `general-purpose`
- `description`: `"Plan chunk <N>: <chunk name>"`
- `prompt`: the composed prompt
- `run_in_background`: `false` (operator must interact)

c. **Wait for completion.** The operator drives the /superpowers session. The agent returns when /superpowers' brainstorm + writing-plans sub-flow finishes.

d. **Extract decisions.** Read the design doc and plan that /superpowers produced (in `docs/superpowers/specs/` and `docs/superpowers/plans/`). Summarize key decisions for downstream chunks: architecture choices, tech stack, API contracts, data models. Format into a "## Upstream decisions" section ready to feed into the next dependent chunk.

e. **Update the artifact.** Add a link to the chunk's design doc and plan in the chunk's section. Optionally add a "Decisions made" subsection. Commit the artifact update.

f. **Move to the next chunk** in execution order.

**Step 3: when all chunks are complete,** tell the operator:

> "All N chunks dispatched. Each chunk has a design doc and an implementation plan. The discovery artifact has been updated with links. The operator can now run /superpowers:executing-plans (or subagent-driven-development) on each plan independently."

### Handling chunking-was-wrong

If during a chunk's /superpowers session, the operator discovers that the chunking is wrong (e.g., "we can't design Chunk 2 because Chunk 1's constraints are wrong" or "chunks 2 and 3 should have been one chunk"):

1. The operator interrupts /superpowers (just stops the session and tells you).
2. You stop the dispatch loop.
3. The operator updates the discovery artifact: revise chunks, dependencies, execution order. Add a "Revisions" section noting what changed and why.
4. You resume dispatch from the affected chunk. Earlier chunks that already completed don't re-run unless the operator explicitly says so.

This is operator-driven. Don't auto-resume.

### Handling skip

If, mid-dispatch, the operator says "skip this chunk":
1. Mark in artifact: `Status: skipped — <reason>`
2. Don't dispatch
3. Re-evaluate downstream chunks: do they still depend on this chunk's outputs? If so, what's the new plan?

### Anti-patterns

- ❌ **Backgrounding /superpowers.** It's interactive — operator must interact. Always foreground.
- ❌ **Running in a worktree.** /superpowers' artifacts need to be in the main tree.
- ❌ **Forgetting to feed upstream decisions.** Each dependent chunk needs prior chunks' decisions or it'll re-litigate.
- ❌ **Auto-resuming after a chunking-was-wrong revision.** Revisions are operator-driven. Don't automate around their control.

---

## Closing

When all phases complete and dispatch is done, the operator has:
- A committed discovery artifact at `docs/discovery/<topic>.md`
- Per-chunk design docs and implementation plans (produced by /superpowers)
- A clear hand-off point: each plan can be executed independently

Your job is done. /superpowers and its execution sub-skills handle the rest.
````

- [ ] **Step 2: Verify the file is complete**

```bash
wc -l /workspace/skills/discover/SKILL.md
grep -c "^## Phase" /workspace/skills/discover/SKILL.md
tail -20 /workspace/skills/discover/SKILL.md
```

Expected: ~440 lines. 6 `## Phase` headings (1, 2, 3, 3.5, 4, 5). Last line is the closing.

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add skills/discover/SKILL.md
git commit -m "feat(discover): SKILL.md phases 4 (ARTIFACT) and 5 (DISPATCH)"
```

### Task 2.4: Cross-link review

**Files:**
- Modify: `skills/discover/SKILL.md` (only if cross-link issues found)

- [ ] **Step 1: Verify all reference files exist and are linked from SKILL.md**

```bash
ls /workspace/skills/discover/references/
grep "references/" /workspace/skills/discover/SKILL.md
```

Expected: 5 reference files in the directory. SKILL.md references each at least once.

- [ ] **Step 2: Verify naming consistency**

Check that the SKILL.md uses consistent terminology with reference files:

```bash
# Phase names should match
grep -E "Phase (1|2|3|3.5|4|5)" /workspace/skills/discover/SKILL.md | head -20

# Technique letters should be consistent
grep -E "Technique [BCD]" /workspace/skills/discover/SKILL.md | head -20
grep -E "Technique [BCD]" /workspace/skills/discover/references/anti-sycophancy.md | head -10
```

Expected: phase numbering and technique letters match across files.

- [ ] **Step 3: If issues found, fix inline and commit. If no issues, no commit needed for this task.**

---

## Phase 3 — Skill-creator validation (Level 1 evals)

This phase uses the `skill-creator` skill to write and run eval cases. The evals check whether the discover skill's behaviors fire on representative test prompts.

### Task 3.1: Author eval cases via skill-creator

**Files:**
- Create: `skills/discover/evals/cases.md` (path may vary based on skill-creator's conventions)

- [ ] **Step 1: Invoke skill-creator with eval-authoring intent**

In the executing session, invoke the skill-creator skill:

```
Skill: skill-creator
Args: Write eval cases for the /discover skill at skills/discover/SKILL.md.
The eval cases should test whether expected behaviors fire on
representative prompts. Test cases needed:

1. Prompt: "I want to deploy agents for my team that can communicate"
   Expected:
   - Technique D fires on any specifics that surface
   - At least 5 of 8 expected items explored (see test cases doc)
   - Research phase surfaces AutoGen / LangGraph / Claude Agent SDK as candidates

2. Prompt: "Build me a todo app"
   Expected:
   - Full discovery + red-team runs
   - No chunking proposed (single-chunk problem)
   - Single-chunk artifact produced
   - Research phase surfaces existing todo apps; at least one Adopt or Inspire

3. Prompt: "We need a platform with auth, billing, a marketplace, and analytics"
   Expected:
   - Chunking proposed within first ~5 turns
   - At least 3 chunks identified
   - Research phase surfaces Auth0/Clerk for auth, Stripe for billing
   - At least one Adopt or Adopt-partially classification

4. Prompt: "Build a REST API using Express with Postgres and deploy to AWS ECS"
   Expected:
   - Technique D challenges at least 2 specifics as choices-vs-constraints
   - Technique B offers a simpler reframing (option 3, reductive)
   - Research phase considers managed alternatives (Supabase, Render, Railway)
```

- [ ] **Step 2: Save the eval cases**

The skill-creator should produce eval case files. Confirm the location and content:

```bash
find /workspace/skills/discover -name "evals" -o -name "cases*"
ls /workspace/skills/discover/evals/ 2>/dev/null
```

- [ ] **Step 3: Review the eval cases for completeness**

Read each generated eval case. Confirm:
- Each test prompt is verbatim
- Each "expected behavior" is checkable (not vague — e.g., "Technique D fires" should specify what observable output indicates that)
- The grading rubric is explicit (pass/fail criteria per behavior)

If a case is vague, return to skill-creator and request refinement.

- [ ] **Step 4: Commit eval cases**

```bash
cd /workspace
git add skills/discover/evals/
git commit -m "feat(discover): eval cases via skill-creator"
```

### Task 3.2: Run evals and inspect results

**Files:**
- Create: `skills/discover/evals/results-<date>.md` (or skill-creator's convention)

- [ ] **Step 1: Invoke skill-creator's eval-running capability**

```
Skill: skill-creator
Args: Run the eval cases at skills/discover/evals/ against the
/discover skill at skills/discover/SKILL.md. Capture results per
case and produce a pass/fail summary.
```

- [ ] **Step 2: Inspect the results**

Read the generated results. For each case:
- Did each expected behavior fire? Pass/fail per behavior.
- For failures, what did the skill do instead? Diagnose: prompt issue, missing reference content, ambiguous instruction.

- [ ] **Step 3: If any case fails, plan iteration**

Note specific failures and what needs to change in SKILL.md or references. Don't iterate yet — collect all failures first.

- [ ] **Step 4: Commit results**

```bash
cd /workspace
git add skills/discover/evals/
git commit -m "test(discover): initial eval run results"
```

### Task 3.3: Iterate on the skill until evals pass

**Files:**
- Modify: `skills/discover/SKILL.md` and/or `skills/discover/references/*.md`

- [ ] **Step 1: For each failed eval case, identify the root cause**

Common patterns:
- Technique D didn't fire: prompt section for Phase 1 may be too soft about classifying specifics; strengthen the language.
- Technique B's reductive frame is weak: examples in `anti-sycophancy.md` may need more weight on what makes a reductive frame "qualitatively different."
- Chunking missed: the signals in `chunking-guidelines.md` may need re-ordering or a stronger trigger phrase.
- Research phase shallow: the soft limits may be too aggressive; the search strategy may need more concrete query templates.

- [ ] **Step 2: Make targeted edits**

Use the Edit tool to revise the relevant section. Keep edits minimal — small changes are easier to assess.

- [ ] **Step 3: Re-run evals**

```
Skill: skill-creator
Args: Re-run eval cases at skills/discover/evals/ against the updated
SKILL.md. Compare results to the prior run.
```

- [ ] **Step 4: Repeat steps 1-3 until all eval cases pass**

There is no fixed iteration count. The criterion is: all eval cases pass. If after 3 iteration cycles a case is still failing, escalate to the operator — the eval case may be wrong, or the skill may have a structural problem requiring re-design.

- [ ] **Step 5: Commit the final passing version**

```bash
cd /workspace
git add skills/discover/
git commit -m "test(discover): all Level 1 eval cases passing"
```

---

## Phase 4 — Path B validation (Level 2)

Manual validation against the Path A baseline at `/test-1/transcript.md`.

### Task 4.1: Set up clean-room session

**Files:**
- Read: `/test-1/transcript.md` (Path A reference, do not study before running)

- [ ] **Step 1: Verify the operator is the same person who ran Path A**

The operator running this validation needs to be the same person who ran Path A on 2026-04-24, OR a different trusted person. If different, that's the cleanest run.

- [ ] **Step 2: Wait for adequate time gap from Path A**

Per `docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md`: ideally 24+ hours since Path A. The operator should not have been actively rehearsing Path A's questions in the meantime.

- [ ] **Step 3: Open a fresh Claude Code session**

- New session, no `/continue` or `/compact` of any prior work
- Fresh shell, no memory files referencing Path A results

- [ ] **Step 4: Confirm clean-room readiness**

Operator self-check:
- Have you re-read the test cases doc's "expected to surface" list recently? (If yes, that contaminates — wait longer.)
- Do you remember what /superpowers asked you in Path A? (If too vivid, wait longer.)

If contamination is too high, postpone the run. Don't force it.

### Task 4.2: Run /discover on Test 1 prompt

**Files:**
- Create: `docs/superpowers/specs/path-b-results/test-1-low.md` (transcript + artifact location)
- Create: `docs/discovery/team-agents.md` (or similar slug — the artifact /discover writes)

- [ ] **Step 1: Paste the Test 1 prompt verbatim**

```
I want to deploy agents that are available for my entire team and the agents can communicate with each other.
```

Nothing else. No preamble. No "I'm testing something."

- [ ] **Step 2: Invoke `/discover`**

The skill should auto-trigger on this kind of vague prompt. If it doesn't, explicitly invoke `/discover`.

- [ ] **Step 3: Run the skill to completion**

Answer questions only as asked. Don't volunteer information from your memory of Path A. Let all five phases run: DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, then enter DISPATCH but stop before actually running /superpowers (we want to score the discovery itself, not the downstream plans).

- [ ] **Step 4: Save the full transcript**

Before closing the session, save the conversation transcript to `docs/superpowers/specs/path-b-results/test-1-low.md`. Include every turn — operator and skill — verbatim. This was the protocol gap in Path A; do NOT repeat it.

- [ ] **Step 5: Save the discovery artifact**

The skill should have written `docs/discovery/<slug>.md` during Phase 4. Verify it exists and contains the full template.

- [ ] **Step 6: Commit**

```bash
cd /workspace
git add docs/superpowers/specs/path-b-results/ docs/discovery/
git commit -m "test(discover): Path B Test 1 transcript + artifact"
```

### Task 4.3: Score Path B against Path A

**Files:**
- Modify: `docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md` (append scoring)

- [ ] **Step 1: Score Coverage (1-5)**

Read the Path B transcript. For each item in the Test 1 "expected to surface" list (from the test cases doc), check:
- Was it surfaced as a question by the skill?
- Was it volunteered by the operator?
- Was it not surfaced at all?

Count items surfaced as questions (not volunteered). Convert to 1-5 score:
- 1: 0-1 of 8 items surfaced
- 2: 2-3 of 8 items
- 3: 4-5 of 8 items
- 4: 6-7 of 8 items
- 5: all 8 items

Path A scored 2 (3 of 8). Path B must score at least 3 to pass.

- [ ] **Step 2: Score Correctness of Frame (1-5)**

Operator self-judgment: looking at the discovery artifact, would you actually proceed with this framing? Is the chunk structure the one you'd choose if forced to pick? Score:
- 1: would not ship; framing is wrong
- 3: would ship with reservations
- 5: would ship confidently

Path A's plan was deployable but overkill (operator's note: "would likely be deployable. However I suspect it would also miss critical things or it would be overkill"). Estimate Path A as 3. Path B must score at least 4 to pass.

- [ ] **Step 3: Pass criterion**

Path B passes Test 1 if **both** Coverage and Correctness of Frame score at least +1 vs. Path A.

- [ ] **Step 4: Append scoring to test cases doc**

Add a "Path B results (Test 1)" section to `docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md` with:
- Coverage score and reasoning (per-item check)
- Correctness of Frame score and operator reasoning
- Operator cost (turns, typing, wall-clock) for tracking
- Pass/fail vs. pass criterion

- [ ] **Step 5: Commit**

```bash
cd /workspace
git add docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md
git commit -m "test(discover): Path B Test 1 scored against Path A baseline"
```

### Task 4.4: If Path B fails Test 1, decide next steps

- [ ] **Step 1: If Path B passes, skip this task**

If Path B beats Path A on both axes per Step 3 above, this task is a no-op. Move to Phase 5.

- [ ] **Step 2: If Path B fails, root-cause**

Common failure modes:
- Coverage low: skill isn't asking enough discovery questions. Likely Phase 1 prompt is too soft or Technique B isn't firing enough.
- Correctness low: skill is asking the right things but landing on a wrong frame. Likely Technique B's reductive frame is weak, or Phase 3 (red-team) didn't catch the issue.

- [ ] **Step 3: Decide path forward**

Option A: iterate on the skill (return to Phase 3 of this plan, modify SKILL.md/references, re-run evals + Path B).

Option B: declare MVP not ready, escalate to operator. The decision memo's §9 says scope creep is grounds for "do not ship." If Path B can't beat Path A even after iteration, the tool needs more design work, not more polish.

The operator decides between A and B. If A, return to Task 3.3 and iterate.

---

## Phase 5 — Additional real-problem validation (Level 3)

Per memo §7: 2 more real problems, different domains, run through both paths. Pass = Path B wins in at least 2 of 3 total cases (counting Test 1).

### Task 5.1: Pick problems 2 and 3

- [ ] **Step 1: Operator selects two real problems**

Criteria:
- Different domain from Test 1 (which is platform/infra)
- Real — something the operator has actually wanted to solve
- Different from each other (e.g., one frontend-heavy, one data-heavy)

Examples (operator chooses):
- "I want to add real-time collaboration to my note-taking app"
- "We need to migrate our analytics from Mixpanel to a custom solution"
- "Build a tool that watches my git repo and auto-summarizes changes for the team"

- [ ] **Step 2: Document the problems**

Append the two chosen problems to `docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md` under a new "Test 2 (real problem)" and "Test 3 (real problem)" section. Include the verbatim prompt for each, plus an "expected to surface" list (from the operator's own knowledge of the problem).

- [ ] **Step 3: Commit**

```bash
cd /workspace
git add docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md
git commit -m "test(discover): pick problems 2 and 3 for additional validation"
```

### Task 5.2: Run Path A and Path B for problem 2

- [ ] **Step 1: Path A (baseline) — run /superpowers alone on problem 2's prompt**

Same protocol as Path A in `docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md`. Save transcript + plan to `docs/superpowers/specs/path-a-results/test-2.md`.

- [ ] **Step 2: Path B — run /discover on problem 2's prompt**

Clean-room protocol per Task 4.1-4.2. Save transcript + artifact.

- [ ] **Step 3: Score and commit**

Score Coverage and Correctness of Frame per Task 4.3. Append to test cases doc.

```bash
cd /workspace
git add docs/superpowers/specs/path-a-results/ docs/superpowers/specs/path-b-results/ docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md
git commit -m "test(discover): Path A + Path B for problem 2, scored"
```

### Task 5.3: Run Path A and Path B for problem 3

- [ ] **Step 1: Repeat Task 5.2 for problem 3**

Same steps. Save to `test-3.md` files.

- [ ] **Step 2: Compute aggregate pass criterion**

Path B passes Level 3 validation if it wins (Coverage +1, Correctness +1) in **at least 2 of 3 tests** (Test 1, Problem 2, Problem 3).

- [ ] **Step 3: Append summary to test cases doc**

Add an "Aggregate validation result" section: pass/fail with per-test scores side by side.

- [ ] **Step 4: Commit**

```bash
cd /workspace
git add docs/superpowers/specs/
git commit -m "test(discover): aggregate Level 3 validation result"
```

### Task 5.4: If aggregate fails, decide next steps

- [ ] **Step 1: If passing (≥2 of 3), skip this task**

- [ ] **Step 2: If failing, decide:**

Per memo §9: "Do not proceed if scope expands beyond §6." If iteration is needed, it must stay within scope. If failure suggests structural redesign, escalate to operator before continuing.

---

## Phase 6 — Description optimization

After validation, use skill-creator to optimize the description for triggering accuracy.

### Task 6.1: Benchmark current triggering accuracy

- [ ] **Step 1: Invoke skill-creator's benchmark capability**

```
Skill: skill-creator
Args: Benchmark the description triggering accuracy of the /discover skill
at skills/discover/SKILL.md. Use a mix of prompts that should trigger
the skill (vague problem statements, ambitious goals) and prompts that
should NOT trigger it (well-scoped specific bug fixes, simple questions).
Report false-positive and false-negative rates.
```

- [ ] **Step 2: Review the benchmark report**

The report should show:
- True positives (skill triggered when it should)
- False positives (skill triggered when it shouldn't)
- True negatives (skill didn't trigger when it shouldn't)
- False negatives (skill didn't trigger when it should)

- [ ] **Step 3: Save benchmark results**

```bash
cd /workspace
git add skills/discover/benchmarks/ 2>/dev/null || true
git commit -m "test(discover): description triggering benchmark (initial)" 2>/dev/null || true
```

### Task 6.2: Apply skill-creator's optimization

- [ ] **Step 1: Invoke skill-creator's description-optimization capability**

```
Skill: skill-creator
Args: Optimize the description and when_to_use fields in
skills/discover/SKILL.md based on the benchmark results. Iterate until
true-positive rate is >85% and false-positive rate is <10%.
```

- [ ] **Step 2: Review the proposed description changes**

Skill-creator will propose new wording. Verify:
- Description still accurately describes what the skill does
- when_to_use captures the trigger conditions clearly
- No misleading claims or scope creep

If the proposal is acceptable, apply it. If not, iterate with skill-creator.

- [ ] **Step 3: Re-benchmark to confirm improvement**

Re-run Task 6.1's benchmark. Confirm metrics improved.

- [ ] **Step 4: Commit**

```bash
cd /workspace
git add skills/discover/SKILL.md skills/discover/benchmarks/ 2>/dev/null || true
git commit -m "perf(discover): optimize description for triggering accuracy"
```

---

## Phase 7 — Wrap

### Task 7.1: Spec coverage self-check

**Files:**
- Read: `docs/superpowers/specs/2026-04-24-discover-skill-design.md`
- Read: all of `skills/discover/`

- [ ] **Step 1: Open the spec and the skill side by side**

For each section of the spec, confirm a corresponding implementation exists:

- [ ] Goal — covered by skill purpose
- [ ] Non-goals — confirmed; nothing the skill does crosses these lines
- [ ] File layout — directory matches spec
- [ ] SKILL.md frontmatter — present and correct
- [ ] Phase 1 (DISCOVER) — present, includes Technique D continuous + Technique B at convergence points
- [ ] Phase 2 (CHUNK) — present, references chunking guidelines
- [ ] Phase 3 (RED-TEAM) — present, references anti-sycophancy
- [ ] Phase 3.5 (RESEARCH) — present, references research-protocol
- [ ] Phase 4 (ARTIFACT) — present, references artifact-template
- [ ] Phase 5 (DISPATCH) — present, references dispatch-protocol
- [ ] Anti-sycophancy techniques (B, C, D) — fully documented in references/anti-sycophancy.md
- [ ] Chunking guidelines — fully documented in references/chunking-guidelines.md
- [ ] Artifact template — fully documented in references/artifact-template.md
- [ ] Dispatch protocol — fully documented in references/dispatch-protocol.md
- [ ] Research protocol — fully documented in references/research-protocol.md
- [ ] Testing levels — Level 1 (evals) done in Phase 3; Level 2 (Path B) done in Phase 4; Level 3 (additional problems) done in Phase 5

- [ ] **Step 2: List any gaps**

If anything is missing, return to the relevant phase of this plan and complete it. Do not proceed to release if gaps exist.

### Task 7.2: Final commit and release readiness

- [ ] **Step 1: Verify no uncommitted changes**

```bash
cd /workspace
git status
```

Expected: clean tree.

- [ ] **Step 2: Tag the release**

```bash
git tag -a discover-mvp-v1 -m "Discover skill MVP — validated against Path A baseline"
```

- [ ] **Step 3: Inform operator**

Summarize:
- Skill is at `skills/discover/`
- Discovery artifacts go to `docs/discovery/`
- Validation status: Level 1 evals passing, Level 2 Path B beat Path A, Level 3 aggregate pass rate
- Next steps: use the skill on real problems; gather feedback; iterate based on usage

---

## Wrap verification

Final checks before declaring MVP complete:

1. `ls /workspace/skills/discover/` shows `SKILL.md` and `references/` with 5 files inside.
2. `git log --oneline -20` shows the implementation history with commits for each task.
3. The skill is invocable: `/discover <problem statement>` triggers Phase 1.
4. `docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md` has Path B results and an aggregate pass result.
5. The decision memo's §9 conditions are all satisfied (validation done, no scope creep, anti-sycophancy not deferred).

Plan complete and saved to `docs/superpowers/plans/2026-04-24-discover-skill.md`.
