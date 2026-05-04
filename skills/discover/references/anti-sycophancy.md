# Anti-Sycophancy Techniques

> Phase names (DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the technique specs only.

Three techniques the skill uses to prevent the LLM from drifting into agreeable summarization. Each catches a different failure mode and runs at different points in the flow.

| Technique | When it fires | What it catches | Cost |
|-----------|--------------|-----------------|------|
| **D — Constraints vs. choices** | Continuously, every time a specific surfaces | Untested assumptions baked into the framing | ~0 extra turns |
| **B — Alternative framings** | Turn 1 + 2 more at convergence points in Phase 1 | Wrong problem frame, complexity bias | ~2-3 extra turns total |
| **C — Red-team pass** | Once, as Phase 3 (its own phase) | Contradictions, missing concerns, scope creep, dependency gaps | ~2 extra turns |

---

## Technique D — Constraints vs. choices (continuous)

**When to fire:** Any time a specific implementation detail appears in the conversation. The detail can come from the user's input, the user's answer to a question, or the LLM's own suggestion.

Examples of "specific implementation details":
- A named technology ("Postgres", "AWS", "Next.js", "Azure")
- A protocol or pattern ("REST", "GraphQL", "event-driven")
- An architectural choice ("microservices", "monorepo", "serverless")
- A library or framework ("React", "FastAPI", "Tailwind")
- A concrete number that wasn't justified ("3-week MVP", "$500/month budget")
- A behavioral default or policy quote ("default-ON [X]", "always [Y] before [Z]", "never [W]", "[X] is the source of truth"). Also: any operator-quoted rationale that becomes the support for a design rule (e.g., "we don't want a PM agent without expertise..." → "default-ON it-ops consultation"). Any rule about agent behavior whose only support is operator preference, not external constraint.

**The prompt:**

> "You mentioned [X]. Is that a constraint — something imposed on you externally (company policy, existing infra, compliance, team decision) — or a choice you're making right now? If it's a choice, I want to explore alternatives before we lock it in."

**Trigger phrasing for the sixth category (behavioral defaults / policy quotes):**

> "You stated [Q]. The rule it justifies is [R]. Is [R] a constraint — something imposed externally — or a preference that should be pressure-tested? Alternatives to [R]: ..."

The sixth category often surfaces when the operator phrases a preference as a justification ("we don't want X without Y"). The agent must classify the *rule the quote justifies*, not the quote itself.

**If constraint:** do NOT record yet. First, sub-classify by scope-of-origin with this follow-up:

> "Is [constraint] driven by V1 needs, or by out-of-scope/future needs (V2 features, hypothetical scale, undeployed systems)?"

**Two outcomes:**

- **V1-driven** → record as `[V1] <text> (source: <quote / external source>)`. Move on.
- **Future-pull** → challenge: *"What specifically about V1 requires this? Would V1 work without it?"* The operator must either:
  - Articulate a concrete V1 impact → record as `[future-pull, V1-justified: <reason>] <text> (source: ...)`
  - Acknowledge it's V2-driven → either drop from V1 design, or record as `[V2-driven, deferred] note: <text>` under a separate "Deferred (V2 only)" subsection (NOT as a V1 constraint)

These recording formats match the artifact template (see `references/artifact-template.md`); operators following Tech-D produce strings that drop directly into the "Confirmed constraints" section without reformatting.

The agent MUST run sub-classification on every constraint, not only ones that "feel" V2-ish. Future-pull constraints often look reasonable on first encounter; they reveal themselves only when the question is asked explicitly.

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

**When to fire:**

1. **Mandatory turn 1, immediately after Phase 0 completes** — fire the 4-option frame *before* asking any other discovery question. By turn 3, the operator has typed multiple paragraphs inside the original frame; firing at turn 1 surfaces alternatives while the cost of switching is still low.
2. When a major architectural direction emerges later in Phase 1.
3. Before the skill proposes moving from DISCOVER to CHUNK.

The LLM should not fire this every turn between firings. It should sense when the conversation is *settling* on a frame and use that as the cue for firings 2 and 3.

**The prompt:**

> "Before we go further, four ways to think about this problem:
>
> 1. **[Complex frame]** — what we've been building toward. Full custom system.
> 2. **[Middle-build frame]** — same outcome, smaller surface. Reuse more, build less.
> 3. **[Low-build frame]** — minimal new code. Glue + configuration over existing tools.
> 4. **[No-build frame]** — outcome reached without writing code. Workflow change, existing tool adoption, accepting the pain.
>
> Which resonates, or is the answer a mix?"

**Critical principle: equal weight across the full complexity spectrum.** All four options must be plausible, concrete paths the operator could actually take — same bar across the board. Option 4 (no-build) is not a formality; it is a credible alternative the operator must be able to evaluate seriously. If the agent cannot construct a credible no-build frame for the problem, that is itself a signal the framing is too narrow and needs reconsideration — re-state the outcome at a higher level and try again.

The bias the LLM must fight: Socratic exploration tends to expand problems. Without the no-build frame, conversations drift toward bigger, more architected solutions. Including all four frames keeps the full complexity space honest.

### Example (good reframings for "deploy agents for my team")

1. **Complex frame:** A multi-service platform with a portal, orchestrator, and specialist agents communicating via A2A.
2. **Middle-build frame:** A shared chat workspace where each "agent" is a Claude Code skill team members invoke via slash commands. No platform. No orchestrator. Skill packages built and shared in a git repo.
3. **Low-build frame:** A small set of well-crafted prompts saved in a shared git repo, plus a README that describes when to use each. Team uses Claude Code's existing skills mechanism to load them.
4. **No-build frame:** Document a few prompt patterns in the team wiki. Team members paste into Claude/ChatGPT as needed. No code at all.

The user might pick any frame, or a hybrid. All four deserve serious consideration.

### Anti-pattern: weak no-build frame

Don't write: "4. Use a spreadsheet" or "4. Just don't build it" as a no-build placeholder. Don't write a no-build frame that the agent itself doesn't believe in. Each frame — including no-build — must be a *qualitatively different, credible* path the operator could actually take. If the no-build frame feels forced, re-examine the outcome restatement: the framing may be at the wrong level of abstraction.

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
6. **Existence question** — "do you even need to build this?" Is there an existing tool or simpler approach? This is a shallow check from training data — Phase 3.5 does the active research. If a strong candidate surfaces here, record it as a CRITICAL finding and let Phase 3.5 verify.
7. **Stop-the-clock check** — what happens if you stop here? What would be lost vs. what would be gained?
8. **Future-pull contamination** — for each chunk and each constraint, ask: *"Is any design element here driven by features, scale, or systems that aren't in V1 scope?"* This catches what Tech-D's V1/future-pull sub-classification missed during DISCOVER.

**Severity guidance for future-pull contamination findings:**

- **CRITICAL** — the future-pull element materially shapes the chunk's architecture. Example: a "core/ has no Claude-runtime-specific imports" constraint shapes how every module in `core/` is structured.
- **DISCUSS** — the future-pull element adds friction without shaping. Example: choosing structlog now instead of stdlib `logging` adds an extra V1 dependency with no V1-specific benefit.
- **MINOR** — small choices with future-pull rationale that don't propagate.

**Expectation:** by the time RED-TEAM runs, future-pull contamination should be rare because Tech-D's sub-classification caught it inline. If RED-TEAM finds many instances, that is itself a signal that Tech-D's sub-classification is being skipped in DISCOVER — not just a sign that RED-TEAM is doing its job.

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
