# Discovery: Team Claude Code skills repo + result-sharing convention

**Date:** 2026-04-29
**Status:** Discovery complete, ready for execution
**Chunks:** Single chunk — no decomposition needed

## Execution order

1. Chunk 1: Design team Claude Code skills repo + result-sharing convention (no dependencies)

Single chunk — no parallelism considerations.

## Framing

A 6-engineer team wants to consolidate the one-off Claude Code agent / skill setups its members have been individually building into a shared, version-controlled library that everyone on the team installs and can invoke from their existing Claude Code session, and to add a lightweight convention so the results of agent runs are visible to teammates (so handoffs work without bespoke runtime infrastructure). The original framing of "agents that communicate with each other" was tested against alternatives and reframed: the team does not actually want a multi-agent runtime with agent-to-agent RPC or a message bus; they want shared skills + a discoverable place for results. v1 has no deployed runtime; if and when something is deployed (e.g. a Slack bot in V2), it must run on AWS.

### Original statement

> I want to deploy agents for my team that can communicate

### Key reframes

- "Agents that communicate" → "shared skills + a result-sharing convention" (the user, after Technique B, agreed the original framing was a "fantasy" and the real need was sharing).
- "Each person has their own agent" → "shared library any team member invokes from their own Claude Code." Removed the per-person agent runtime entirely.
- "Communicate with each other" → "post results to a known place so others can see and resume." No agent-to-agent RPC, no message bus, no event-driven coupling.
- "Deploy" → "v1 doesn't deploy anything." The original word "deploy" implied a service; the refined v1 is a git repo of skills loaded by each engineer's local Claude Code.

## Confirmed constraints

- **AWS-only for any deployed component**: company policy. Locks out GCP-managed and Azure-managed runtimes. Currently inert in v1 (nothing is deployed) but will apply if/when V2 adds a Slack bot or hosted runtime.
- **Single shared Anthropic API key, no per-user budget tracking**: explicit decision; team is small enough that runaway-loop risk is tolerable, finance reviews the bill.
- **Team scale ~6 engineers, ~25 person company**: shapes which solutions are viable — no multi-tenancy, no enterprise SSO, no hardened RBAC needed.
- **Async result handoff with persistence**: requesting human keeps working and returns to read results later; results must persist somewhere readable by the rest of the team.

## Tested choices

- **Claude Code as runtime**: alternatives considered — Cursor agents, OpenAI Assistants, custom Claude Agent SDK loop, AutoGen, LangGraph. Selected because team already has Claude Code seats, daily usage, and existing skill-authoring patterns. Phase 3.5 confirmed Anthropic ships official skill-sharing mechanisms that fit this exactly.
- **Claude Code skills as v1 invocation surface**: alternatives considered — CLI tool, custom web UI, Slack bot. Rejected for v1 because they all add integration cost beyond the existing skill workflow. Slack bot deferred to V2.
- **Result-sharing default = `results/<date>-<skill>-<author>.md` committed to the shared repo**: alternative considered — Slack thread as primary. Rejected because multiple conventions break discoverability. Slack thread allowed as optional add-on, not v1 default.
- **Contribution model = PR + 1 reviewer**: alternatives considered — anyone-can-push (rejected: quality drift) and full review by lead (rejected: stalls contributions). PR-with-one-reviewer balances throughput and quality at this team size.
- **Shape is shared library + posting convention, not platform**: alternatives considered (Technique B fired twice) — full multi-agent platform with portal/orchestrator (rejected: scope is a fantasy relative to actual need); just-skills-no-log (rejected: no resumability); reductive "README of prompts in wiki" (rejected: loses git versioning and `claude` plugin install path). Hybrid of #2 and #3 from the second Technique B round was selected, with explicit decision NOT to build a custom log service in v1.

## Chunk 1: Design team Claude Code skills repo + result-sharing convention

### Problem statement

Design and bootstrap a shared Claude Code skills repository for a 6-engineer team using the official Anthropic Claude Code plugins/skills mechanism (`.claude/skills/`, plugin marketplace pattern). The repo must contain (a) an initial set of 3-5 skills representative of the agent-style work the team has been doing one-off (e.g. "review flaky tests," "summarize a PR," "draft release notes"), (b) a documented contribution model (PR + 1 reviewer), (c) a documented result-sharing convention where invocation outputs are committed to `results/<date>-<skill>-<author>.md` in the same repo so teammates can discover and read them, and (d) installation/onboarding docs so each engineer can clone-and-go with the skills loaded into their existing Claude Code. No deployed runtime, no custom log service, no agent-to-agent communication layer. Output is a runnable repo plus a README team members can follow.

### Constraints (inherited + chunk-specific)

- Use official Anthropic Claude Code plugins/skills mechanism (do not build a custom skill runtime).
- Single shared Anthropic API key model — do not design per-user auth or budgeting.
- Team scale ~6 — do not design for multi-tenancy or RBAC.
- Result-sharing default convention is `results/<date>-<skill>-<author>.md` in the repo.
- Contribution model is PR + 1 reviewer.
- v1 ships no deployed services; AWS constraint is inert but documented for V2.
- Attribution = git author of the result file. No invocation-time identity tracking.

### Open choices (for the executor to resolve)

- Concrete shape of the initial 3-5 skills (which workflows to formalize first; the user mentioned "review flaky tests" as one example).
- Whether to ship as a plain git repo of `.claude/skills/` or as a full Claude Code plugin (with `plugin.json` manifest). Trade-off: plugin adds discoverability and version pinning at the cost of more setup ceremony.
- Folder layout for results — flat `results/`, or grouped (e.g. `results/<author>/`, `results/<skill>/`).
- Whether to include any lightweight automation (e.g. a hook that reminds the user to commit a result file after a skill run), or leave that fully manual in v1.
- README and onboarding docs structure: single README, or split (CONTRIBUTING.md, USAGE.md, etc.).

### Dependencies

None.

### Recommended executor

`/superpowers:brainstorming` followed by `/superpowers:writing-plans`. The chunk is small enough for a single brainstorm-and-plan session.

## Red-team findings

### Addressed

- **[DISCUSS] Finding 2 — Vague result-sharing convention.** Resolution: picked `results/<date>-<skill>-<author>.md` as the default convention; Slack thread allowed as optional add-on but not v1 default.
- **[DISCUSS] Finding 4 — No contribution model.** Resolution: PR + 1 reviewer.
- **[CRITICAL] Finding 6 — Existence question (is there already a tool that does this?).** Resolution: Phase 3.5 research confirmed Anthropic ships official skills/plugins mechanisms (`.claude/skills/`, plugin marketplaces) that cover the "shared library" portion. The chunk was rescoped to *use* that mechanism rather than reinvent it.

### Accepted risks

- **[DISCUSS] Finding 1 — AWS constraint is inert in v1.** Accepted because: v1 deploys nothing; constraint will activate at V2 (Slack bot or hosted runtime). Documented explicitly in the framing and constraints.
- **[MINOR] Finding 3 — No skill versioning story.** Accepted because: git history covers v1's needs. If the team adopts plugin marketplace (versioned plugins), pinning becomes available later.
- **[MINOR] Finding 5 — Attribution is git-author-of-result-file, not invocation-time identity.** Accepted because: light audit only, honor system, the scale doesn't justify invocation logging in v1.

### Dismissed

None.

## Research outcomes (build-vs-buy)

### Overall problem

- **Searched for:** `Claude Code plugins skills team shared repository 2026` and `multi-agent framework comparison AutoGen LangGraph Claude Agent SDK 2026`.
- **Candidates evaluated:** Anthropic Claude Code plugins/skills (official), AutoGen, LangGraph, Claude Agent SDK.
- **Outcome:** Adopt fully (Claude Code plugins/skills) for the shared-library portion; reject the multi-agent frameworks because the refined v1 doesn't need a separate runtime.
- **Effect on chunks:** Chunk was reframed — instead of "build a shared agent system," the chunk uses Anthropic's official mechanism for the library and only designs the team-specific content/conventions on top. Chunk did not collapse to zero (we still need to design *which* skills, *what* contribution rules, *what* posting convention) but the runtime question is fully answered by the off-the-shelf adoption.

### Chunk 1

- **Searched for:** `Claude Code plugins skills team shared repository 2026` (per-chunk and overall search overlap because this is a single-chunk design).
- **Candidates evaluated:**

  - **Anthropic Claude Code Plugins / Skills (official `.claude/skills/`, plugin marketplace pattern)** — Adopt fully
    - URL: https://code.claude.com/docs/en/plugins ; https://github.com/anthropics/skills ; https://github.com/anthropics/claude-code/blob/main/plugins/README.md
    - Functionality match: ~90% of the shared-library goal. Covers repo-based sharing (`.claude/skills` committed to git), plugin marketplaces for private team distribution, and enterprise managed settings for org-wide rollout. Doesn't cover the result-sharing convention itself, which is by design — that part is editorial, not technical.
    - Cost: free (built into Claude Code; team already has seats).
    - License: N/A (a Claude Code feature, not a dependency).
    - Maintenance: actively maintained by Anthropic.
    - Lock-in: low. Skills are markdown + YAML; portable to other agent runtimes if migration ever needed.
    - Integration burden: low. Each engineer clones the repo (or installs via plugin marketplace); skills load automatically.
    - Reason: this is the supported, official mechanism for exactly the use case. Building a custom skill loader would duplicate Anthropic's work.

  - **AutoGen (Microsoft)** — Reject
    - URL: https://microsoft.github.io/autogen/
    - Functionality match: ~70% of the original (pre-reframe) framing; ~10% of the refined v1.
    - Cost: free, OSS.
    - License: MIT.
    - Maintenance: active.
    - Lock-in: medium (Python framework, replaces rather than extends Claude Code).
    - Integration burden: medium-high — would require running a separate Python runtime, building the multi-agent conversation layer, and stepping outside the team's existing Claude Code workflow.
    - Reason: refined v1 explicitly removed the multi-agent runtime; AutoGen would replace Claude Code, not extend it. Note for V2 if "agents talking to each other autonomously" comes back as a real requirement.

  - **LangGraph (LangChain)** — Reject
    - URL: https://langchain-ai.github.io/langgraph/
    - Functionality match: ~60% of original framing; ~5% of refined v1.
    - Cost: free OSS; LangSmith hosted observability is paid.
    - License: MIT.
    - Maintenance: active.
    - Lock-in: medium-high (graph-shaped framework, framework-specific state).
    - Integration burden: high (Python framework, learning curve for graph + state schemas).
    - Reason: same as AutoGen — refined v1 doesn't need orchestration of multiple long-running agents. Inspire-only for V2 orchestration if the team ever does want a real multi-agent backend.

  - **Claude Agent SDK (Anthropic)** — Reject for v1, Inspire for V2
    - URL: https://docs.claude.com/en/api/agent-sdk/overview
    - Functionality match: ~30% of refined v1 (it builds custom agents; v1 wants shared *skills*, which is a Claude Code feature, not an SDK concern).
    - Cost: free SDK; pay for API usage (already covered by company key).
    - License: SDK terms.
    - Maintenance: active, official.
    - Lock-in: medium (Anthropic-specific, but team is already there).
    - Integration burden: medium — would require building a custom runtime, which is exactly what the reframe scoped out.
    - Reason: refined v1 doesn't build a custom runtime. If V2 adds a Slack bot that's more than a Claude Code skill wrapper, this is the right SDK to use then.

- **Reverse sunk-cost check:** Not triggered because the chosen path *adopts* the official Anthropic mechanism rather than rejecting it in favor of building. No "build it ourselves" preference to test.

- **Outcome:** Chunk renamed and rescoped from "build a shared agent system" to "design team-specific content/conventions on top of Anthropic's official Claude Code plugins/skills mechanism." Net: chunk smaller, less risky, faster to ship.

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

- **Q (turn 2):** What kind of agent did you mean — autonomous LLM loop, scheduled job, chatbot, or shared skill library?
  **A:** Claude Code agents, each person has their own, they hand off work.
  **Impact:** Surfaced "Claude Code" as a specific that needed Technique D.

- **Q (turn 4, Technique D):** Is "Claude Code" a constraint or a choice?
  **A:** Mixed — paid seats and team likes it, but not policy. A leaning.
  **Impact:** Recorded as a tested choice (with alternatives to be explored in research), not a constraint.

- **Q (turn 8):** What does "communicate" actually mean — shared chat thread, RPC, queue, shared state, or human-in-the-loop?
  **A:** Mostly RPC-ish — "delegate a bounded task and get a result back." No queue.
  **Impact:** Eliminated event-bus / pub-sub framings; simplified toward request-response.

- **Q (turn 10):** Sync or async? Persist conversation/state, or fresh context each time?
  **A:** Async-ish, results land somewhere readable later.
  **Impact:** Confirmed async result-handoff with persistence.

- **Q (turn 12):** Where would the agents run — laptop, shared cloud, managed, or serverless?
  **A:** AWS shop (policy), probably shared cloud, local-only too fragile.
  **Impact:** Recorded AWS as a hard constraint and "local-only fragile" as a derived constraint.

- **Q (turn 14, Technique B #1):** Multi-agent platform vs. shared workspace vs. shared README of prompts?
  **A:** Hybrid of #2 and #3 — shared library + lightweight task/result log.
  **Impact:** Major reframe. Removed "per-person agent runtime" and "agent-to-agent RPC" from scope. Reduced problem size by ~70%.

- **Q (turn 26, Technique B #2):** Skills + log vs. just skills vs. README in wiki?
  **A:** Skills + log, but pushed back on whether log is worth building.
  **Impact:** After honest counter-push, settled on skills repo + lightweight posting convention (commit markdown + optional Slack thread). No custom log service in v1.

- **Q (turns 20–24):** Auth/identity, cost, observability?
  **A:** Honor-system attribution, single shared API key, transcripts in shared log = observability.
  **Impact:** Recorded as constraints; pushed lots of complexity out of v1.

- **Q (turn 30):** Refined statement match check.
  **A:** Yes, that's it.
  **Impact:** Exit DISCOVER, enter CHUNK.

</details>
