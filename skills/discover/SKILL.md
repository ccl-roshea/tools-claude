---
name: discover
description: >
  Socratic idea discovery and chunking — runs upstream of /superpowers.
  Pressure-tests the user's problem framing, distinguishes constraints
  from choices, decomposes large problems into executor-sized chunks
  with dependencies, actively researches existing tools (build-vs-buy),
  and sequentially dispatches each chunk to /superpowers or another
  executor. Especially valuable when the user is unsure what they want,
  presents an ambitious or multi-subsystem goal, OR when the prompt
  looks tight but contains specifics that may be untested choices
  rather than constraints (e.g., "build a REST API using Express with
  Postgres on AWS ECS" — every named technology deserves a constraint-
  vs-choice classification before downstream work locks them in).
when_to_use: >
  Use before /superpowers in any of these situations: (1) the user has
  a vague or ambitious idea ("I want to build a platform for X"); (2)
  the user says they're not sure what they want, or the problem
  statement is one or two sentences; (3) the problem looks like it
  could span multiple subsystems or domains; (4) the prompt is
  over-specified — names specific technologies, protocols, or stacks
  that may have been typed out of habit rather than chosen
  deliberately; (5) the user is starting a new project, ambitious
  feature, or platform build. Skip this skill for narrow well-scoped
  bug fixes, single-function changes, or maintenance tasks where the
  problem is genuinely tight.
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
- `references/checkpoint-protocol.md` — WIP file format, per-exchange writes, phase-boundary commits, resume, completion

You should read these on demand, not all at once at session start.

## The seven phases

You execute the following phases in order. Within each phase you can loop, but you don't skip ahead. Each phase has explicit entry and exit criteria.

0. **PREMISE CHECK** — One mandatory turn at session start. Restate the operator's highest-level outcome and ask whether a no-build path could reach it.
1. **DISCOVER** — Socratic exploration with continuous Technique D (constraints vs. choices, with V1/future-pull sub-classification) and 2-3 invocations of Technique B (alternative framings, 4-option spectrum). First Tech-B firing is at turn 1, immediately after Phase 0.
2. **CHUNK** — Decompose into executor-sized chunks if needed; compute execution order. Includes mandatory chunk-overload-signal check and per-chunk audit before exit.
3. **RED-TEAM** — Adversarial pass on the conclusions (Technique C), including future-pull contamination check.
4. **RESEARCH** (Phase 3.5) — Active build-vs-buy research; restructure chunks based on findings.
5. **ARTIFACT** — Run write-time gates (see `references/artifact-gates.md`); write and commit the discovery document if gates pass.
6. **DISPATCH** — Sequentially launch /superpowers for each chunk.

The flow is: premise → gather understanding → decompose → attack → research → write → execute. Each phase narrows commitment from "open exploration" to "executor-ready problem statements." At every phase exit through ARTIFACT, the agent surfaces a structured ledger to the operator (see `references/checkpoint-protocol.md`) before advancing.

## Session startup

Read `references/checkpoint-protocol.md` for the full WIP file format, per-exchange write steps, and phase-boundary commit commands.

**New session** (plain invocation):
- Begin with Phase 0 (PREMISE CHECK). Do not derive the slug or create the WIP file until after Phase 0 is recorded — the slug derivation may use the restated outcome from Phase 0 step 1.
- After Phase 0 completes (or after the first exchange if Phase 0 took only one turn), derive a provisional topic slug and create `docs/discovery/.wip/<slug>.wip.md`. The WIP file's transcript starts with the Phase 0 turn(s) recorded under a `Premise check` section, then the regular transcript begins.
- If `docs/discovery/.wip/` already contains `.wip.md` files, note them to the operator BEFORE Phase 0: "Found in-progress session(s): `<slug>` (Phase: X, Turn: N). Run `/discover resume <slug>` to resume, or continue for a new session." (Phase 0 does not run until the operator confirms a new session.)

**Resume** (`/discover resume <slug>`):
- Read the WIP file for `<slug>`. Follow the resume reconstruction steps in `references/checkpoint-protocol.md`.
- Continue from the recorded phase. Do not re-ask questions already in the transcript.

## Phase 0: PREMISE CHECK

**Entry:** User pastes a problem statement. The statement may be vague ("I want to deploy agents for my team") or over-specified ("Use Express, Postgres, deploy to ECS"). Either is a valid input.

**Exit:** Premise check recorded in the WIP file under a `Premise check` section. Phase advances to DISCOVER.

### What you do in this phase

Exactly one mandatory turn (with a possible 1-3 follow-up turns if the operator wants to explore the no-build path).

**Step 1: Restate the highest-level outcome.** State back the *outcome* the operator is asking for, not the proposed solution. Example: for "build a PM agent for Plane" input, restate as "you want PM legwork off your plate" — *not* "you want a Plane-integrated agent." Naming the outcome forces the conversation onto the right axis (the goal) rather than the wrong axis (the solution shape).

**Step 2: Ask the premise-check question.** Use this exact shape:

> "Before I start asking questions about how to build this, one premise check: is there a path where this outcome gets reached *without building anything new*? Possible no-build paths I can see: [enumerate 2-3 specific ones]. Have you considered these and ruled them out, or is the build premise still open?"

**Anti-pattern guard:** the agent MUST NOT enumerate generic no-build paths ("just don't build it"). The 2-3 paths must be *concrete to the operator's stated outcome*. For example, for a "build a PM agent for Plane" input, concrete no-build paths would include:
- "Use Plane's MCP directly from your Claude installs (no new agent code)."
- "Improve the existing markdown POC instead of greenfield rewrite."
- "Accept that you do PM in Plane manually with a small skill set, no agent."

If the agent cannot construct 2-3 *concrete* no-build paths for the operator's outcome, that itself is a signal the framing is too narrow — note this and re-state the outcome at a higher level before re-asking.

**Step 3: Handle the operator's response.**

- **"Considered and ruled out"** — record the ruling reason in the WIP file under a new `Premise check` section (format: `Ruled out because: <reason>`). Move to Phase 1.
- **"Open / haven't considered"** — proceed to a brief no-build exploration (1-3 turns). For each no-build path the operator wants to consider, ask a clarifying question about whether it would actually reach the outcome. If a no-build path proves viable, suggest stopping the discovery and pursuing it. If not, record what was considered and why building wins (format: `Considered but rejected: <path> — <reason>`). Move to Phase 1.
- **"Don't ask me this"** (operator override) — record the override and the operator's reason (format: `Operator override: <reason>`). Move to Phase 1.

**Resume behavior:** if `/discover resume <slug>` is invoked, Phase 0 does NOT re-run. The WIP file's `Premise check` section is preserved. If a resumed WIP predates the Phase 0 discipline (no `Premise check` section present), tell the operator:

> "This session predates the Phase 0 premise check. Want me to run a backfill premise check turn now, or skip and resume from Phase `<phase>`?"

Then proceed per the operator's choice.

### Anti-patterns

- ❌ **Restating the solution instead of the outcome.** "You want a Plane-integrated agent" is a restatement of the proposed solution, not the underlying goal. Name the goal: "you want PM legwork off your plate."
- ❌ **Skipping the no-build path enumeration.** The 2-3 concrete paths are load-bearing. A bare "have you considered alternatives?" invites "yes I did" without specifics.
- ❌ **Treating Phase 0 as multiple turns by default.** It is ONE turn unless the operator opts into the no-build exploration.
- ❌ **Generic no-build paths.** "Just don't build it" or "use a spreadsheet" without a credible path to the outcome is filler. If you can't construct 2-3 credible paths, re-state the outcome at a higher level.

## Phase 1: DISCOVER

**Entry:** User pastes a problem statement. The statement may be a single sentence or multiple paragraphs. It may be vague ("I want to deploy agents for my team") or over-specified ("Use Express, Postgres, deploy to ECS"). Both are valid inputs.

**Exit:** The operator agrees that discovery is sufficient, OR you propose moving on and the operator approves. Commit the WIP file with `phase: CHUNK` per `references/checkpoint-protocol.md`.

### What you do in this phase

Ask one question at a time. Socratic style — probe the framing, surface assumptions, classify specifics. Never ask multi-part compound questions; if you have multiple things to ask, ask them in sequence.

### Continuous: Technique D (constraints vs. choices)

Read `references/anti-sycophancy.md` for the full Technique D protocol if you haven't already.

**Trigger:** any time a specific implementation detail appears in the conversation. The detail can come from the user's input, an answer they give, or a suggestion you make.

**Action:** classify it. Ask:

> "You mentioned [X]. Is that a constraint — something imposed on you externally — or a choice you're making right now?"

Constraints get recorded. Choices get briefly explored (2-3 alternatives) and then either confirmed or replaced.

**Do not skip this.** The Path A test demonstrated that adopting specifics without classification produces shallow architectures. This is your most important continuous discipline.

### Periodic: Technique B (4-option alternative framings)

Fire 2-3 times per session:
1. **Mandatory turn 1, immediately after Phase 0 completes** — fire the 4-option frame *before* any other discovery question.
2. When a major architectural direction emerges later in Phase 1.
3. Before you propose moving from DISCOVER to CHUNK.

**Action:** present 4 framings of the entire problem:

> "Before we go further, four ways to think about this problem:
>
> 1. **[Complex frame]** — what we've been building toward. Full custom system.
> 2. **[Middle-build frame]** — same outcome, smaller surface. Reuse more, build less.
> 3. **[Low-build frame]** — minimal new code. Glue + configuration over existing tools.
> 4. **[No-build frame]** — outcome reached without writing code. Workflow change, existing tool adoption, accepting the pain.
>
> Which resonates, or is the answer a mix?"

**Critical:** all four options must be plausible, concrete paths the operator could actually take. Option 4 (no-build) is not a formality; it is a credible alternative the operator must be able to evaluate seriously. If you cannot construct a credible no-build frame for the problem, re-state the outcome at a higher level and try again. See `references/anti-sycophancy.md` Tech-B section for full guidance.

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

### Checkpoint discipline

After every turn in this phase (and in all phases through RESEARCH): write the turn to the WIP file per `references/checkpoint-protocol.md`. This applies whether you asked a question, fired Technique B, proposed moving on, or made any other exchange. Every turn goes in.

### Discovery axes to consider

These are not a strict checklist — exploration is emergent — but most non-trivial problems benefit from touching each of these axes. Before proposing to move on from Phase 1, check which axes are unexamined and ask if any of them are still open:

- **Purpose / audience.** Is this internal tooling, a product feature, a research artifact, or a workflow orchestrator? *Always worth asking explicitly* — it shapes architecture decisions downstream and is easy to assume implicitly when it shouldn't be.
- **Scale.** Rough user count, request volume, data volume — orders of magnitude only.
- **Deploy target.** Local, shared server, cloud, hosted service. Often a constraint, but ask.
- **Lifecycle.** Long-running vs. ephemeral, persistent state vs. stateless, scheduled vs. on-demand.
- **Identity / trust model.** Who can use it? Per-user identity, shared identity, anonymous?
- **Operability.** Auth, observability, cost accounting, error handling expectations.
- **Communication / interaction surface.** How is it invoked, how does it respond, who sees the output?
- **Constraints from outside.** Compliance, existing infra, team skills, budget, deadlines.

If the user has answered the operator's prompt with rich detail that already covers many of these, don't re-litigate them. But if a major axis is genuinely unexplored, name it before declaring Phase 1 complete. *Especially* the purpose/audience question — if you don't know whether you're building internal tooling or a shippable product, you don't know what "good" looks like.

### Anti-patterns

- ❌ **Asking compound questions.** "What's your scale and what's your tech stack?" — split into two questions.
- ❌ **Accepting specifics without classifying.** Every named technology, protocol, or pattern triggers Technique D.
- ❌ **Sycophantic summarization.** "Great choice!" "That makes sense!" — don't validate, classify.
- ❌ **Over-asking.** If you've explored an area and the answers are repetitive, propose moving on. Don't dig forever.
- ❌ **Skipping Technique B.** Without alternative framings, the conversation drifts toward the first frame that emerged. Fire B at turn 1, then at convergence points.
- ❌ **Filler no-build frame.** A no-build option you don't believe in is worse than no option — it makes the prompt look like it covered alternatives when it didn't. If the no-build frame feels forced, re-state the outcome at a higher level.

## Phase 2: CHUNK

**Entry:** Discovery is complete. You have a refined problem statement, confirmed constraints, tested choices, and a sense of the problem's scope.

**Exit:** Chunk structure approved by operator (or "no chunking needed" approved). Commit the WIP file with `phase: RED-TEAM` per `references/checkpoint-protocol.md`.

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

**Exit:** All CRITICAL findings addressed. Operator approves. Commit the WIP file with `phase: RESEARCH` per `references/checkpoint-protocol.md`.

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

**Exit:** All chunks classified for build-vs-buy. Operator approves classifications. Chunks restructured. Commit the WIP file with `phase: ARTIFACT` per `references/checkpoint-protocol.md`.

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

**Step 5: stage the artifact:**

```bash
git add docs/discovery/<topic-slug>.md
```

**Step 5b: finalize the session transcript.** Follow the completion steps in `references/checkpoint-protocol.md`. Strip the YAML front matter from the WIP file, write the transcript to `docs/discovery/<topic-slug>.transcript.md`, then commit everything together:

```bash
git add docs/discovery/<topic-slug>.transcript.md
git rm docs/discovery/.wip/<topic-slug>.wip.md
git commit -m "docs(discovery): add artifact and transcript for <topic>"
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

a. **Assess chunk complexity for recursion.** Before composing the dispatch prompt, check whether this chunk is well-scoped for /superpowers or whether it would benefit from its own /discover pass first. The parent /discover pressure-tested the *root* framing, but chunks can still be too large or multi-decision for a single /superpowers session.

Apply these signals to the chunk:
- Does the "Open choices" list have 3+ independent items?
- Does the problem statement still feel vague or multi-faceted when read aloud (i.e., would a fresh executor still need clarification on basic intent)?
- Does the chunk span multiple sub-domains (e.g., "Portal" = UX + auth + APIs)?
- Did Phase 3's red-team flag this chunk as scope-creep-prone or with unresolved untested specifics?

If 2 or more signals fire, propose to the operator:

> "Chunk N (<name>) looks like it might still need its own discovery pass before /superpowers can plan it well. The signals: [cite which fired and why]. Want to run /discover on this chunk first, or proceed straight to /superpowers?"

If the operator chooses /discover, recursively invoke this skill on the chunk's problem statement and constraints. The output is a sub-discovery artifact at `docs/discovery/<parent-slug>/<chunk-slug>.md`. Then dispatch the sub-chunks of that artifact via the same Phase 5 logic. Operator-driven recursion only — no automatic recursion. The operator decides per chunk and can stop the recursion at any depth.

If 0-1 signals fire, proceed straight to dispatch — don't surface the prompt. Don't ask "should we run discovery?" on chunks that look fine; that's just operator fatigue. The point is to flag chunks that genuinely need it.

If the operator declines /discover, proceed straight to dispatch.

b. **Compose the dispatch prompt.** Combine:
- The chunk's problem statement (verbatim from artifact)
- A "## Constraints (do not re-open)" section with all top-level constraints + chunk-specific constraints
- The chunk's "Open choices (for the executor to resolve)" section
- An "## Upstream decisions (from completed chunks)" section IF this chunk has dependencies — populated from the prior chunks' /superpowers outputs

c. **Launch via Agent tool:**
- `subagent_type`: `general-purpose`
- `description`: `"Plan chunk <N>: <chunk name>"`
- `prompt`: the composed prompt
- `run_in_background`: `false` (operator must interact)

d. **Wait for completion.** The operator drives the /superpowers session. The agent returns when /superpowers' brainstorm + writing-plans sub-flow finishes.

e. **Extract decisions.** Read the design doc and plan that /superpowers produced (in `docs/superpowers/specs/` and `docs/superpowers/plans/`). Summarize key decisions for downstream chunks: architecture choices, tech stack, API contracts, data models. Format into a "## Upstream decisions" section ready to feed into the next dependent chunk.

f. **Update the artifact.** Add a link to the chunk's design doc and plan in the chunk's section. Optionally add a "Decisions made" subsection. Commit the artifact update.

g. **Move to the next chunk** in execution order.

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
