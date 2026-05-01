# Discovery: Team-Shared Claude Code Agent Plugin

**Date:** 2026-04-29
**Status:** Discovery complete, ready for execution
**Chunks:** Single chunk — no decomposition needed

## Execution order

1. Chunk 1: Build private Claude Code plugin with shared subagents/skills + GH Actions on-call summary runner (no dependencies)

## Framing

The user's team (a 6-person engineering org at a small SaaS company) wants a single, shared, low-ops way to give every engineer the same Claude Code subagents and skills, plus one or two scheduled jobs (e.g., overnight on-call summary that posts to Slack). After Socratic discovery, the right shape is a **private Claude Code plugin** distributed via a private GitHub plugin marketplace. The plugin holds the team's `skills/` and `agents/`. A small GitHub Actions workflow invokes Claude Code in headless mode for the one-or-two scheduled jobs and posts results to Slack via an existing bot identity. No new persistent infrastructure is operated.

### Original statement

> I want to deploy agents for my team that can communicate

### Key reframes

- "Agents" was ambiguous — refined to **shared Claude Code subagents + skills**, with one or two scheduled background jobs. Not a chatbot, not an autonomous platform, not agent-to-agent orchestration.
- "Communicate" was reframed from "agent-to-agent messaging" to **agent-to-human notification** (Slack posts, GitHub PR comments). Inter-agent coordination is not a v1 need; the Task tool already handles within-session subagent dispatch.
- "Deploy" was reframed from "build a platform" to **publish a Claude Code plugin** to a private marketplace. The Claude Code plugin system itself is the deployment mechanism.
- Build-vs-buy research surfaced that the Claude Code plugin system natively satisfies ~90% of the requirement; multi-agent frameworks (LangGraph/AutoGen/CrewAI/Claude Agent SDK) are wrong-tool for this use case.

## Confirmed constraints

- **Internal tooling for a 6-person engineering team** (purpose/audience): not a customer-facing product, not a research artifact. Day-to-day dev productivity (code review, ticket triage, on-call summaries).
- **Claude Code is the LLM client.** Team subscriptions exist; no switching evaluation.
- **Slack is the primary output surface.** GitHub PR comments and Linear are secondary channels. Email is not viable (would be ignored).
- **Keep Claude-related work isolated from the production AWS account.** Even though the team runs ECS Fargate for prod, scheduled Claude jobs must not run there.
- **Shared bot identity** for outbound Slack/GitHub posts. Single org-level Anthropic API key in GitHub Secrets.
- **No new persistent infra to operate.** Small team; ops budget is approximately zero.

## Tested choices

- **"Library frame" (git repo of skills+subagents) over "Platform frame" (custom orchestrator service) and "Reductive frame" (Notion prompt library).** Library frame chosen because the team wants real subagent configs, not just prompts; platform frame rejected because of the no-new-infra constraint.
- **GitHub Actions for scheduled jobs over ECS Fargate.** ECS Fargate already runs prod; rejected because operator wanted Claude work isolated from prod and the cost of running one nightly job on Actions is trivial.
- **Agent-to-human communication over agent-to-agent.** Inter-agent buses considered (A2A protocols, message queues) and rejected — Task tool already handles within-session dispatch and there's no use case for cross-session agent messaging.
- **Per-run max-token cap as the only cost guardrail in v1.** Dashboards and alerting considered and deferred to v2 — operator wants minimum complexity.
- **Claude Code plugin system over a custom repo layout.** Custom layout considered and rejected after Phase 3.5 research surfaced that Claude Code plugins natively cover the requirement.

## Chunk 1: Private Claude Code Plugin with Scheduled-Job Runner

### Problem statement

Build a private Claude Code plugin that bundles a 6-person engineering team's shared subagents and skills (e.g., code review, ticket triage helpers), distributable via a private GitHub-hosted plugin marketplace so each engineer can install it once with `/plugin install`. In addition, build a small GitHub Actions workflow that invokes Claude Code in headless mode on a nightly schedule to produce an on-call summary, using a shared Slack bot identity and a single org-level Anthropic API key stored in GitHub Secrets. The plugin and the runner share the same skill definitions: the runner invokes the same `summarize-oncall` skill that an engineer could invoke interactively. v1 has exactly one scheduled job; the runner should be designed so adding more is straightforward but not over-engineered.

### Constraints (inherited + chunk-specific)

- Internal tooling for 6-person eng team (no end-user-facing UX).
- Claude Code is the LLM client; the plugin format and Claude headless invocation are the two integration points.
- Slack primary output (existing bot identity, can be reused or sibling-cloned). GitHub PR comments + Linear are secondary.
- Anthropic key is a single org-level GitHub Secret; the secret must be scoped to a single repo only (red-team Finding 2 acceptance).
- Per-run max-token cap is required so a runaway loop cannot exceed a bounded spend.
- No infra outside GitHub Actions and the existing Slack bot. No ECS, no new servers.
- Discoverability handled by README; no formal versioning beyond `main`.

### Open choices (for the executor to resolve)

- Plugin manifest layout: which subagents and skills ship in v1 (operator wants to decide during planning).
- Marketplace mechanism: private repo with `marketplace.json` manifest, vs. a single-plugin repo the team installs directly. Both are supported by Claude Code; trade-offs differ for future plugin growth.
- Headless-mode invocation pattern in the GH Actions workflow: how to pass the Anthropic key, how to capture stdout, how to post to Slack (curl + webhook vs. Slack Action).
- Token-cap implementation: env var on the Claude Code invocation? Pre/post check on output length? Simple abort wrapper?
- Repo structure: single repo for plugin + Actions workflow, or two repos? (Probably single — simpler.)

### Dependencies

None (single chunk).

### Recommended executor

`/superpowers:brainstorming`, then `/superpowers:writing-plans`. The brainstorm phase needs to settle the plugin layout and headless-mode invocation pattern; writing-plans turns those into a concrete implementation plan.

## Red-team findings

### Addressed

- **[DISCUSS] Finding 2: Single org Anthropic key in GH secrets is unbounded by frequency.** — Resolution: operator accepted; added constraint that the Anthropic GH secret must be scoped to a single repo only. Per-run max-token cap remains the spend ceiling.
- **[CRITICAL] Finding 3: Existing tools not checked.** — Resolution: Phase 3.5 ran. Claude Code plugin system surfaced as the right shipping vehicle (~90% functionality match); chunk restructured from "custom team-agent repo" to "Claude Code plugin." LangGraph/AutoGen/CrewAI/Claude Agent SDK rejected with specific reasons.

### Accepted risks

- **[DISCUSS] Finding 1: Slack-from-GH-Actions security surface (webhook secrets, who can trigger workflows).** — Accepted: 6-person team, internal-only repo, low blast radius. Documented for future review.
- **[MINOR] Finding 4: No rollback story for skill regressions.** — Deferred to v2.
- **[MINOR] Finding 5: README-based discoverability won't scale past ~10 people.** — Deferred to v2; team is 6, headroom is sufficient.

## Research outcomes (build-vs-buy)

### Overall problem

- **Searched for:** "Claude Code shared team subagents skills plugin repository best practices"; "Claude Agent SDK vs LangGraph vs AutoGen multi-agent framework"; "Claude Code plugin marketplace shared subagents team examples github"
- **Candidates evaluated:** Claude Code plugin system; Claude Agent SDK; LangGraph; AutoGen; CrewAI; VoltAgent/awesome-claude-code-subagents (and similar curated collections)
- **Outcome:** Adopt fully — Claude Code plugin system
- **Effect on chunks:** Chunk 1 restructured from "custom team-agent repo" to "Claude Code plugin published to private marketplace." Saved significant scope.

### Chunk 1 research detail

- **Searched for:** As above.
- **Candidates evaluated:**
  - **Claude Code plugin system** — Adopt fully
    - URL: https://code.claude.com/docs/en/plugin-marketplaces
    - Functionality match: ~90% (plugin format natively bundles skills + subagents + hooks + MCP servers; private marketplace is a built-in concept)
    - Cost: Free (included with Claude Code subscription, which is already a constraint)
    - License: Same as Claude Code
    - Maintenance: Active (Anthropic-maintained)
    - Lock-in: Zero marginal — already locked to Claude Code
    - Integration burden: Low — native concept
    - Reason: This is essentially the exact shape of what the operator described, except "shipped as a Claude Code plugin" instead of "an ad-hoc git repo."
  - **Claude Agent SDK** — Reject
    - URL: https://docs.claude.com/en/api/agent-sdk
    - Reason: Targets building net-new agent applications outside Claude Code (email assistants, research bots, customer support). Operator explicitly wants tooling that runs *inside* Claude Code, not a separate runtime.
  - **LangGraph** — Reject
    - URL: https://gurusup.com/blog/best-multi-agent-frameworks-2026
    - Reason: Production multi-agent workflow framework with directed-graph orchestration and stateful checkpointing. Requires running its own runtime. Operator does not need agent-to-agent orchestration and explicitly rejected new infrastructure.
  - **AutoGen / Microsoft Agent Framework** — Reject
    - URL: https://gurusup.com/blog/best-multi-agent-frameworks-2026
    - Reason: GroupChat-style multi-agent conversations. Same rejection class as LangGraph: wrong problem (no agent-to-agent need), wrong runtime model (separate process), wrong ecosystem (not Claude Code-native).
  - **CrewAI** — Reject
    - URL: https://gurusup.com/blog/best-multi-agent-frameworks-2026
    - Reason: Same class — multi-agent collaboration framework. Not Claude Code-native, and the multi-agent collaboration premise doesn't match an agent-to-human use case.
  - **VoltAgent/awesome-claude-code-subagents and similar curated collections** — Inspire
    - URL: https://github.com/VoltAgent/awesome-claude-code-subagents
    - Reason: Useful as a source of subagent/skill prompts to adapt. Not a deployment path; these are catalogs, not platforms.
- **Outcome:** Chunk shrinks dramatically. Instead of "design a custom team-agent repo," the chunk is "build a Claude Code plugin per Anthropic's plugin spec, plus a small GH Actions runner." Reverse sunk-cost check applied: operator confirmed no specific gap in Claude Code plugins that would justify a custom layout.

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

- **Q:** Is this internal tooling, a product feature, a research artifact, or a workflow orchestrator? (Turn 1, purpose/audience question)
  **A:** Internal tooling for a 6-person eng team — code review, ticket triage, on-call summaries.
  **Impact:** Locked the design space to dev-productivity tooling. Eliminated product/customer-facing patterns. Made "no new infra" defensible.

- **Q:** When you said "agents," do you mean subagents, skills, autonomous loops, or chatbots?
  **A:** Mostly subagents and skills; maybe one or two scheduled tasks. No chatbot.
  **Impact:** Eliminated Slack-bot/web-UI architectures. Kept the surface inside the Claude Code ecosystem.

- **Q:** "Communicate" — agent-to-agent, agent-to-human, or shared state?
  **A:** Mostly agent-to-human. Agents post to Slack, comment on PRs.
  **Impact:** Eliminated message-bus and orchestration framework architectures. Major scope reduction.

- **Q:** Three framings — full platform, library/repo, or just a Notion prompt page? (Technique B)
  **A:** Library frame, with a small GH Actions piece for scheduled jobs.
  **Impact:** Locked the deployment shape: code-as-data, no orchestrator.

- **Q:** AWS or GitHub Actions for scheduled jobs?
  **A:** GitHub Actions — keep Claude work out of prod AWS.
  **Impact:** Added a constraint (isolation from prod), confirmed the choice was tested not assumed.

- **Q:** Have you considered existing tools for this? (Phase 3.5 research)
  **A:** [Operator approved running the research; results restructured the chunk]
  **Impact:** The Claude Code plugin system itself is the right shipping vehicle. Saved significant build scope.

</details>
