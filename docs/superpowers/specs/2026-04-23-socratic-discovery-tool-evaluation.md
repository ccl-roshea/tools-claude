# Decision Memo: Recursive Socratic Discovery Tool

**Date:** 2026-04-23
**Status:** Discovery + exploration complete. Go/no-go decision requested.
**Recommendation:** Weak-go, conditional on the MVP addressing four named gaps and validating against at least three real historical problems before being declared useful.

---

## 1. The original pitch

Treat any problem statement as a graph of sub-problems. Start at a root node and run a five-phase pipeline (DISCOVERY → EXPLORE → DESIGN → PLAN → EXECUTE) at each node, recursing until every leaf is small enough for an executor like /superpowers to handle. Traverse breadth-first by abstraction layer (IDEA → LAYERS → ARCH → STACK → FEATURES). Allow per-node executor assignment. Use HITL throughout.

## 2. How the idea evolved during discovery

Three substantive reframes emerged over the course of the discussion:

1. **The graph is an output artifact, not train tracks.** The tool is not a graph engine executing a plan; it is an exploration loop that *happens to emit a graph* as a byproduct. This is a material simplification and the single most important shift in the design.
2. **Layers are a vocabulary, not a traversal order.** IDEA / LAYERS / ARCH / STACK / FEATURES is a way of naming abstraction levels, not a mandatory BFS sequence. Traversal is emergent — the loop hops between layers based on whatever the current node surfaces as the next most valuable thing to examine. This dissolves the intra-layer-coupling objection without introducing new rigidity.
3. **The core value is Socratic pressure-testing of user framing, not decomposition.** Existing tools (including /superpowers:brainstorming) treat the user's stated problem as mostly given and ask clarifying questions downstream of it. The gap is at the root: users often cannot articulate what they actually want, and discovering that *before* implementation — rather than during MVP-and-scrap cycles — is where most of the value is. The recursive / graph / layered structure is the scaffolding that makes this sustained pressure-testing tractable across a non-trivial problem.

The evolved framing: **a dialogue loop that Socratically pressure-tests the user's framing at each step, hops between abstraction layers based on in-the-moment metacognition, terminates on operator judgment (with LLM pushback allowed), and emits a structured artifact that downstream tools like /superpowers can consume.**

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

### 4.4 "Automate what I do manually" must pay for itself

In the emergent model, the operator is engaged every step (nudging, answering, pruning). That is not automation — that is partnership. The bet is that *steering at every step is cheaper than authoring chunks from scratch*. This is likely true, but the MVP must demonstrate it rather than assume it. Concretely: a successful session should leave the operator feeling they typed less than they would have typing into /superpowers directly to reach the same breakdown.

### 4.5 No grounding in concrete historical cases

Throughout discovery, the conversation stayed at the level of mental models rather than specific real problems where /superpowers missed something and this tool would have caught it. Every concern and every counter is conceptually sound, but none is empirically validated. **This is a go/no-go risk the MVP must resolve early**, not a conceptual flaw.

## 5. Unresolved gaps (to be addressed in MVP scoping brainstorm)

These do not block go/no-go but are the questions the MVP spec must answer:

- **Graph representation.** Since the graph is an output artifact, what is its format? Markdown with structured headings? JSON? Both (human-readable + machine-consumable)?
- **Node schema.** What metadata does each node carry? At minimum: the question it represents, current status, Socratic challenges asked, operator answers, cross-edges to other nodes.
- **Cross-edges.** Layers-as-vocabulary helps, but feature nodes frequently depend on each other. The artifact format must support non-tree edges without becoming a full graph-editing UI.
- **Mode transitions.** When does the LLM switch between Socratic-challenge mode and gardener-emergent (next-node-selection) mode? Is this decided by the LLM, the operator, or rule-based?
- **Handoff to executors.** What is the exact format an executor (like /superpowers) receives? A single node? A subtree? What context travels with it?
- **Persistence granularity.** Does every turn get committed, or only decisions? How does a resumed session reconstruct context?
- **Soft-signal implementation.** Are these computed post-hoc from a turn log, or tracked as first-class state?

## 6. Suggested MVP scope (if go)

A single skill (not a full plugin), invocable as `/socratic-discover` or similar. Approximately 1–2 weeks of careful work.

- **Input:** a user-stated problem at any level of vagueness
- **Output:** a committed markdown artifact with headings as abstraction layers, bullets as sub-nodes, Socratic Q&A inline per node, and explicit cross-edge annotations
- **Interaction:** multi-turn dialogue loop; operator terminates with "this is fleshed out enough" (LLM may push back once), or LLM proposes termination (operator may push back)
- **Modes:** Socratic-challenge mode (adversarial questioning on a focused node) and gardener-emergent mode (deciding what to examine next). Mode transitions explicit in the prompt.
- **Anti-sycophancy:** at least two of the techniques listed in §4.2, selected based on prototyping
- **Soft signals:** revisit count and turns-since-artifact-update shown to operator
- **Explicitly out of scope for MVP:** per-node executor dispatch, automated plan generation, live orchestrated execution, graph visualization, cross-session resume

## 7. MVP validation plan (non-negotiable)

Before declaring the MVP useful:

1. Pick 3 real problems the operator has previously run through /superpowers (or similar) and felt the output missed details.
2. Run each through the new tool from scratch — problem statement only, no guidance.
3. For each, compare: what got surfaced, what got missed, how much operator typing was required, and how the resulting artifact feeds a subsequent /superpowers session versus the original /superpowers-only run.
4. A pass is *"at least 2 of 3 cases produced an artifact that led to a materially better downstream plan, with comparable-or-less operator effort."*

If the validation fails, the tool does not ship as-is; the failure mode is analyzed and fed back as a new root node in the tool itself (dog-fooding).

## 8. Prior art to study before MVP design

- Hierarchical Task Network (HTN) planning — classical AI planning that decomposes tasks into subtasks; the formal version of what this tool approximates
- AutoGPT / BabyAGI postmortems — why they drifted and what that implies about unbounded LLM exploration loops
- Tree-of-Thoughts and Plan-and-Solve prompting papers — structured reasoning under LLMs
- Constitutional AI and debate techniques — adversarial prompting against sycophancy
- Socratic questioning in pedagogy literature — there is substantial work on structured Socratic dialogue that likely beats improvising the prompts

## 9. Recommendation

**Weak-go.** Proceed to an MVP-scoping brainstorm, then a spec, then implementation. The idea as evolved (§2) is coherent, differentiated at the discovery layer, and of manageable scope if limited to §6. The four gaps in §4 must be explicitly addressed in the MVP spec; validation per §7 must happen before the tool is declared useful.

**Do not proceed** if any of the following are true:
- The operator is unwilling to commit to the validation plan in §7 (because then we are validating an argument, not a tool)
- The anti-sycophancy work in §4.2 is deferred or hand-waved (because then the "metacognition at every step" premise is unfounded)
- Scope expands beyond §6 before the MVP ships (because ambitious meta-tooling ideas die from scope creep, and this one is no exception)

## 10. Next step if go

Run a focused brainstorm scoped to: MVP interaction design, artifact format, and anti-sycophancy technique selection. That conversation produces a design doc and an implementation plan via /superpowers:writing-plans.
