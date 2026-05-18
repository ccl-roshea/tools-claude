# Research Protocol (Build-vs-Buy)

> Phase names (SHAPE-DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the research protocol only.

Phase 3 of the skill. After RED-TEAM (Phase 2) and before ARTIFACT (Phase 4), actively research existing tools that might satisfy chunks. Replaces training-data intuition with current web evidence.

`/discover` runs a *shallow* existence check during its own RED-TEAM (see `../../discover/references/research-protocol.md` for that scope); this protocol is the *rigorous* per-chunk and whole-problem build-vs-buy evaluation, with candidate scoring, classification, the reverse sunk-cost check, and soft session limits. The two protocols are deliberately separated: shallow scouting is part of pressure-testing outcomes; rigorous evaluation requires the chunks and shape decisions that only `/solution` produces.

## Why this phase exists

Phase 2 RED-TEAM's existence-question check (per `../SKILL.md` Phase 2 list, check 7) asks "is there an existing tool?" using only the LLM's training data. Training data has cutoff issues and recency problems. The LLM also tends to reject existing tools without rigorous evaluation. The Path A test (May baseline) demonstrated this: AutoGen, LangGraph, Microsoft Agent Framework, and Claude Agent SDK were all named, then all rejected in favor of build-it-yourself, with no actual evaluation.

This phase replaces "I think there might be a tool" with "I searched, evaluated three candidates, and recorded specific functional gaps or constraint conflicts for each rejection." The output is a per-chunk and whole-problem evaluation that the operator can audit and that downstream `/superpowers` sessions inherit.

## Search strategy

### Per-chunk search

For each chunk in the solution artifact's `## Chunks` section, run at least one targeted search. The query is constructed from the chunk's `Problem statement` and `Inherited constraints`. Examples:

- Chunk: "Auth for a B2B SaaS app, multi-tenant, SSO required"
  Query: `"multi-tenant SSO auth provider B2B SaaS"` and follow-ups for top results

- Chunk: "Background job runner with retry and observability"
  Query: `"background job queue Python retry observability"`

- Chunk: "Real-time collaboration cursor + presence"
  Query: `"real-time collaboration cursor presence library"`

If a chunk genuinely has no obvious tooling category (a small custom integration step, a one-off data migration), the search may produce zero candidates after refinement — record that result and move on. Not every chunk requires research; trivial chunks may skip with a one-line note (per `solution-artifact-template.md`'s Research outcomes section).

### Whole-problem search

In addition to per-chunk searches, run one **whole-problem search**. Sometimes the right answer is to skip all chunks and adopt one platform. Example:

- Problem: "I want a team agent platform"
  Query: `"team agent platform Claude" OR "multi-agent framework"` — surfaces AutoGen, LangGraph, Claude Agent SDK, etc.

If the whole-problem search finds a strong match, propose adopting it across multiple chunks. The chunk structure may collapse — multiple chunks merge into a single integration chunk, or the entire solution becomes a single "evaluate, install, configure" chunk. Record the collapse under the artifact's `## Research outcomes (build-vs-buy)` → `### Whole problem` subsection.

### Tools to use

- **WebSearch** — primary discovery. Use for finding candidates.
- **WebFetch** — fetch specific pages (homepage, pricing, docs) to evaluate candidates.
- **`mcp__plugin_context7_context7__resolve-library-id`** + **`mcp__plugin_context7_context7__query-docs`** — when evaluating a specific library, get current authoritative docs.

### When search results look thin

If the first search returns weak results:
1. Refine the query — add domain terms, remove specifics that may be too narrow.
2. Try alternative framings — "tool" vs. "library" vs. "framework" vs. "service".
3. Search for the *category* — "what are the leading X solutions in 2026?"

If after 2-3 refinements still no good candidates: that's a real signal there's no obvious existing tool. Record "no candidates after 3 refinements" under the chunk's research section and move on. Don't search forever.

## Evaluation criteria

For each candidate, evaluate against ALL six criteria. These are the criteria the solution artifact's `## Research outcomes (build-vs-buy)` section records and the gate (G2 if the eventual decision is `[Tested-shape] integrate <tool>`) checks rejection-reason quality against.

### 1. Functionality match (%)

What percentage of the chunk's requirements does this candidate cover? Be specific — list what it does and what it doesn't. Don't round up. A candidate at 70% functionality match with the remaining 30% being a small custom extension is different from a candidate at 70% where the remaining 30% means redesigning the data model — both are "70%" but the integration cost is wildly different.

### 2. License compatibility

- Open source license — MIT/Apache/BSD are usually fine, GPL/AGPL may have implications.
- Commercial — pricing model, lock-in clauses.
- Patent grants and contributor terms.
- Compatibility with the operator's company policies (note as a constraint to verify if unknown). If unknown, record as `license: <name>; compliance check pending` rather than asserting compatibility.

### 3. Cost

- Free? Paid? Freemium?
- If paid: pricing model (per-user, per-request, per-MB, flat).
- For freemium: where does the free tier end? Is the free tier sustainable for the operator's expected scale?
- Include hidden costs: hosting if self-hosted, training time, integration burden, operational overhead (paging, on-call, runbook authoring).

### 4. Maintenance status

- Last release date.
- Open issues, PR turnaround.
- Contributor activity (single maintainer? Active community?).
- Recent breaking changes.
- Clear roadmap?

A tool with active maintenance is much more valuable than one with marginally better functionality but stale maintenance. A tool with no commits in 18 months and a single inactive maintainer is a future migration problem regardless of today's functionality match.

### 5. Lock-in / dependency risk

- How hard is it to swap out later?
- Does it require significant rewrites of *your* code to integrate?
- Are there standard interfaces (e.g., OAuth, S3 API, OpenAPI) that make replacement easier?
- Is the tool itself dependent on a single vendor that could disappear?
- Does it require data to flow through a third party, and is that compatible with the operator's data-handling constraints?

### 6. Integration burden

- Auth requirements (API keys, OAuth, mTLS).
- Data format expectations.
- Runtime requirements (Python version, Docker, K8s).
- Network/firewall implications.
- Documentation quality.
- SDK availability in the operator's target language.

## Classification

Each candidate is classified into exactly one of four buckets. The classification drives whether and how the chunk changes.

### Adopt fully

The candidate covers the entire chunk's scope. The chunk is *replaced* with a much smaller "evaluate, install, configure, integrate" chunk. The original build-from-scratch chunk is deleted (or, more precisely, rewritten — its `Problem statement` changes to the integration scope; its `Open choices` shrink to the configuration knobs that remain).

Example: chunk was "build OAuth provider"; candidate is Auth0; chunk becomes "integrate Auth0 — set up tenant, configure callbacks, wire to app."

### Adopt partially

The candidate covers part of the chunk's scope. The chunk *shrinks* to cover only the gap. The artifact records what the existing tool covers vs. what's still being built.

Example: chunk was "build agent orchestration"; candidate is LangGraph; chunk becomes "build agent orchestration on top of LangGraph (using LangGraph for state machine and tool routing; building custom: persistence layer, multi-tenancy, billing-aware rate limiting)."

### Reject

The candidate doesn't fit. The candidate's name, version, and rejection reason are recorded in the artifact. **This is important** — future readers should see which alternatives were considered and why they were rejected. Without this, every future engineer will re-ask the same question.

Reasons should be specific:
- "Auth0 free tier ends at 7,500 users; we need to support 50k+ at MVP."
- "Temporal requires running a separate cluster; ops budget doesn't allow."
- "AutoGen is Python-only; our backend is TypeScript."

Vague reasons are red flags: "doesn't fit our needs" is not a rejection reason — it's a placeholder. If the artifact ends up recording a `[Tested-shape] build custom` decision with the rejection reason as the alternatives column, Phase 4 G2 (tested-shape alternatives) will reject the placeholder.

### Inspire

Don't adopt, but the candidate has architecture or interface ideas worth borrowing. Note as a reference link in the chunk's `Notes` field for the executor. The chunk still builds custom, but the executor has prior art to consult.

## Reverse sunk-cost check

Before classifying any candidate as Reject — particularly when the operator's stated preference is "build it ourselves" — apply Tech-D's verifiability rule to that preference. The full statement of the check (and the broader verifiability framing that PR 1 introduced — externally-sourced rejection vs. preference needing specific gaps) lives in `../../shared/anti-sycophancy.md` under the "Reverse sunk-cost check" subsection. Inline form for use in /solution's RESEARCH:

> "Is 'we want to build this ourselves' externally sourced — a mandate, contract, regulator requirement, or factual constraint that prevents adopting [tool name]? If yes, cite the source and we record the rejection. If no, this is a preference — the bar for rejecting [tool name] must be specific functional gaps or constraint conflicts (pricing, lock-in, integration burden, license), not preference itself."

If the operator can cite an external source (a contract clause that forbids the third-party tool, a regulator control that requires self-hosting, a deployed-system constraint, a prior empirical result), record the rejection with the citation. The citation flows into the solution artifact's research section as `Reason for classification: <category citation> — <text>`.

Otherwise the operator must articulate specific functional gaps or constraint conflicts; without either, the rejection is suspect — find a real reason or reconsider Adopt / Adopt partially. The verifiability rule applies symmetrically: the same standard that prevents shapes from masquerading as constraints during SHAPE-DISCOVER prevents preferences from masquerading as constraints during RESEARCH.

If the operator pushes back ("we want to build it; that's enough"), the check is doing its job — surface the asymmetry to the operator explicitly, record the operator's response under the chunk's research section, and continue. The protocol does not override the operator; it surfaces the question.

## Soft limits

Don't research forever:

- **Per chunk:** evaluate ~3-5 candidates. After that, classify the rest as Reject (not evaluated, no obvious fit) and move on. The marginal value of the 6th candidate is small; the cost in operator attention is high.
- **Per session:** ~30 minutes of research total. Beyond that, the operator should call it — either there's no clear winner (commit to build with the recorded losers) or there's a clear winner and the remaining minutes are gold-plating.
- **Stop early when:** a clear winner emerges (Adopt fully) — don't keep evaluating just for completeness. Record the runners-up briefly so future readers see what else was looked at, then move on.

## Output format

Findings get folded into the solution artifact in Phase 4. Each finding is recorded per chunk under `## Research outcomes (build-vs-buy)` → `### Per chunk`, in the format defined in `references/solution-artifact-template.md`:

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
- **Outcome:** <chunk modified to ... | chunk eliminated | chunk replaced with integration chunk | chunk unchanged, build custom (reverse sunk-cost check fired: result)>
```

And, separately, the whole-problem search outcome under `### Whole problem`:

```markdown
- Candidates evaluated: <list>
- Outcome: <chunk structure unchanged | chunks collapsed into single integration chunk | partial collapse: <which chunks merged>>
```

## Anti-patterns

- ❌ **Searching once, skimming the first result, declaring "no good options."** Always evaluate at least 2-3 candidates against the criteria. The first-result-only failure mode is what the May baseline Path A test surfaced.
- ❌ **Vague rejection reasons.** "Doesn't fit" is a placeholder. Specify what doesn't fit — which of the 6 criteria, with the specific gap or conflict.
- ❌ **Skipping the reverse sunk-cost check.** When you find a candidate that matches the chunk and the operator says "let's build anyway," apply Tech-D's verifiability rule before recording Reject. Externally sourced (mandate / contract / regulator / factual constraint) → record rejection with citation; otherwise treat as preference and require specific functional gaps or constraint conflicts.
- ❌ **Pricing-page hand-waving.** If a candidate is paid, check the actual pricing page with WebFetch. Don't guess from training data.
- ❌ **Researching forever.** Soft limits exist for a reason. After 3 candidates without a clear winner, move on. Operator attention is the bottleneck, not search depth.
- ❌ **Per-chunk only, skipping whole-problem.** The whole-problem search is the cheapest defense against the case where one platform replaces the entire solution. Skipping it means the operator commits to a 5-chunk build when a 1-chunk integration would have shipped.
- ❌ **Letting Inspire become a way to avoid recording Reject.** Inspire means the chunk still builds custom AND the existing tool's architecture is informing the build. If the existing tool isn't actually informing the build, the classification is Reject — record it as such.
