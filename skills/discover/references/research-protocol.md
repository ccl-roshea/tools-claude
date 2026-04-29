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
