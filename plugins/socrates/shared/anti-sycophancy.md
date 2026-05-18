# Anti-Sycophancy Techniques

> Shared library consumed by multiple Socrates skills (currently `/discover` and `/solution`). Phase names and the overall flow are defined in each consuming skill's `SKILL.md`; this file expands the technique specs only and is skill-agnostic at the rule level. Skill-specific specializations are flagged inline.

Three techniques each consuming skill uses to prevent the LLM from drifting into agreeable summarization. Each catches a different failure mode and runs at different points in the flow.

| Technique | When it fires | What it catches | Cost |
|-----------|--------------|-----------------|------|
| **D — Verifiability rule** | Continuously, every time a specific surfaces | Shapes locked in without external grounding; untested assumptions baked into the framing | ~0 extra turns |
| **B — Alternative framings** | Turn 1 + 2 more at convergence points in the discovery/shape-discovery phase | Wrong problem frame (in /discover) or wrong shape frame (in /solution); complexity bias | ~2-3 extra turns total |
| **C — Red-team pass** | Once, as a dedicated red-team phase in each consuming skill | Contradictions, missing concerns, scope creep, dependency gaps | ~2 extra turns |

---

## Technique D — Verifiability rule (continuous)

**When to fire:** Any time a specific surfaces. The specific can come from the operator's prompt, an answer to a question, or the skill's own suggestion. "Specific" includes:

- A named technology ("Postgres", "AWS", "Next.js", "Azure")
- A protocol or pattern ("REST", "GraphQL", "event-driven")
- An architectural choice ("microservices", "monorepo", "serverless")
- A library or framework ("React", "FastAPI", "Tailwind")
- A concrete number that wasn't justified ("3-week MVP", "$500/month budget")
- A solution-shaped abstraction ("real-time updates", "comprehensive task instructions with guardrails", "auditability as a first-class citizen", "primary working tool")
- A behavioral default or policy quote ("default-ON [X]", "always [Y] before [Z]", "never [W]", "[X] is the source of truth"). Also: any operator-quoted rationale that becomes the support for a design rule (e.g., "we don't want a PM agent without expertise..." → "default-ON it-ops consultation"). The rule the quote justifies is what gets classified, not the quote itself.

**The rule.** Every surfaced specific is one of two things:

- **EXTERNAL** — verifiable via a concrete external source from one of the five categories below. Lock in as a constraint.
- **PREFERENCE / SHAPE** — no external source. Do not classify the shape itself. The consuming skill handles the preference per its own rule (see below).

Absence of an external source is not "soft constraint" or "operator strong preference." It is a preference, and the consuming skill takes it from there.

**Skill-specific handling of the PREFERENCE path:**

- **In `/discover`:** peel back to the outcome the shape serves and park it in the WIP ledger's Parked shapes subsection with the outcome-question. (See the /discover SKILL.md Phase 1 spec and "Peel-back path (preference): park the shape" below for the operator-facing prompt and ledger format.)
- **In `/solution`:** classify the parked shape as one of:
  - **candidate** — evaluate against alternatives via Tech-D's tested-choice path (the shape is one of several plausible designs; pick by comparing).
  - **default-to-test** — run Tech-B's no-build framing against it (the shape may not need to exist at all; pressure-test by constructing the no-build alternative).

  /solution's input set for SHAPE-DISCOVER is /discover's parked-shapes ledger entries.

### The five external-source categories

A specific qualifies as EXTERNAL only if the operator can point to one of:

1. **Regulator / compliance framework** — SOC2, HIPAA, PCI-DSS, GDPR, FedRAMP, etc. Cite framework + the specific control. *Example:* `regulator — SOC2 CC6.1: logical access controls`.
2. **Contract / commercial agreement** — enterprise contract, vendor SLA, customer MSA. Cite contract + clause. *Example:* `contract — enterprise AWS agreement, §4.2 cloud exclusivity`.
3. **Deployed system** — infrastructure already running in the operator's environment. Cite system + version. *Example:* `deployed system — Postgres 15 cluster on RDS, prod since 2024-01`.
4. **Prior empirical result** — previous experiment, POC, production incident, or load test with documentation. Cite result + where recorded. *Example:* `prior empirical — INC-2025-0412 postmortem: Redis cluster failover took 47s`.
5. **Factual measurement** — headcount, revenue, traffic, scale numbers from observed reality. Cite measurement + when taken. *Example:* `factual measurement — 12 engineers across 3 squads, as of 2026-04`.

If the proposed source doesn't fit one of these five, treat the specific as preference. "It's what we usually do," "the team is comfortable with it," "we discussed it last quarter" are not external sources.

### Source citation format

Tightens the existing `(source: …)` field; no new field is introduced.

- **External:** `(source: <category> — <specific citation>)` — e.g., `(source: regulator — SOC2 CC6.1: logical access controls)`.
- **Preference:** no `source` field. Record under the WIP ledger's "Parked shapes" subsection instead, with the outcome-question the shape raises. (Ledger format defined in `checkpoint-protocol.md`.)

### Operator-facing prompt

> "[X] surfaced. What's the external source? Specifically: is there a (regulator, contract, deployed system, prior empirical result, factual measurement) that mandates this? If yes, cite it and I'll record as constraint. If no, this is a design preference — I'll park it with the outcome-question it raises."

For the "rule justified by quoted preference" case (e.g., "we don't want X without Y"):

> "You stated [Q]. The rule it justifies is [R]. What external source mandates [R] — regulator, contract, deployed system, prior empirical result, or factual measurement? If none, [R] is a preference and I'll park the shape it implies."

### Lock-in path (external only): V1/future-pull sub-classification

After an external source is cited, do NOT record yet. First sub-classify by scope-of-origin:

> "Is [constraint] driven by V1 needs, or by out-of-scope/future needs (V2 features, hypothetical scale, undeployed systems)?"

**Two outcomes:**

- **V1-driven** → record as `[V1] <text> (source: <category> — <specific citation>)`. Move on.
- **Future-pull** → challenge: *"What specifically about V1 requires this? Would V1 work without it?"* The operator must either:
  - Articulate a concrete V1 impact → record as `[future-pull, V1-justified: <reason>] <text> (source: <category> — <specific citation>)`.
  - Acknowledge it's V2-driven → either drop from V1 design, or record as `[V2-driven, deferred] note: <text>` under a separate "Deferred (V2 only)" subsection (NOT as a V1 constraint).

The agent MUST run sub-classification on every external constraint, not only ones that "feel" V2-ish. Future-pull constraints often look reasonable on first encounter; they reveal themselves only when the question is asked explicitly.

These recording formats match the artifact template (see `references/artifact-template.md`); operators following Tech-D produce strings that drop directly into the "External constraints" section without reformatting.

### Peel-back path (preference): park the shape — /discover specialization

V1/future-pull does NOT apply on the preference path. The shape itself is not classified. This is the `/discover` realization of the PREFERENCE-path rule above. Instead:

1. Name the outcome-question the shape raises ("What outcome does [X] serve? What breaks if it isn't met?").
2. Record an entry in the WIP ledger's "Parked shapes" subsection with the shape, the turn it surfaced, the outcome-question, and who introduced it (operator vs. skill).
3. Surface the outcome-question to the operator inline: *"Parking [X] — the outcome-question I'm tracking against it is [Q]. Does that capture what you actually want to know?"*

A parked shape can be revived later as a tested choice once its outcome-question is answered (handled by the ledger's `resolved` field). What it cannot do in /discover Phase 1 is escape unresolved or get promoted to constraint without a source citation. The parked-shapes ledger is consumed by `/solution`'s SHAPE-DISCOVER phase as its candidate input set.

### Example (good — external lock-in)

User: "We need SOC2-grade audit logging on every agent action."
Skill: "What's the external source — regulator, contract, deployed system, prior empirical, or factual measurement?"
User: "Regulator. SOC2 CC7.2 — system monitoring."
Skill: "Got it. Is the audit-logging requirement V1-driven, or pulled from a future scope (e.g., a not-yet-signed enterprise customer)?"
User: "V1 — we're in the SOC2 audit window now."
Skill: [records] `[V1] SOC2-grade audit logging on every agent action (source: regulator — SOC2 CC7.2: system monitoring)`. "Locked in. Moving on."

### Example (good — peel-back to outcome, shape parked)

User: "I want real-time updates from the agents."
Skill: "What's the external source for 'real-time' — regulator, contract, deployed system, prior empirical, or factual measurement?"
User: "No external source — I just think it'd be better."
Skill: "Then 'real-time' is a preference, not a constraint. The outcome-question I'm parking it against: *how often does the outcome 'real-time' serves actually trigger, and what breaks if it isn't met?* I'll record it under Parked shapes and we'll resolve it when the outcome is clearer. Sound right?"
User: "Yeah, that's fair."
Skill: [adds to WIP ledger Parked shapes subsection: shape="real-time updates", outcome_question="how often does the outcome 'real-time' serves actually trigger? what breaks if not met?", introduced_by=operator, resolved=false]

### Example (anti-pattern — don't do this)

User: "I want to use Postgres."
Skill: "Great choice, Postgres is excellent. Moving on."

This is the failure mode. Specifics get adopted without an external-source check. Always apply the verifiability rule.

### Anti-patterns

- ❌ **Classifying a shape as constraint without an external source citation.** "It's a constraint because the operator feels strongly" is preference, not external grounding. Default to peel-back.
- ❌ **Accepting non-categorical justifications as external sources.** "Team consensus", "we always do it this way", "it's our style" do not match any of the five categories. Treat as preference.
- ❌ **Running V1/future-pull on the preference path.** Sub-classification only applies after a source is cited. Parked shapes are not classified.
- ❌ **Skipping the source citation when the specific "obviously" looks like a constraint.** Even AWS or Postgres needs an explicit category + citation. The whole point is to surface untested assumptions.
- ❌ **Letting a parked shape escape Phase 1 without an outcome-question.** Every Parked-shapes entry has its outcome-question filled in.

### Reverse sunk-cost check (research/build-vs-buy phase only)

In a research / build-vs-buy phase (currently lives in `/solution`'s RESEARCH phase), when an existing tool was found that satisfies a chunk, apply Technique D's verifiability rule to the operator's stated preference for building:

> "Is 'we want to build this ourselves' externally sourced — a mandate, contract, regulator requirement, or factual constraint that prevents adopting [tool name]? If yes, cite the source and we record the rejection. If no, this is a preference — the bar for rejecting [tool name] must be specific functional gaps or constraint conflicts, not preference itself."

This fights the inverse failure mode: dismissing a good existing tool because the operator is emotionally invested in building. The verifiability rule applies symmetrically — the same standard that prevents shapes from masquerading as constraints during shape-discovery prevents preferences from masquerading as constraints during research.

---

## Technique B — Alternative framings (2-3 times per the consuming skill's discovery phase)

**Skill-specific framing of what Tech-B challenges:**

- **`/discover`'s Tech-B** fires on alternative **outcome** framings — the 4-way complexity spectrum runs from full-custom problem → no-build problem. The operator is being asked which *problem framing* they actually want to solve.
- **`/solution`'s Tech-B** fires on alternative **shape** framings — the same 4-way complexity spectrum applied to candidate shapes, where No-build = adopt an existing tool / nothing new built. The operator is being asked which *shape* solves the already-agreed problem.

In both cases the 4-option structure below is identical; the substantive content of each option differs by skill.

**When to fire:**

1. **Mandatory turn 1, immediately after Phase 0 completes (in /discover) or Phase 0 SHAPE-DISCOVER opens (in /solution)** — fire the 4-option frame *before* asking any other question. By turn 3, the operator has typed multiple paragraphs inside the original frame; firing at turn 1 surfaces alternatives while the cost of switching is still low.
2. When a major direction emerges later in the phase (architectural direction in /discover; shape direction in /solution).
3. Before the skill proposes moving to its next phase (DISCOVER → next phase in /discover; SHAPE-DISCOVER → CHUNK in /solution).

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

## Technique C — Red-team pass (its own phase in each consuming skill)

**When to fire:** Once per skill flow, as a dedicated red-team phase. Not optional. Not skippable. Even single-chunk simple problems get a red-team pass.

**Where the mechanics live:** The *mechanics* of running a red-team pass — mode-shift announcement, severity classification (CRITICAL / DISCUSS / MINOR), finding format, operator response patterns (Accept / Dismiss / Defer), and exit criteria — are defined once in `red-team-protocol.md`. Consult that file for the operational details. Tech-C in this file covers the underlying *technique* (why red-teaming counters sycophancy); the protocol file covers the *how*.

**Where the check categories live:** The list of *what* the red-team checks for is skill-specific — it names the kinds of conclusions the upstream phase produced. Each consuming skill's `SKILL.md` defines its own check list in its red-team phase section:

- `/discover` red-teams **outcomes**: contradictions in outcomes, untested specifics that should have been Tech-D'd, missing concerns, scope drift in the problem framing, future-pull contamination of the outcome statement, existence question (do you even need to solve this?).
- `/solution` red-teams **shapes and chunks**: contradictions between shape choices, untested shape commitments, missing concerns at the shape level, scope creep in chunks, dependency gaps between chunks, future-pull contamination of shape decisions, existence question at the shape level (is there an existing tool that obviates this whole shape?).

The shared check categories that recur across both (contradictions, untested specifics, missing concerns, future-pull contamination, existence question) get tailored language per skill; the protocol file does not enumerate them.

**Tech-C as anti-sycophancy:** the technique's job is to switch the LLM out of collaborative mode and into adversarial mode for one phase. Without the mode shift, the LLM keeps building toward what's already on the page. With it, the LLM tries to break what's been concluded — and the friction surfaces exactly the kind of issues Tech-B and Tech-D were supposed to catch but didn't.

---

## How the techniques interact

- **Technique D feeds Technique C.** Specifics that *should* have been classified by D but weren't are exactly what C catches. If C is finding lots of unclassified specifics, the LLM is failing at D and should improve.
- **Technique B feeds Technique D.** Choosing a frame in B makes some specifics constraints (locked in by the framing) and others choices (still open). D operates on both.
- **Technique C is the safety net.** B and D run during exploration; C runs at commitment. By the time C runs, B and D should have caught most issues — C catches what they missed.

If C is finding a lot of CRITICAL issues, it means B and D are weak. That's a signal the skill prompt needs improvement, not a sign that C is doing its job well.
