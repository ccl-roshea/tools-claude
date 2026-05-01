# Eval 1 (iteration 2): Vague Agents — Full Transcript

Eval prompt: `I want to deploy agents for my team that can communicate`

User persona: developer at 6-person SaaS eng team, has rough idea about Claude Code agents, hasn't pinned details.

Phases executed: 1 (DISCOVER), 2 (CHUNK), 3 (RED-TEAM), 3.5 (RESEARCH), 4 (ARTIFACT). Phase 5 (DISPATCH) intentionally not executed per eval instructions.

---

## Turn 0 — User initial input
> I want to deploy agents for my team that can communicate

## Turn 1 — Skill (Phase 1: DISCOVER opens; PURPOSE/AUDIENCE QUESTION)
Before I start asking questions, I want to flag something: "deploy agents that can communicate" has a lot of degrees of freedom. Let me probe one at a time.

First, the most load-bearing question: **what's the purpose of this?** Is this:
- **internal tooling** that your team uses day-to-day (e.g. dev productivity, ops automation)?
- a **product feature** you're shipping to your own customers (the agents are part of what you sell)?
- a **research artifact** — exploring the agent space, learning what's possible?
- a **workflow orchestrator** — the agents drive a specific business process end-to-end?

The right architecture is wildly different across those four — easy to build the wrong thing if we don't pin this down up front.

## Turn 2 — User
Internal tooling. We're a 6-person engineering team at a small SaaS company. I want to give the team shared agents — like, helpful assistants for code review, ticket triage, on-call summaries, that kind of thing. We use Claude Code already individually but each person reinvents their own setup.

## Turn 3 — Skill (Technique D fires on "Claude Code")
Good — internal tooling, dev productivity, 6 people. That tightens the design space a lot.

You mentioned Claude Code. Quick classify: is "we use Claude Code" a constraint (company tooling decision, paid for, etc.) or a choice you're making right now? If choice, alternatives include Cursor, Copilot, Aider, plain Claude.ai with web — each has different shareability stories.

## Turn 4 — User
Constraint, basically. We have team Claude Code subscriptions and that's what people use. I'm not looking to switch tools.

## Turn 5 — Skill (probes the meaning of "agent")
Recorded: Claude Code is a constraint.

Now the word "agent" is doing a lot of work in your statement. In the Claude Code ecosystem, "agent" can mean very different things:

1. A **subagent** — a Claude config (system prompt + allowed tools) that you invoke from inside a Claude Code session via the Task tool. Lives in `.claude/agents/`.
2. A **skill** — a reusable instruction file (slash command) shared across the team. Lives in `.claude/skills/` or a plugin.
3. An **autonomous loop** — a long-running process (cron, background agent) that does work on its own without a human driving it.
4. A **chat bot** — something the team talks to outside Claude Code (Slack, web UI).

When you said "agents," which of these were you picturing? Or a mix?

## Turn 6 — User
Honestly I was vague on this. I think mostly #1 and #2 — subagents and skills the team can share. Maybe #3 for things like "summarize on-call overnight" but I'd want a human in the loop for most of it. Definitely not #4, we don't need a chatbot.

## Turn 7 — Skill (probes "communicate")
Helpful — so primarily shared subagents + skills, with maybe one or two scheduled background tasks. Chatbot is out.

Next: "agents that can communicate." That phrase is also ambiguous. Communicate with each other, communicate with the team, or both? Concretely:

- Do you imagine **agent-to-agent** messaging (e.g. one subagent dispatches work to another via Task)?
- Or **agent-to-human** updates (e.g. an agent posts to Slack when something happens)?
- Or **shared state** (agents read/write a common scratchpad or knowledge base)?

## Turn 8 — User
Mostly agent-to-human, I think. Like, when the on-call summary agent finishes, it should post to Slack. The code review agent should comment on PRs. I'm not sure I need agents talking to each other — the Task tool already handles that within a single session.

## Turn 9 — Skill (Technique D fires on "Slack")
OK, that's a meaningful simplification — output channels, not inter-agent buses. Recording.

You mentioned Slack. Constraint or choice? If choice, alternatives are GitHub PR comments only, Linear/Jira comments, email digests, or even just a shared Notion page.

## Turn 10 — User
Slack is a constraint, that's where the team lives. We also use Linear and GitHub. Email would be ignored.

## Turn 11 — Skill (Technique B — first alternative-framings)
Recorded: Slack is the primary output surface; GitHub and Linear are secondary integration points.

Before we go deeper, let me step back and offer three different ways to frame what we're building. I want to make sure we're not converging on the wrong shape.

1. **Shared platform frame (current):** A repo or plugin that bundles team subagents + skills + a few scheduled jobs. Team members install it once; everyone gets the same agents. Background jobs run somewhere shared (a server, Lambda, GitHub Actions). Output goes to Slack/GitHub.

2. **Library frame:** A git repo with skills and subagents only — no scheduled jobs, no shared infrastructure. Each engineer pulls the repo into their own `.claude/`. The "deployment" is `git pull`. Anything autonomous is just a GitHub Action triggered by repo events. No new infra to operate.

3. **Reductive frame:** A shared Notion page with 5-10 well-crafted prompts the team copies into Claude Code as needed. No code, no agents, no deployment. The "team agent" is a documented prompt library.

Which of these resonates? Or does the right answer mix two?

## Turn 12 — User
Frame 2 is closest. I really don't want to operate new infrastructure — we're a small team. The git repo idea matches what I was vaguely picturing. Frame 3 is too thin; we want actual subagent configs not just prompts. But I do want like one or two scheduled things (the overnight on-call summary), and GitHub Actions for that sounds right.

## Turn 13 — Skill (probes scheduled/background piece)
Good — Frame 2 with a small scheduled-job carve-out. Recording.

On the scheduled jobs: GitHub Actions has cost and concurrency implications, and running Claude inside Actions is non-trivial (auth, rate limits, secret management). Quick question — do you have any other infra you're already paying for that could host scheduled work? You mentioned earlier we use AWS or did I make that up?

## Turn 14 — User
Yeah we're on AWS. We have ECS Fargate for the main app. Honestly though, GitHub Actions is fine for this — we already use it for CI, and one nightly job isn't going to blow the budget. I'd rather keep all "Claude stuff" out of our prod AWS account.

## Turn 15 — Skill (Technique D on AWS / GH Actions choice; identity question)
Reasonable — and "keep Claude work isolated from prod AWS" is itself a meaningful constraint, recording it.

So GitHub Actions for scheduled jobs is now a tested choice (ECS Fargate considered, rejected because ops isolation matters more than infra reuse). Locked in.

Two more axes I want to touch before proposing we move on:

**Identity / trust:** when the on-call summary agent runs in GitHub Actions and posts to Slack, whose identity is it acting as? A shared bot user? Per-engineer credentials? Does it matter for your use case?

## Turn 16 — User
A shared bot user is fine. We already have a Slack bot for our deploy notifications, I can reuse that or make a sibling one. For the API key to Anthropic, we'd use a single org-level key in GitHub secrets.

## Turn 17 — Skill (probes observability/cost)
Got it — shared bot identity, single org Anthropic key in GH secrets. Recording.

**Cost & observability:** if a scheduled agent runs amok (token loop, retry storm), how would you know? Do you want any cost guardrails (max tokens per run, daily spend cap), or is "trust it and check the bill monthly" fine for v1?

## Turn 18 — User
For v1, trust it and check the bill is fine. Maybe just a max-tokens-per-run hard cap so a single bug doesn't burn $500. We don't need dashboards or alerting for this.

## Turn 19 — Skill (soft signals fire; running summary; propose moving on)
OK, recording max-tokens-per-run as a chunk requirement. v1 cost posture: trust + per-run cap, no dashboards.

Here's my running summary of what I have:

**Confirmed constraints:**
- Internal tooling for a 6-person eng team (purpose/audience)
- Claude Code is the LLM client; not switching
- Slack is primary output surface; GitHub + Linear secondary
- Keep Claude work out of prod AWS account
- Shared bot identity, org-level Anthropic key in GH secrets

**Tested choices:**
- "Library frame" (git repo of skills+subagents, GH Actions for scheduled jobs) over platform frame and Notion-prompts frame
- GitHub Actions for scheduled jobs over ECS Fargate
- Output is agent-to-human (Slack/PRs), not agent-to-agent

**Themes that emerged:**
- Subagents + skills shared via repo
- One or two scheduled jobs (e.g. on-call summary)
- Per-run token cap as the only cost guardrail in v1

**Axes I haven't probed in depth:** discoverability (how does the team find/learn the skills?), versioning/update flow, what specific subagents/skills are in v1 scope.

I think the framing is solid enough to move toward chunking. Want to go deeper on any of those unprobed axes, or move on?

## Turn 20 — User
Move on. Discoverability we'll figure out with a README and we don't need formal versioning — just main branch. The exact list of v1 agents I'd rather decide during planning.

## Turn 21 — Skill (Phase 2: CHUNK — single chunk proposal)
Phase 2: Chunk assessment.

Looking at the signals: this is one repo, one tech domain (Claude Code configs + a thin GitHub Actions workflow), tightly coupled (the scheduled job uses the same skills the humans use). Maybe 3-4 distinct design decisions: repo structure, scheduled-job mechanics, secret/identity wiring, README/onboarding.

That's borderline-but-leaning-single-chunk. Tight coupling is a signal AGAINST chunking. I'd propose treating this as one chunk — "team-shared Claude Code agent repo with a small scheduled-job runner." The /superpowers brainstorming session can resolve repo structure + scheduled-job design together since they share the same secrets/identity story.

Sound right, or do you want me to split it (e.g. repo separately from the GH Actions runner)?

## Turn 22 — User
Single chunk is fine. I agree they're tightly coupled.

## Turn 23 — Skill (Phase 3: RED-TEAM — mode shift announced, 5 findings)
Switching to red-team mode. I'm going to try to break what we've concluded. Severity tags: CRITICAL / DISCUSS / MINOR.

**Finding 1 [DISCUSS]:** We classified Slack as a constraint but never asked whether posting to Slack from GitHub Actions has security implications (incoming webhook secrets in GH, who can trigger workflows). For internal tooling on 6-person team this is probably fine, but worth flagging.

**Finding 2 [DISCUSS]:** "Single org Anthropic key in GH secrets" means every workflow with access to that secret can spend money. The max-tokens-per-run cap helps but doesn't bound *how often* something runs. Worth a brief check that nothing else with access to that secret can loop.

**Finding 3 [CRITICAL]:** We never explicitly asked whether the team has tried existing solutions for this. There are at least three known frameworks/SDKs in this space (Claude Agent SDK, AutoGen, LangGraph) and Claude Code itself ships subagents+skills+plugins as first-class concepts. Phase 3.5 will run the actual research, but flagging this CRITICAL: the answer might be "use Claude Code's plugin system as-is and skip a custom repo."

**Finding 4 [MINOR]:** No rollback story. If a skill regresses, the team has no signal except "Claude Code feels off." For v1, probably fine.

**Finding 5 [MINOR]:** Discoverability deferred to "README" — works for 6 people but won't scale. Noted.

How do you want to handle each?

## Turn 24 — User
1: dismiss, accept the risk for v1, write it down. 2: accept, add a note that the GH secret should be scoped to a single repo only. 3: agreed CRITICAL, run the research and tell me what you find. 4 and 5: defer to v2.

## Turn 25 — Skill (Phase 3.5: RESEARCH — runs WebSearch x3)
Recording dispositions. Moving to Phase 3.5 — research.

Searching for existing tooling that solves "shared team agents on Claude Code with a small scheduled-job piece."

[WebSearch 1: "Claude Code shared team subagents skills plugin repository best practices 2026"]
[WebSearch 2: "Claude Agent SDK vs LangGraph vs AutoGen multi-agent framework comparison 2026"]
[WebSearch 3: "Claude Code plugin marketplace shared subagents team examples github"]

## Turn 26 — Skill (research findings)
Done with research. Here's what I found:

**Candidates evaluated:**

1. **Claude Code plugin system itself** — Adopt fully.
   - URL: https://code.claude.com/docs/en/plugin-marketplaces
   - Functionality match: ~90%. Plugins bundle skills + subagents + hooks + MCP servers. Installable per team. Built-in to the tool you already use.
   - Cost: Free (part of Claude Code).
   - License: Same as Claude Code.
   - Maintenance: Active (Anthropic-maintained).
   - Lock-in: You're already locked into Claude Code (constraint), so this adds nothing.
   - Integration burden: Low. Native concept.
   - The Claude Code plugin system literally is the "shared team agent repo" you described. A plugin = a git repo with `.claude-plugin/plugin.json`, plus `skills/`, `agents/`, etc. Team members install the plugin from a marketplace (which can be your private GH repo).

2. **Claude Agent SDK** — Reject.
   - URL: https://docs.claude.com/en/api/agent-sdk
   - Reject reason: This is for building *new agent applications outside Claude Code* (research bots, customer support, etc.). Wrong tool — you specifically said you want what your team uses *inside Claude Code*, not a separate agent app.

3. **LangGraph / AutoGen / CrewAI** — Reject.
   - URL: https://gurusup.com/blog/best-multi-agent-frameworks-2026
   - Reject reason: Multi-agent orchestration frameworks for autonomous systems. You explicitly said agent-to-agent communication is NOT a need; agents-to-humans (Slack/PR) is. These frameworks would be massive overkill and require a separate runtime to operate, contradicting your "no new infra" constraint.

4. **VoltAgent/awesome-claude-code-subagents (and similar collections)** — Inspire.
   - URL: https://github.com/VoltAgent/awesome-claude-code-subagents
   - Useful as a source of subagent/skill patterns to crib from. Not a replacement — these are catalogs, not a deployment path.

**Reverse sunk-cost check:** Is "we want to build our own repo" a constraint or a choice? If choice, the bar for rejecting Claude Code plugins is specific gaps. I don't see any — they fit your needs nearly perfectly.

**Recommendation:** Adopt the Claude Code plugin system as the shipping vehicle. The chunk shrinks from "design a custom team-agent repo" to "build a Claude Code plugin (with the team's skills + subagents) and a small GH Actions workflow that invokes Claude Code headless mode for the on-call summary."

Approve?

## Turn 27 — User
Yes, that's clearly the right call. Plugin it is. Build a private plugin marketplace in our org GH so the team can install it.

## Turn 28 — Skill (Phase 4: ARTIFACT — write file)
Approved. Restructuring the chunk to "build a private Claude Code plugin (skills + subagents + GH Actions runner)" and writing the artifact.

[Write file: docs/discovery/team-agents-iter2.md]

## Turn 29 — Skill (Phase 4 close; STOP per eval instructions)
Artifact written to `docs/discovery/team-agents-iter2.md`. (Skipping the git commit step in this eval run since the controller handles git.) Want to review before dispatch, or proceed?

[STOP — Phase 5 not executed per eval instructions.]
