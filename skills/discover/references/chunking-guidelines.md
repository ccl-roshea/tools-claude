# Chunking Guidelines

> Phase names (DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the chunking heuristics only.

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

The operator is already chunking mentally. The skill should formalize the split.

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

Push back gently. Apply Technique B's no-build (or low-build) frame: is there a simpler solve that wouldn't need chunking? If the operator confirms they want chunks, propose them. The operator has final say.

## Chunk-overload signals (mandatory check)

After proposing chunks (and before iterating with the operator to approve), the agent MUST check each chunk against four overload signals:

1. **Open-choice density:** the chunk's "Open choices" list has 3+ independent items.
2. **Lingering vagueness:** the chunk's problem statement still feels vague or multi-faceted when read aloud.
3. **Sub-domain spread:** the chunk spans multiple sub-domains.
4. **Red-team flag:** the agent's own draft red-team thinking flags the chunk as scope-creep-prone or with unresolved untested specifics.

If 2 or more signals fire on a chunk, the agent MUST propose a sub-decomposition in-line, before iterating with the operator. The operator may override; the override is recorded in the artifact as a one-liner under that chunk's section.

If 0-1 signals fire on a chunk, the agent does not surface the check — proceed silently. Don't ask "should we split?" on chunks that look fine; that's operator fatigue.

This check happens at end of CHUNK phase, not at dispatch. By the time DISPATCH runs, any chunk that tripped 2+ signals has either been split or has an explicit override on record.

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
