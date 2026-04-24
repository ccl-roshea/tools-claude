# Decision Memo: Socratic Discovery + Chunking Tool

**Date:** 2026-04-23 (updated 2026-04-24)
**Status:** Go. Validated against Path A baseline. Proceed to MVP scoping.
**Recommendation:** Go, scoped to idea discovery + chunking only. Planning and execution delegated to existing tools (/superpowers). See §9 for conditions.

---

## 1. The original pitch

Treat any problem statement as a graph of sub-problems. Start at a root node and run a five-phase pipeline (DISCOVERY → EXPLORE → DESIGN → PLAN → EXECUTE) at each node, recursing until every leaf is small enough for an executor like /superpowers to handle. Traverse breadth-first by abstraction layer (IDEA → LAYERS → ARCH → STACK → FEATURES). Allow per-node executor assignment. Use HITL throughout.

## 2. How the idea evolved during discovery

Three substantive reframes emerged over the course of the discussion:

1. **The graph is an output artifact, not train tracks.** The tool is not a graph engine executing a plan; it is an exploration loop that *happens to emit a graph* as a byproduct. This is a material simplification and the single most important shift in the design.
2. **Layers are a vocabulary, not a traversal order.** IDEA / LAYERS / ARCH / STACK / FEATURES is a way of naming abstraction levels, not a mandatory BFS sequence. Traversal is emergent — the loop hops between layers based on whatever the current node surfaces as the next most valuable thing to examine. This dissolves the intra-layer-coupling objection without introducing new rigidity.
3. **The core value is Socratic pressure-testing of user framing, not decomposition.** Existing tools (including /superpowers:brainstorming) treat the user's stated problem as mostly given and ask clarifying questions downstream of it. The gap is at the root: users often cannot articulate what they actually want, and discovering that *before* implementation — rather than during MVP-and-scrap cycles — is where most of the value is. The recursive / graph / layered structure is the scaffolding that makes this sustained pressure-testing tractable across a non-trivial problem.

4. **The tool is discovery + chunking only — not planning, not execution.** Path A validation (see §11) proved that /superpowers is good at planning and execution once given a well-framed problem; building competing planning capability would be redundant. The gap is upstream: pressure-testing the framing and breaking too-large problems into executor-sized chunks. The tool's scope is deliberately narrow: Socratic discovery, constraints-vs-choices classification, chunking with dependency annotation, and handoff. Everything downstream (/superpowers for planning, /superpowers:executing-plans or subagent-driven-development for execution) already exists and works.
5. **Over-specification during discovery is actively harmful.** While composing test prompts at medium and high thoroughness, the operator noticed that adding implementation-level specifics (e.g., "agents call each other via HTTPS") silently closed off the design space. This led to retiring Tests 2 and 3 and sharpening the tool's bidirectional verb: *deepen* vague prompts AND *widen* over-committed ones. See §4.4 for the full "constraints vs. choices" analysis.

The evolved framing: **a dialogue loop that Socratically pressure-tests the user's framing, distinguishes constraints from choices, chunks too-large problems into executor-sized pieces with dependencies, and emits a structured artifact that downstream tools like /superpowers can consume. It does not plan. It does not execute. It does the part that is currently missing.**

## 3. Where the idea holds up

- **Discovery is genuinely underserved.** No tool in the current ecosystem systematically pressure-tests the user's framing at multiple abstraction layers. /superpowers:brainstorming is closest, but it explores *one* problem; it does not recurse or challenge the root framing. This is real whitespace.
- **Chunking is a rate-limiter.** The observation that existing executors get the right level of detail *for the chunk they're given*, and thus build wrong-shaped things when the chunk is wrong-shaped, is accurate and widely experienced. Automating the chunking with HITL is a legitimate, focused product goal.
- **Emergent-over-waterfall is the right call for LLM + HITL workflows.** LLMs plus a human have metacognition at every step. A pre-committed BFS traversal throws away that metacognition. Letting the loop hop between layers based on what each step surfaces is both more honest and easier to build.
- **Per-node executor dispatch is the most differentiated idea.** Picking the right specialist per subproblem (one plugin for frontend chunks, another for backend, /superpowers for planning-heavy chunks) is a real unlock that nothing in the current ecosystem does. This is out of MVP scope but worth naming as the long-term strategic win.
- **The methodology is self-referential in a good way.** Problems identified about the system (LLM sycophancy, operator fatigue, unclear stopping criteria) are themselves addressable via the same Socratic discovery process. This is meaningful evidence of conceptual coherence and provides a natural dog-fooding path for the MVP.

## 4. Where I still disagree or push back (AD)

These are not fatal, but the MVP must address them deliberately. Skipping them will produce a tool that "almost works," which is worse than obviously broken.

### 4.1 "Implicit knowledge across session restarts" does not exist

The claim that a new session building Abstract node 1 has implicit knowledge of Idea node 1 from a prior session is **wrong**. A new session has zero memory of prior sessions. What persists is:
- Explicit written artifacts (notes, graph nodes, plans)
- Generic LLM training data

Calling artifact-loading "implicit knowledge" is a naming hazard. If designers believe sessions inherit implicitly, they will under-invest in artifact quality. **Rule for the MVP: every layer or node boundary is a serialization boundary. If it isn't written down, it doesn't exist across sessions.** Within a single session, coherence via shared context is real and valuable — that claim stands.

### 4.2 Anti-sycophancy is a prompt-engineering problem, not a graph problem

The whole premise of "metacognition at every step" rests on the LLM genuinely asking itself *"wait, should I be doing something different right now?"* and sometimes answering *"no."* LLMs default to continuing the current frame. Without deliberate adversarial prompting, this collapses into confident continuation. This is the hardest single engineering problem in the MVP.

Candidate techniques to evaluate in MVP design:
- Force the LLM to write *"what I think is wrong with this framing"* before asking questions
- Ask for 2–3 alternative problem framings at each meaningful step
- Separate Socratic-challenge mode and gardener-emergent mode with explicit mode transitions, so the LLM knows when it should be adversarial
- Use a second, "red-team" prompt periodically against the in-progress artifact
- Constitutional-AI / debate-style techniques from the literature

### 4.3 "No stopping rules" is correct, but needs soft signals

Operator-driven termination is right in principle. In practice, LLMs are happy to explore forever and operators fatigue. The MVP should surface *hints* (not gates):
- "This node has been revisited 3× without new information"
- "10 turns since the last artifact update"
- "This thread has drifted N layers from your original question"

These are shown to the operator, not enforced. They exist to fight rubber-stamping, not to impose determinism.

### 4.4 "Automate what I do manually" must pay for itself — and the tool must distinguish constraints from choices

In the emergent model, the operator is engaged every step (nudging, answering, pruning). That is not automation — that is partnership. The bet is that *steering at every step is cheaper than authoring chunks from scratch*. This is likely true, but the MVP must demonstrate it rather than assume it. Concretely: a successful session should leave the operator feeling they typed less than they would have typing into /superpowers directly to reach the same breakdown.

**Constraints vs. choices — a discovery from the validation process itself.** While composing the medium- and high-thoroughness test prompts, the operator noticed that adding implementation-level specifics *hurt* the discovery process. For example, writing "agents call each other via HTTPS" into the prompt silently excluded in-process function calls, shared-memory IPC, message buses (SNS/SQS, Kafka, Redis streams), gRPC, Unix sockets, and "actually these don't need to be separate processes at all." Each specific implementation detail in a prompt is either a **constraint** (externally imposed: "security mandates HTTPS," "we're on Azure already") or a **choice** (made by the operator while typing, without testing whether it was the right choice). Constraints compress the design space correctly; choices compress it arbitrarily.

This has two implications for the Socratic tool:

1. **The verb is not just "deepen vague prompts" — it's also "widen over-committed ones."** The same Socratic mechanism should challenge specifics that look like premature commitments, asking the operator to classify each detail as a constraint or a choice. Details confirmed as constraints stay; details revealed as choices get reopened.
2. **Over-specification during discovery is actively harmful.** The Test 1 Path A results illustrate this: a 15-word intent-only prompt ("I want to deploy agents that are available for my entire team and the agents can communicate with each other") produced a 1,667-line implementation plan locked into Azure Container Apps + A2A-over-HTTPS + Entra ID + Service Bus + Next.js + Postgres + Bicep IaC. Many of these architectural commitments may be correct, but they were not tested as constraints-vs-choices during discovery. The Socratic tool's job is to ensure each commitment earns its place before downstream executors build on top of it.

The operator's meta-observation: they self-Socratic-challenged while *writing* the test prompts and caught the premature commitments before running the tests. This is evidence that the Socratic approach works — the operator just did it manually. The tool automates this for cases where the operator doesn't catch it.

### 4.5 ~~No grounding in concrete historical cases~~ — resolved by Path A validation

~~Throughout discovery, the conversation stayed at the level of mental models rather than specific real problems where /superpowers missed something and this tool would have caught it.~~

**Updated 2026-04-24:** Path A validation (§11) provides the missing empirical grounding. A 15-word intent-only prompt run through /superpowers produced a comprehensive but shallow result: 6 clarifying questions covering 3 of 8 expected discovery items (Coverage: 2/5), followed by an immediate jump to a specific Azure architecture. The communication model — the user's literal ask — was never explored as a question; it was presented as a recommendation (A2A-over-HTTPS). This is the concrete case the memo was missing: the tool surfaces items that /superpowers does not, and the gap is at the discovery layer specifically.

## 5. Unresolved gaps (to be addressed in MVP scoping brainstorm)

These do not block go/no-go but are the questions the MVP spec must answer:

- **Graph representation.** Since the graph is an output artifact, what is its format? Markdown with structured headings? JSON? Both (human-readable + machine-consumable)?
- **Node schema.** What metadata does each node carry? At minimum: the question it represents, current status, Socratic challenges asked, operator answers, cross-edges to other nodes.
- **Cross-edges.** Layers-as-vocabulary helps, but feature nodes frequently depend on each other. The artifact format must support non-tree edges without becoming a full graph-editing UI.
- **Mode transitions.** When does the LLM switch between Socratic-challenge mode and gardener-emergent (next-node-selection) mode? Is this decided by the LLM, the operator, or rule-based?
- **Handoff to executors.** What is the exact format an executor (like /superpowers) receives? A single node? A subtree? What context travels with it?
- **Persistence granularity.** Does every turn get committed, or only decisions? How does a resumed session reconstruct context?
- **Soft-signal implementation.** Are these computed post-hoc from a turn log, or tracked as first-class state?

## 6. MVP scope

A single skill (not a full plugin), invocable as `/discover` or similar. Approximately 1–2 weeks of careful work.

### What the tool does

1. **Socratic discovery** — pressure-test the user's framing at the root. Challenge assumptions. Surface hidden ambiguities. Distinguish constraints (externally imposed) from choices (made while typing). Widen over-committed prompts. Deepen vague ones.
2. **Chunking** — if the resulting problem is too large for a single /superpowers session, decompose it into sub-problems scoped for one executor each, with dependencies noted between chunks.
3. **Handoff** — emit a structured artifact (markdown) that /superpowers or other executors can consume directly. Each chunk should be self-contained enough to paste into a fresh session.

### Interaction model

- **Input:** a user-stated problem at any level of vagueness or specificity
- **Output:** a committed markdown artifact with headings as chunks, Socratic Q&A inline per chunk, constraints-vs-choices classifications, dependency annotations between chunks, and a recommended execution order
- **Dialogue:** multi-turn loop; operator terminates with "this is fleshed out enough" (LLM may push back once), or LLM proposes termination (operator may push back)
- **Modes:** Socratic-challenge mode (adversarial questioning on a focused area) and gardener mode (deciding what to examine next). Mode transitions explicit in the prompt.
- **Anti-sycophancy:** at least two of the techniques listed in §4.2, selected based on prototyping
- **Soft signals:** revisit count and turns-since-artifact-update shown to operator

### What the tool does NOT do

- **No planning.** /superpowers:brainstorming and /superpowers:writing-plans handle this. The tool's output feeds into them.
- **No execution.** /superpowers:executing-plans and subagent-driven-development handle this.
- **No recursive exploration at every node.** The original pitch proposed running DISCOVERY → EXPLORE → DESIGN → PLAN → EXECUTE at every graph node. The MVP runs discovery + chunking at the root only. If a chunk is itself too large, the operator can re-invoke the tool on that chunk — but this is operator-driven, not automatic recursion.
- **No per-node executor dispatch.** This is the long-term strategic win (§3) but is premature for MVP. The artifact can note *recommended* executor per chunk as a human-readable annotation, but there is no automated dispatch.
- **No graph visualization, cross-session resume, or graph-editing UI.**

## 7. MVP validation plan (non-negotiable)

### Path A baseline (completed)

Test 1 Path A has been run — see §11 and `2026-04-23-socratic-discovery-test-cases.md`. The baseline is recorded: /superpowers alone on a low-thoroughness prompt scores Coverage 2/5. The Q&A transcript is saved at `/test-1/transcript.md`.

### Path B validation (after MVP is built)

1. Run the same Test 1 prompt through the Socratic discovery tool in a clean-room session (see test cases doc for protocol). Record the full transcript.
2. Feed the resulting artifact into a fresh /superpowers session. Let /superpowers produce a plan.
3. Score against the same rubric: Coverage (of the 8 expected items) and Correctness of Frame (operator judgment: would you ship this?).
4. Path B wins if it beats Path A by +1 on both Coverage and Correctness of Frame.

### Additional validation

Run at least 2 more real problems (different domains) through both paths. A pass is "Path B wins in at least 2 of 3 total cases." Operator cost is tracked but does not gate.

If the validation fails, the tool does not ship as-is; the failure mode is analyzed and fed back as a new root node in the tool itself (dog-fooding).

## 8. Prior art to study before MVP design

- Hierarchical Task Network (HTN) planning — classical AI planning that decomposes tasks into subtasks; the formal version of what this tool approximates
- AutoGPT / BabyAGI postmortems — why they drifted and what that implies about unbounded LLM exploration loops
- Tree-of-Thoughts and Plan-and-Solve prompting papers — structured reasoning under LLMs
- Constitutional AI and debate techniques — adversarial prompting against sycophancy
- Socratic questioning in pedagogy literature — there is substantial work on structured Socratic dialogue that likely beats improvising the prompts

## 9. Recommendation

**Go.** The idea is validated at the discovery layer with empirical evidence (§11). The reframe to discovery + chunking only (§2 point 4, §6) makes the scope manageable and complementary to existing tools rather than competitive. The four gaps in §4 remain relevant — §4.5 is resolved, §4.1/4.2/4.3/4.4 must be addressed in the MVP spec.

**Do not proceed** if any of the following are true:
- The anti-sycophancy work in §4.2 is deferred or hand-waved (because then the "pressure-testing" premise is unfounded — the tool degenerates into "tell me more about your idea")
- Scope expands beyond §6 before the MVP ships (no planning, no execution, no per-node dispatch, no graph visualization)
- The operator is unwilling to commit to Path B validation after the MVP is built (because then we shipped an argument, not a tool)

## 10. Next step

Run a focused brainstorm scoped to: MVP interaction design (dialogue loop, mode transitions), artifact format (what does the handoff document look like?), anti-sycophancy technique selection, and chunking heuristics (when is a problem "too large for one executor"?). That conversation produces a design doc and an implementation plan via /superpowers:writing-plans.

## 11. Empirical evidence: Path A scoring (Test 1)

**Prompt:** "I want to deploy agents that are available for my entire team and the agents can communicate with each other." (15 words, intent only)

**What /superpowers asked (6 questions, 6 turns):**

| # | Question | Expected item covered |
|---|----------|----------------------|
| Q1 | What kind of agents? (terminal / always-on / scheduled / mix) | Item 1 (what is "an agent") ✓ |
| Q2 | Which chat surface? (Slack / Teams / Discord / custom) | Not in expected list |
| Q3 | What kinds of tasks? (dev / business / data / customer / mix) | Item 8 partial |
| Q4 | How big is the deployment? (small / medium / large) | Item 2 (team scale) ✓ |
| Q5 | Where will this run? (AWS / GCP / Azure / on-prem) | Item 3 (deploy target) ✓ |
| Q6 | Who authors the agents? (platform team / self-service / low-code) | Not in expected list |

**What was NOT asked:**

| Expected item | Gap |
|---------------|-----|
| "Available for the entire team" — discoverable? invocable? shared state? | Assumed "via portal" without exploring |
| "Communicate with each other" — message passing, shared memory, RPC, event bus? | Jumped to A2A-over-HTTPS in approach presentation. The user's literal ask was never explored as a question. |
| Sync vs. async; persistence of conversation state | Decided for the user (A2A sync + Service Bus async) |
| Identity, auth, observability, cost accounting | Partially — RBAC and observability were user-volunteered in Turn 5, not tool-surfaced. Auth assumed (Entra because Azure). Cost accounting never raised. |
| Is this internal tooling, a product feature, a research artifact? | Assumed internal tooling |

**Coverage score: 2/5** (3 of 8 items surfaced by the tool; 1 additional user-volunteered)

**Correctness of Frame (operator judgment):** the resulting plan is deployable but likely overkill — it jumped to a complex multi-service architecture (orchestrator + specialist Container Apps + Service Bus + Entra + portal) without exploring simpler alternatives. The tool didn't challenge whether this level of complexity was warranted for ~5-20 users and 5-15 agents.

**Key observations:**
- No question challenged the user's framing or asked "do you actually need this?"
- The 3 approach options were all "build a platform" — no "use existing tools" or "start simpler" option
- The communication model was the biggest unasked question — presented as a recommendation, never explored
- The tool moved from 6 clarifying questions to a full architecture to a 1,667-line implementation plan in 8 turns
- The operator had to intervene to stop execution ("revert all the executing you did")

**Transcript:** `/test-1/transcript.md`
**Path A outputs:** `/test-1/docs/plans/`
