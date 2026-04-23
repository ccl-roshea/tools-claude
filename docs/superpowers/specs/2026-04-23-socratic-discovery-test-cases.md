# Test Cases: Socratic Discovery Tool vs. /superpowers Alone

**Date:** 2026-04-23
**Purpose:** Empirical validation set for the decision memo at `2026-04-23-socratic-discovery-tool-evaluation.md` §7. One root idea, three problem statements at low / medium / high thoroughness, run through /superpowers alone and through the Socratic discovery tool, then compared.

**Design principle:** the three prompts share a single root idea ("deploy shared, communicating agents for an engineering team") at increasing specificity. This lets the test measure something richer than any individual prompt: whether the Socratic tool surfaces *different* concerns as the input gets more specific, or whether it just asks generic questions regardless. A good tool should surface baseline ambiguities on the low-thoroughness prompt, finer-grained architectural pitfalls on the medium one, and higher-order concerns (versioning, failure modes, coupling) on the high one. A bad tool will ask similar questions on all three.

The prompts below are pasted verbatim into both tools. Our hypotheses about what a good pass would surface live in a separate section per prompt, so they do not leak into the tools under test.

---

## Root idea

> Deploying shared Claude-based agents for an engineering team where the agents can communicate with each other.

## Test 1 — Low thoroughness

**Thoroughness:** minimal. Intent only. No context on team, scale, stack, "agent" meaning, or communication semantics.

**Prompt (paste verbatim):**

> I want to deploy agents that are available for my entire team and the agents can communicate with each other.

**What we expect a good Socratic pass to surface:**
- What is "an agent" — an autonomous LLM loop, a scheduled job, a chat bot, a skill another user triggers?
- Team scale (3 people vs. 300) and trust model
- Deploy target — local, shared server, cloud, hosted service
- "Available for the entire team" — discoverable? invocable? shared state?
- "Communicate with each other" — message passing, shared memory, RPC, shared filesystem, event bus?
- Sync vs. async; persistence of conversation state
- Identity, auth, observability, cost accounting
- Is this internal tooling, a product feature, a research artifact, or a workflow orchestrator?

---

## Test 2 — Medium thoroughness

**Thoroughness:** moderate. Adds team size, concrete agent examples, a rough communication shape, and stack context. Still leaves most architectural decisions open.

**Prompt (paste verbatim):**

> I want to set up a system where my 8-person engineering team can share Claude-based agents — things like a code-reviewer agent, a deployment-runbook agent, a standup-summary agent. The agents should be discoverable by anyone on the team and should be able to hand off tasks to each other when needed. We're a Python/TypeScript shop on AWS.

**What we expect a good Socratic pass to surface (beyond Test 1's items):**
- "Hand off" semantics — synchronous call-and-wait? async task with callback? queue-based?
- Discoverability mechanism — static config? runtime registry? capability-based lookup?
- Are agents long-running processes or ephemeral per-request invocations?
- Per-user identity vs. team-level shared identity in agent calls
- How is the agent's work observed by the invoking human — streaming output, final result, notification?
- Cost attribution and concurrency caps
- Onboarding model — who can author a new agent, what is the review / deploy pipeline
- Failure modes: one agent down, cyclic handoffs, agents given wildly expensive tasks
- What part of this *shouldn't* the team build themselves vs. adopt an existing framework (AutoGen, LangGraph, Claude Agent SDK, plain Claude Code subagents)?

---

## Test 3 — High thoroughness

**Thoroughness:** high. Stack, scale, protocol, auth, persistence model, deploy target, observability, budget, and timeline are all named. The test is whether the tool can still add value — or just adds noise — when the prompt looks tight.

**Prompt (paste verbatim):**

> We want to build an internal platform where our 8-person engineering team can author and deploy Claude-based agents. Each agent is a long-running HTTP service with a stable URL and API-key auth. Agents register themselves into a shared registry on startup and tag their capabilities. When one agent needs another (e.g., the code-reviewer agent pulls in the style-guide agent for context), it looks up the capability in the registry and calls the peer directly via HTTPS. State is per-invocation — no shared memory. Deploy target is AWS ECS Fargate behind an internal ALB; logs go to CloudWatch; secrets in Parameter Store. Budget: $500/month infra cap. MVP within 3 weeks.

**What we expect a good Socratic pass to surface (higher-order pitfalls, since the basics are named):**
- Why direct HTTPS peer calls vs. an event bus or broker — what does the current choice cost in coupling, retries, and cascading failure?
- Capability tagging: free-form strings, controlled vocabulary, versioned? What happens when two agents claim the same capability?
- Cyclic handoffs — A calls B while B is calling A — how are they detected and broken?
- API-key auth at what granularity: per-agent, per-user, per-invocation? Rotation story?
- "Per-invocation state" — what about long-running agent tasks that legitimately need multi-step state? Is that out of scope or does the design quietly force a workaround?
- $500/month on ECS Fargate + ALB + CloudWatch + LLM API costs — is this budget even feasible at team scale? (Often the answer surfaces a different architecture entirely.)
- Observability: without request tracing across peer calls, debugging a 3-hop agent failure is miserable. Is OpenTelemetry / X-Ray in scope?
- Registry consistency and bootstrapping — what if the registry is down when an agent starts?
- 3-week MVP scope realism — which of the named requirements are actually MVP vs. V1?
- Do existing tools (Claude Agent SDK, LangGraph, Temporal, Step Functions) make most of this unnecessary, or is there a reason to build custom?

---

## Test protocol

For each prompt, run both paths. **Run all Path A results first**, then run Path B in a separate session with the clean-room protocol below.

### Path A — /superpowers alone

1. Fresh Claude Code session
2. Paste the prompt verbatim
3. Answer clarifying questions naturally. Do not volunteer information not asked for.
4. Let /superpowers produce a plan
5. Record: the Q&A transcript, the final plan, turn count, operator typing (approximate character count), wall-clock time
6. Save to `docs/superpowers/specs/path-a-results/test-N-low|medium|high.md` (or similar)

### Path B — Socratic discovery tool, then /superpowers

**Clean-room requirement:** Path B cannot carry context from Path A. This means:
- New session, no CLAUDE.md or memory referencing the Path A results
- Ideally a gap of 24+ hours between runs on the same prompt, so the operator's own memory of Path A's clarifying questions has faded
- The operator answers **only what is asked**, as if seeing the prompt for the first time. If memory of Path A intrudes (e.g., "I remember /superpowers asked about scale, I'll pre-answer that"), do not pre-answer — wait for the tool to ask.
- If a second trusted person is available, have them run Path B instead of the Path A operator. That is the cleanest version of this protocol.

1. Fresh session, clean-room as above
2. Paste the prompt verbatim
3. Run the Socratic discovery tool to completion (operator-terminated, or tool-terminated with operator concurrence)
4. Save the resulting artifact
5. Start a fresh /superpowers session and feed the artifact as the problem statement
6. Let /superpowers produce a plan
7. Record: Socratic transcript, Socratic artifact, final plan, total turn count across both steps, total operator typing, total wall-clock time
8. Save to `docs/superpowers/specs/path-b-results/test-N-low|medium|high.md`

## Scoring rubric

Score each prompt on three axes, 1–5:

1. **Coverage** — of the "expected to surface" list in each test section, how many were actually surfaced? Judge against the expected list only after both paths complete. Same judge, same list.
2. **Correctness of frame** — does the resulting plan reflect what the operator *actually* wanted, in retrospect? Operator self-judgment. Tiebreaker: which plan would the operator actually ship if forced to pick one right now?
3. **Operator cost** — **tracked but not part of the pass gate.** Measured as turns + typing + wall-clock. Recorded for later analysis, because if the tool is wildly more expensive we still care, just not as a ship blocker. Cheap framing errors are worse than expensive correct framings.

## Pass criterion

Path B wins a test when it beats Path A by +1 or more on **both** Coverage *and* Correctness of Frame.

The validation passes for the memo's §7 go-decision when Path B wins in **at least 2 of the 3 tests**.

Operator cost does not enter this judgment. It will inform later MVP tuning: if Path B wins all three tests but costs 5× the operator effort, that shapes the next iteration of the tool (e.g., "the Socratic challenge is doing the work, but too many turns are spent on the gardener-mode next-node-selection; reduce that"). It does not block go.

## Known limitations of this validation

- **Operator bias.** Same person running both paths cannot fully forget what they saw. Mitigated by time gap and the clean-room protocol, not eliminated. A second operator would be strictly better.
- **Single operator / single domain.** One person on agent-platform problems. Results won't fully generalize. This is acceptable for go/no-go; not acceptable for declaring the tool shippable to others.
- **Plan-quality judgment is subjective.** The validation is an argument-closer for this one operator, not a paper. Accept this upfront.
- **The tool doesn't exist yet.** Path B can only run after the MVP is built. Path A should be run now — it gives us a recorded baseline to beat, rather than asking the MVP to beat a remembered one.

## Next step

Run **Path A for all three prompts now**, saving results under `docs/superpowers/specs/path-a-results/`. This is possible today with no new tools. The results will ground the MVP-scoping brainstorm that follows the go decision — so that when we design the tool, we are designing against a specific deficit rather than an abstract argument.
