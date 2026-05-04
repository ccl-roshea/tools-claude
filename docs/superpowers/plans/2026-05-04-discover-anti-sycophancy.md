# /discover Anti-Sycophancy Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement nine anti-sycophancy hardening mechanisms in the `/discover` skill, plus a new artifact-gates reference file, so future discoveries surface premise challenges, classify all specifics (including operator quotes), distinguish V1-driven from future-pull constraints, audit chunks before exiting CHUNK phase, and enforce provenance/alternatives/justifications at artifact write time.

**Architecture:** Surgical additions only (Shape A from spec). Each mechanism is a targeted edit to one or two files. One new reference file (`artifact-gates.md`) is created. No global prose-tightening pass on existing content.

**Tech Stack:** Markdown documentation in `skills/discover/` and its `references/` subdirectory. No code, no automated tests. Validation is an empirical mental walkthrough on the PM agent input that motivated the spec (see Task 12).

---

## Spec reference

This plan implements `docs/superpowers/specs/2026-05-04-discover-anti-sycophancy-design.md`. Mechanism numbers below match the spec's Mechanism 1-9 numbering.

## Spec open-question resolutions

The spec's "Open questions for the implementation plan" are resolved here so the executor can apply them consistently:

1. **Phase 0 prompt exact wording:** see Task 3 step 2 — the prompt is fixed text quoted in the SKILL.md edit.
2. **Per-phase ledger rendering:** fenced text block (not table). Format defined in Task 8 step 3.
3. **Artifact-gate failure-message format:** one bulleted list grouped by gate name. Defined in Task 10 step 1.
4. **Cross-reference style for the four gates:** by name (e.g., "Constraints provenance gate"), not by number. Number labels in `artifact-gates.md` are headings only; cross-references use the names. Defined in Task 10 step 1.
5. **Resume interaction with Phase 0:** Phase 0 does NOT re-run on resume. The WIP file's `Premise check` section is preserved across resume. If `/discover resume <slug>` is invoked against a WIP that predates the Phase 0 discipline (no `Premise check` section), the agent notes the absence and offers to either run a backfill premise check turn or skip and resume normally. Defined in Task 3 step 4.

## Files affected

| File | Change | Tasks that touch it |
|---|---|---|
| `skills/discover/SKILL.md` | New Phase 0; updates to Phases 1-5 | 3, 4, 5, 6, 7, 8, 10 |
| `skills/discover/references/anti-sycophancy.md` | Tech-B 4-option, Tech-D trigger expansion + sub-classification, Tech-C future-pull | 1, 2, 4, 7 |
| `skills/discover/references/chunking-guidelines.md` | Per-chunk audit, per-open-choice self-challenge, mandatory action on self-flag | 5, 6 |
| `skills/discover/references/dispatch-protocol.md` | Remove chunk-complexity assessment (moved to CHUNK phase) | 5 |
| `skills/discover/references/artifact-template.md` | Add label/source/alternatives/justification fields | 9 |
| `skills/discover/references/artifact-gates.md` | NEW — four write-time validation gates | 10 |
| `skills/discover/references/checkpoint-protocol.md` | Add ledger entry shape to WIP file format | 8 |
| `skills/discover/LIMITATIONS.md` | Add new known limits | 11 |

## Commit cadence

One commit per task. Commit messages use the existing project convention (`feat(discover):`, `docs(discover):`).

---

## Task 1: Tech-D — Trigger Expansion (Sixth Category)

**Implements:** Mechanism 3.

**Files:**
- Modify: `skills/discover/references/anti-sycophancy.md` — Tech-D section, after the existing trigger list, before the "The prompt:" heading

- [ ] **Step 1: Read the current Tech-D trigger list**

Run: `cat -n skills/discover/references/anti-sycophancy.md | sed -n '15,35p'`

Confirm the existing trigger list is at lines 19-25 (named technology, protocol/pattern, architectural choice, library/framework, concrete number).

- [ ] **Step 2: Edit `anti-sycophancy.md` — add the sixth category**

Find this exact block (the existing five-item bulleted list under "Examples of 'specific implementation details':"):

```markdown
- A named technology ("Postgres", "AWS", "Next.js", "Azure")
- A protocol or pattern ("REST", "GraphQL", "event-driven")
- An architectural choice ("microservices", "monorepo", "serverless")
- A library or framework ("React", "FastAPI", "Tailwind")
- A concrete number that wasn't justified ("3-week MVP", "$500/month budget")
```

Replace with:

```markdown
- A named technology ("Postgres", "AWS", "Next.js", "Azure")
- A protocol or pattern ("REST", "GraphQL", "event-driven")
- An architectural choice ("microservices", "monorepo", "serverless")
- A library or framework ("React", "FastAPI", "Tailwind")
- A concrete number that wasn't justified ("3-week MVP", "$500/month budget")
- A behavioral default or policy quote ("default-ON [X]", "always [Y] before [Z]", "never [W]", "[X] is the source of truth"). Also: any operator-quoted rationale that becomes the support for a design rule (e.g., "we don't want a PM agent without expertise..." → "default-ON it-ops consultation"). Any rule about agent behavior whose only support is operator preference, not external constraint.
```

- [ ] **Step 3: Edit `anti-sycophancy.md` — add the sixth-category trigger phrasing**

Find the existing single "The prompt:" block (currently a single quoted prompt). Below the existing prompt block, add a new subsection.

After this exact existing block:

```markdown
**The prompt:**

> "You mentioned [X]. Is that a constraint — something imposed on you externally (company policy, existing infra, compliance, team decision) — or a choice you're making right now? If it's a choice, I want to explore alternatives before we lock it in."
```

Insert this immediately after (before "**If constraint:**"):

```markdown
**Trigger phrasing for the sixth category (behavioral defaults / policy quotes):**

> "You stated [Q]. The rule it justifies is [R]. Is [R] a constraint — something imposed externally — or a preference that should be pressure-tested? Alternatives to [R]: ..."

The sixth category often surfaces when the operator phrases a preference as a justification ("we don't want X without Y"). The agent must classify the *rule the quote justifies*, not the quote itself.
```

- [ ] **Step 4: Verify by re-reading the Tech-D section**

Run: `sed -n '15,75p' skills/discover/references/anti-sycophancy.md`

Confirm:
- The sixth bullet is present in "Examples of 'specific implementation details'"
- The new "Trigger phrasing for the sixth category" subsection is present immediately after the original "The prompt:" block
- The flow reads: trigger list → original prompt → sixth-category prompt → "If constraint:" / "If choice:" branches

- [ ] **Step 5: Commit**

```bash
git add skills/discover/references/anti-sycophancy.md
git commit -m "feat(discover): expand Tech-D triggers to include behavioral defaults and policy quotes"
```

---

## Task 2: Tech-D — Constraint Sub-classification (V1 vs Future-Pull)

**Implements:** Mechanism 4.

**Files:**
- Modify: `skills/discover/references/anti-sycophancy.md` — Tech-D section, "If constraint:" handling

- [ ] **Step 1: Read the current "If constraint:" block**

Run: `sed -n '28,50p' skills/discover/references/anti-sycophancy.md`

Confirm the current text reads (approximately):

```markdown
**If constraint:** record it in the running constraints list. Note who/what imposed it and why it can't be changed. Move on.

**If choice:** briefly present 2-3 alternatives covering the realistic option space. The user picks one or keeps the original — but now it's a *tested* choice, not an untested assumption. Record the alternatives considered in the "Tested choices" list.
```

- [ ] **Step 2: Edit `anti-sycophancy.md` — replace the "If constraint:" block with sub-classification**

Replace this exact block:

```markdown
**If constraint:** record it in the running constraints list. Note who/what imposed it and why it can't be changed. Move on.
```

With:

```markdown
**If constraint:** do NOT record yet. First, sub-classify by scope-of-origin with this follow-up:

> "Is [constraint] driven by V1 needs, or by out-of-scope/future needs (V2 features, hypothetical scale, undeployed systems)?"

**Two outcomes:**

- **V1-driven** → record as `[V1] constraint: <text>` (note who/what imposed it and why it can't be changed). Move on.
- **Future-pull** → challenge: *"What specifically about V1 requires this? Would V1 work without it?"* The operator must either:
  - Articulate a concrete V1 impact → record as `[future-pull, V1-justified: <reason>] constraint: <text>`
  - Acknowledge it's V2-driven → either drop from V1 design, or record as `[V2-driven, deferred] note: <text>` (NOT as a V1 constraint)

The agent MUST run sub-classification on every constraint, not only ones that "feel" V2-ish. Future-pull constraints often look reasonable on first encounter; they reveal themselves only when the question is asked explicitly.
```

- [ ] **Step 3: Verify by re-reading the constraint-handling section**

Run: `sed -n '28,55p' skills/discover/references/anti-sycophancy.md`

Confirm:
- The sub-classification follow-up is present
- Both V1-driven and future-pull outcomes are documented
- The "must run on every constraint" anti-pattern guard is present
- The "If choice:" block immediately following is unchanged

- [ ] **Step 4: Commit**

```bash
git add skills/discover/references/anti-sycophancy.md
git commit -m "feat(discover): sub-classify constraints as V1-driven or future-pull in Tech-D"
```

---

## Task 3: Phase 0 — Premise Check

**Implements:** Mechanism 1.

**Files:**
- Modify: `skills/discover/SKILL.md` — add new Phase 0 section before Phase 1; update phases-list and session-startup references

- [ ] **Step 1: Read SKILL.md's "The six phases" section and Phase 1 entry**

Run: `sed -n '49,80p' skills/discover/SKILL.md`

Confirm:
- "The six phases" enumerated as items 1-6
- "Session startup" section follows
- "Phase 1: DISCOVER" begins after that

- [ ] **Step 2: Edit `SKILL.md` — update "The six phases" header and list**

Find this exact block:

```markdown
## The six phases

You execute the following phases in order. Within each phase you can loop, but you don't skip ahead. Each phase has explicit entry and exit criteria.

1. **DISCOVER** — Socratic exploration with continuous Technique D (constraints vs. choices) and 2-3 invocations of Technique B (alternative framings)
2. **CHUNK** — Decompose into executor-sized chunks if needed; compute execution order
3. **RED-TEAM** — Adversarial pass on the conclusions (Technique C)
4. **RESEARCH** (Phase 3.5) — Active build-vs-buy research; restructure chunks based on findings
5. **ARTIFACT** — Write and commit the discovery document
6. **DISPATCH** — Sequentially launch /superpowers for each chunk

The flow is: gather understanding → decompose → attack → research → write → execute. Each phase narrows commitment from "open exploration" to "executor-ready problem statements."
```

Replace with:

```markdown
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
```

- [ ] **Step 3: Edit `SKILL.md` — add Phase 0 section between "Session startup" and "Phase 1: DISCOVER"**

Find this exact line (the start of Phase 1):

```markdown
## Phase 1: DISCOVER
```

Insert this entire block immediately above it:

```markdown
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

```

- [ ] **Step 4: Edit `SKILL.md` — update "Session startup" section to mention Phase 0**

Find this exact block:

```markdown
**New session** (plain invocation):
- After the first exchange, derive a provisional topic slug and create `docs/discovery/.wip/<slug>.wip.md`.
- If `docs/discovery/.wip/` already contains `.wip.md` files, note them to the operator before continuing: "Found in-progress session(s): `<slug>` (Phase: X, Turn: N). Run `/discover resume <slug>` to resume, or continue for a new session."
```

Replace with:

```markdown
**New session** (plain invocation):
- Begin with Phase 0 (PREMISE CHECK). Do not derive the slug or create the WIP file until after Phase 0 is recorded — the slug derivation may use the restated outcome from Phase 0 step 1.
- After Phase 0 completes (or after the first exchange if Phase 0 took only one turn), derive a provisional topic slug and create `docs/discovery/.wip/<slug>.wip.md`. The WIP file's transcript starts with the Phase 0 turn(s) recorded under a `Premise check` section, then the regular transcript begins.
- If `docs/discovery/.wip/` already contains `.wip.md` files, note them to the operator BEFORE Phase 0: "Found in-progress session(s): `<slug>` (Phase: X, Turn: N). Run `/discover resume <slug>` to resume, or continue for a new session." (Phase 0 does not run until the operator confirms a new session.)
```

- [ ] **Step 5: Verify by re-reading SKILL.md**

Run: `sed -n '49,180p' skills/discover/SKILL.md`

Confirm:
- "The seven phases" header (not "six")
- Phase 0 listed as item 0 in the list
- "Session startup" mentions Phase 0 sequencing
- New "Phase 0: PREMISE CHECK" section present, with: entry, exit, three steps, anti-pattern guard, resume behavior, anti-patterns
- "Phase 1: DISCOVER" still present immediately after Phase 0

- [ ] **Step 6: Commit**

```bash
git add skills/discover/SKILL.md
git commit -m "feat(discover): add Phase 0 mandatory premise check"
```

---

## Task 4: Tech-B — 4-Option Frame, First Firing at Turn 1

**Implements:** Mechanism 2.

**Files:**
- Modify: `skills/discover/references/anti-sycophancy.md` — Tech-B section
- Modify: `skills/discover/SKILL.md` — Phase 1 "Periodic: Technique B" subsection

- [ ] **Step 1: Read the current Tech-B section in `anti-sycophancy.md`**

Run: `sed -n '64,100p' skills/discover/references/anti-sycophancy.md`

Confirm the existing structure: "When to fire" with 3 numbered firing points; "The prompt:" block with the 3-option framing prompt; "Critical principle: equal weight across the complexity spectrum"; example.

- [ ] **Step 2: Edit `anti-sycophancy.md` — update Tech-B "When to fire" list**

Find this exact block:

```markdown
**When to fire:** At natural convergence points in Phase 1 (DISCOVER). Specifically:

1. After the initial problem framing stabilizes (typically turns 3-5)
2. When a major architectural direction emerges
3. Before the skill proposes moving from DISCOVER to CHUNK

The LLM should not fire this every turn. It should sense when the conversation is *settling* on a frame and use that as the cue.
```

Replace with:

```markdown
**When to fire:**

1. **Mandatory turn 1, immediately after Phase 0 completes** — fire the 4-option frame *before* asking any other discovery question. By turn 3, the operator has typed multiple paragraphs inside the original frame; firing at turn 1 surfaces alternatives while the cost of switching is still low.
2. When a major architectural direction emerges later in Phase 1.
3. Before the skill proposes moving from DISCOVER to CHUNK.

The LLM should not fire this every turn between firings. It should sense when the conversation is *settling* on a frame and use that as the cue for firings 2 and 3.
```

- [ ] **Step 3: Edit `anti-sycophancy.md` — replace the 3-option prompt with the 4-option prompt**

Find this exact block:

```markdown
**The prompt:**

> "Before we go further, let me offer three different ways to think about this problem:
>
> 1. [Current frame] — what we've been building toward
> 2. [Alternative frame] — reframes the problem as [X]
> 3. [Reductive frame] — what if the real problem is actually just [simpler thing]?
>
> Which resonates, or is the real answer a mix?"
```

Replace with:

```markdown
**The prompt:**

> "Before we go further, four ways to think about this problem:
>
> 1. **[Complex frame]** — what we've been building toward. Full custom system.
> 2. **[Middle-build frame]** — same outcome, smaller surface. Reuse more, build less.
> 3. **[Low-build frame]** — minimal new code. Glue + configuration over existing tools.
> 4. **[No-build frame]** — outcome reached without writing code. Workflow change, existing tool adoption, accepting the pain.
>
> Which resonates, or is the answer a mix?"
```

- [ ] **Step 4: Edit `anti-sycophancy.md` — replace the "Critical principle" block with the updated text**

Find this exact block:

```markdown
**Critical principle: equal weight across the complexity spectrum.** Option 3 (reductive) must always be present, but it is not a "have you considered doing less?" checkbox. The reductive frame must be evaluated with the same rigor as the complex frames. The right answer might be "yes, this really is a distributed system" or "actually, a single shell script does it."

The bias the LLM must fight: Socratic exploration tends to expand problems. Without the reductive frame, conversations drift toward bigger, more architected solutions. Including the reductive frame keeps the full complexity space honest.
```

Replace with:

```markdown
**Critical principle: equal weight across the full complexity spectrum.** All four options must be plausible, concrete paths the operator could actually take — same bar across the board. Option 4 (no-build) is not a formality; it is a credible alternative the operator must be able to evaluate seriously. If the agent cannot construct a credible no-build frame for the problem, that is itself a signal the framing is too narrow and needs reconsideration — re-state the outcome at a higher level and try again.

The bias the LLM must fight: Socratic exploration tends to expand problems. Without the no-build frame, conversations drift toward bigger, more architected solutions. Including all four frames keeps the full complexity space honest.
```

- [ ] **Step 5: Edit `anti-sycophancy.md` — replace the "Example (good reframings)" block to use 4 options**

Find this exact block:

```markdown
### Example (good reframings for "deploy agents for my team")

1. **Current frame:** A multi-service platform with a portal, orchestrator, and specialist agents communicating via A2A.
2. **Alternative frame:** A shared chat workspace where each "agent" is just a Claude Code skill team members invoke via slash commands. No platform. No orchestrator. Just shared skills in a git repo.
3. **Reductive frame:** A shared bookmark folder pointing to a few well-crafted prompts the team can paste into ChatGPT/Claude as needed. No code at all.

The user might pick frame 2, or pick a hybrid of 1 and 2, or realize frame 3 is genuinely sufficient. All three deserve serious consideration.
```

Replace with:

```markdown
### Example (good reframings for "deploy agents for my team")

1. **Complex frame:** A multi-service platform with a portal, orchestrator, and specialist agents communicating via A2A.
2. **Middle-build frame:** A shared chat workspace where each "agent" is a Claude Code skill team members invoke via slash commands. No platform. No orchestrator. Skill packages built and shared in a git repo.
3. **Low-build frame:** A small set of well-crafted prompts saved in a shared git repo, plus a README that describes when to use each. Team uses Claude Code's existing skills mechanism to load them.
4. **No-build frame:** Document a few prompt patterns in the team wiki. Team members paste into Claude/ChatGPT as needed. No code at all.

The user might pick any frame, or a hybrid. All four deserve serious consideration.
```

- [ ] **Step 6: Edit `anti-sycophancy.md` — update the "Anti-pattern: weak reductive frame" subsection**

Find this exact block:

```markdown
### Anti-pattern: weak reductive frame

Don't write: "3. A simpler version of frame 1." That's not a real alternative — it's a hedge. The reductive frame must be *qualitatively different* in approach, not just a smaller version of the complex one.
```

Replace with:

```markdown
### Anti-pattern: weak no-build frame

Don't write: "4. Use a spreadsheet" or "4. Just don't build it" as a no-build placeholder. Don't write a no-build frame that the agent itself doesn't believe in. Each frame — including no-build — must be a *qualitatively different, credible* path the operator could actually take. If the no-build frame feels forced, re-examine the outcome restatement: the framing may be at the wrong level of abstraction.
```

- [ ] **Step 7: Edit `SKILL.md` — update the "Periodic: Technique B" subsection in Phase 1**

Find this exact block in `skills/discover/SKILL.md`:

```markdown
### Periodic: Technique B (alternative framings)

Fire 2-3 times per session at natural convergence points:
1. After the initial framing stabilizes (typically turns 3-5)
2. When a major architectural direction emerges
3. Before you propose moving from DISCOVER to CHUNK

**Action:** present 3 framings of the entire problem:

> "Before we go further, let me offer three different ways to think about this problem:
>
> 1. [Current frame] — what we've been building toward
> 2. [Alternative frame] — reframes the problem as [X]
> 3. [Reductive frame] — what if the real problem is actually just [simpler thing]?"

**Critical:** option 3 must be a *qualitatively different, simpler* approach — not "a smaller version of option 1." The reductive frame fights complexity bias. The right answer might be a distributed system or a single shell script; you must explore the full complexity spectrum with equal rigor.
```

Replace with:

```markdown
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
```

- [ ] **Step 8: Edit `SKILL.md` — update the "Skipping Technique B" anti-pattern entry**

Find this exact line in Phase 1's anti-patterns section:

```markdown
- ❌ **Skipping Technique B.** Without alternative framings, the conversation drifts toward the first frame that emerged. Fire B at convergence points.
```

Replace with:

```markdown
- ❌ **Skipping Technique B.** Without alternative framings, the conversation drifts toward the first frame that emerged. Fire B at turn 1, then at convergence points.
- ❌ **Filler no-build frame.** A no-build option you don't believe in is worse than no option — it makes the prompt look like it covered alternatives when it didn't. If the no-build frame feels forced, re-state the outcome at a higher level.
```

- [ ] **Step 9: Verify by re-reading both updated sections**

Run: `sed -n '64,110p' skills/discover/references/anti-sycophancy.md`

Run: `grep -n -A 25 "Periodic: Technique B" skills/discover/SKILL.md`

Confirm:
- 4-option prompt is present in both files
- Turn-1 firing is the first item in both files' "When to fire" lists
- "Critical principle" mentions all four options
- "Skipping Technique B" anti-pattern is updated in SKILL.md, plus a new "Filler no-build frame" anti-pattern

- [ ] **Step 10: Commit**

```bash
git add skills/discover/references/anti-sycophancy.md skills/discover/SKILL.md
git commit -m "feat(discover): Tech-B becomes 4-option spectrum, first firing at turn 1"
```

---

## Task 5: Chunking — Mandatory Action on Self-Flag

**Implements:** Mechanism 6.

**Files:**
- Modify: `skills/discover/SKILL.md` — Phase 2 (CHUNK) and Phase 5 (DISPATCH)
- Modify: `skills/discover/references/chunking-guidelines.md` — add the mandatory-action rule
- Modify: `skills/discover/references/dispatch-protocol.md` — remove chunk-complexity-assessment (it now lives in CHUNK phase)

- [ ] **Step 1: Read the relevant existing sections**

Run: `sed -n '167,225p' skills/discover/SKILL.md`

Run: `sed -n '385,410p' skills/discover/SKILL.md`

Run: `sed -n '20,65p' skills/discover/references/dispatch-protocol.md`

Confirm:
- Phase 2 currently has steps 1-5 ending in "iterate with operator until they approve"
- Phase 5 currently has step 2a "Assess chunk complexity for recursion"
- `dispatch-protocol.md` has a "Chunk-complexity assessment (step 0)" section

- [ ] **Step 2: Edit `SKILL.md` — add a new step to Phase 2 BEFORE the existing "iterate" step**

Find this exact block in `skills/discover/SKILL.md` (Phase 2 section):

```markdown
**Step 5: iterate** with the operator until they approve. They may merge chunks, split further, reorder, or rename.
```

Replace with:

```markdown
**Step 5: chunk-overload signal check (mandatory).** For each proposed chunk, count how many of these signals fire:

1. **Open-choice density:** the "Open choices" list has 3+ independent items.
2. **Lingering vagueness:** the problem statement still feels vague or multi-faceted when read aloud — a fresh /superpowers session would still need clarification on basic intent.
3. **Sub-domain spread:** the chunk spans multiple sub-domains (e.g., "Portal" = UX + auth + APIs).
4. **Red-team flag:** Phase 3 has not yet run, but if your own draft red-team thinking flags this chunk as scope-creep-prone or with unresolved untested specifics, count it.

If 2 or more signals fire on a chunk, you MUST present a sub-decomposition in-line, before moving on:

> "Chunk N as written has [list signals that fired]. Here's how I'd split it into 2-3 sub-chunks: [proposal]. Want me to apply this split, or override and keep it as one chunk?"

The operator may override. If they override, record the override in the artifact under that chunk's section as a one-liner: *"This chunk was flagged for split (signals: X, Y); operator overrode with reason: Z."*

Do NOT punt this to dispatch-time. The signals are checked here, the action is taken here.

**Step 6: iterate** with the operator until they approve. They may merge chunks, split further, reorder, or rename.
```

- [ ] **Step 3: Edit `SKILL.md` — remove step 2a from Phase 5 (DISPATCH)**

Find this exact block in `skills/discover/SKILL.md` (Phase 5 section):

```markdown
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
```

Replace with:

```markdown
a. **Compose the dispatch prompt.** Combine:
```

(Note: the entire "Assess chunk complexity for recursion" sub-step is removed. The first sub-step under "Step 2: for each chunk in execution order:" becomes "a. Compose the dispatch prompt." Sub-steps that follow shift letters: b becomes a, c becomes b, etc. Renaming is in step 4 below.)

- [ ] **Step 4: Edit `SKILL.md` — re-letter the remaining sub-steps in Phase 5 step 2**

Find each of these existing sub-step letters in Phase 5 step 2 and shift them up by one (since `a` was the removed one):

- `b. **Compose the dispatch prompt.**` → `a. **Compose the dispatch prompt.**`
- `c. **Launch via Agent tool:**` → `b. **Launch via Agent tool:**`
- `d. **Wait for completion.**` → `c. **Wait for completion.**`
- `e. **Extract decisions.**` → `d. **Extract decisions.**`
- `f. **Update the artifact.**` → `e. **Update the artifact.**`
- `g. **Move to the next chunk**` → `f. **Move to the next chunk**`

Apply each rename with a separate `Edit` (since each letter+content combination is unique in the file).

- [ ] **Step 5: Edit `dispatch-protocol.md` — remove the "Chunk-complexity assessment (step 0)" section**

Find this exact block in `skills/discover/references/dispatch-protocol.md` (the entire section starting from the "## Chunk-complexity assessment (step 0)" header through the end of its anti-patterns subsection, ending just before "## Composing the dispatch prompt"):

```markdown
## Chunk-complexity assessment (step 0)

Before dispatching each chunk, check whether it's well-scoped for /superpowers or whether it would benefit from its own /discover pass first. The parent /discover pressure-tested the *root* framing, but chunks can still be too large or multi-decision for a single /superpowers session.

### Signals

For each chunk, count how many of these fire:

1. **Open-choice density.** Does the "Open choices" list have 3 or more independent items?
2. **Lingering vagueness.** Does the problem statement still feel vague or multi-faceted when read aloud — would a fresh /superpowers session still need clarification on basic intent?
3. **Sub-domain spread.** Does the chunk span multiple sub-domains (e.g., "Portal" = UX + auth + APIs)? Distinct sub-domains often deserve distinct framings.
4. **Red-team flag.** Did Phase 3's red-team mark this chunk as scope-creep-prone or with unresolved untested specifics?

### Decision rule

- **0–1 signals fire:** proceed directly to dispatch. Do *not* surface a "should we run /discover?" prompt — that's operator fatigue. The point is to flag chunks that genuinely need it, not to ask about every chunk.
- **2+ signals fire:** propose recursion to the operator:

  > "Chunk N (<name>) looks like it might still need its own discovery pass before /superpowers can plan it well. The signals: [cite which fired and why]. Want to run /discover on this chunk first, or proceed straight to /superpowers?"

### Operator response handling

- **Operator chooses /discover.** Recursively invoke the /discover skill on the chunk's problem statement, inheriting the parent's confirmed constraints. The output is a sub-discovery artifact at `docs/discovery/<parent-slug>/<chunk-slug>.md`. Then dispatch the sub-chunks via the same Phase 5 logic (which itself includes step 0 — recursion can compound, operator-driven).
- **Operator declines /discover.** Proceed straight to dispatch with the chunk as-is. Record the operator's response in the artifact's "Phase 5 — Chunk-complexity assessment" section.
- **Operator says "ask me later" or similar:** treat as decline for now; revisit if downstream chunks reveal the chunking was wrong.

### Honesty about borderline calls

If you assess 2 signals but think the recursion is unnecessary anyway (e.g., the sub-domains integrate within a known pattern, the choices are well-bounded with clear criteria), say so in your proposal:

> "Chunk N fires 2 signals (1 and 3). Honest take: borderline — [reason]. Recommend proceed with /superpowers unless you see specific framing risk I'm missing."

Don't pretend every borderline case is a real recursion candidate. The operator's time is limited.

### Anti-patterns

- ❌ **Surfacing the prompt on every chunk.** That's not assessment, that's outsourcing the decision.
- ❌ **Auto-recursing without operator approval.** Recursion compounds — uncontrolled depth blows the token budget and operator attention.
- ❌ **Skipping the assessment because "the parent already discovered."** The parent discovery pressure-tested the root framing; chunks can still be too large.
- ❌ **Treating 2 signals as automatic recursion.** 2 is a *threshold for surfacing*, not for recursing.

```

Replace with this single replacement note (so dispatch-protocol.md doesn't suddenly leak signal-check logic):

```markdown
## Chunk-complexity assessment

Chunk-overload signals are checked at end of CHUNK phase (Phase 2), not at dispatch time. See `chunking-guidelines.md` for the signal list and the per-chunk audit. By the time DISPATCH runs, any chunk that tripped 2+ signals has already been split (or the operator has explicitly overridden the split, recorded in the artifact). Dispatch does not re-evaluate.

If a chunk's /superpowers session reveals the chunking was wrong despite the upstream check, fall back to the "When chunking turns out to be wrong" protocol below.

```

- [ ] **Step 6: Edit `dispatch-protocol.md` — update the "Sequential dispatch loop" pseudocode**

Find this exact block:

```markdown
```
For each chunk in execution order:
  0. Assess chunk complexity for recursion (see "Chunk-complexity assessment" below)
       — if 2+ signals fire, propose recursive /discover; operator decides
  1. Compose the dispatch prompt (see "Composing the prompt" below)
  2. Launch via Agent tool (foreground, main workspace)
  3. Operator interacts with /superpowers normally
  4. On completion: extract decisions, record as upstream context for downstream chunks
  5. Update artifact with link to chunk's plan output
  6. Move to next chunk
```
```

Replace with:

```markdown
```
For each chunk in execution order:
  1. Compose the dispatch prompt (see "Composing the prompt" below)
  2. Launch via Agent tool (foreground, main workspace)
  3. Operator interacts with /superpowers normally
  4. On completion: extract decisions, record as upstream context for downstream chunks
  5. Update artifact with link to chunk's plan output
  6. Move to next chunk
```

Note: chunk-overload signals were checked at the end of CHUNK phase (Phase 2). Dispatch does not re-check.
```

- [ ] **Step 7: Edit `chunking-guidelines.md` — add a "Chunk-overload signals (mandatory check)" section**

Find this exact line in `skills/discover/references/chunking-guidelines.md`:

```markdown
## How to propose chunks
```

Insert this block immediately above it:

```markdown
## Chunk-overload signals (mandatory check)

After proposing chunks (and before iterating with the operator to approve), the agent MUST check each chunk against four overload signals:

1. **Open-choice density:** the chunk's "Open choices" list has 3+ independent items.
2. **Lingering vagueness:** the chunk's problem statement still feels vague or multi-faceted when read aloud.
3. **Sub-domain spread:** the chunk spans multiple sub-domains.
4. **Red-team flag:** the agent's own draft red-team thinking flags the chunk as scope-creep-prone or with unresolved untested specifics.

If 2 or more signals fire on a chunk, the agent MUST propose a sub-decomposition in-line, before iterating with the operator. The operator may override; the override is recorded in the artifact as a one-liner under that chunk's section.

This check happens at end of CHUNK phase, not at dispatch. By the time DISPATCH runs, any chunk that tripped 2+ signals has either been split or has an explicit override on record.

```

- [ ] **Step 8: Verify by re-reading the modified sections**

Run: `sed -n '167,235p' skills/discover/SKILL.md`

Run: `sed -n '385,420p' skills/discover/SKILL.md`

Run: `sed -n '20,55p' skills/discover/references/dispatch-protocol.md`

Run: `grep -n "Chunk-overload signals" skills/discover/references/chunking-guidelines.md`

Confirm:
- Phase 2 has new "Step 5: chunk-overload signal check (mandatory)" before "Step 6: iterate"
- Phase 5 step 2 starts with "a. Compose the dispatch prompt" (not the removed assessment)
- `dispatch-protocol.md` "Chunk-complexity assessment" section is replaced with a short pointer to chunking-guidelines.md
- `chunking-guidelines.md` has the new "Chunk-overload signals (mandatory check)" section before "How to propose chunks"

- [ ] **Step 9: Commit**

```bash
git add skills/discover/SKILL.md skills/discover/references/dispatch-protocol.md skills/discover/references/chunking-guidelines.md
git commit -m "feat(discover): move chunk-overload signal check to CHUNK phase, mandatory action on 2+ signals"
```

---

## Task 6: Chunking — Per-Chunk Audit + Per-Open-Choice Self-Challenge

**Implements:** Mechanism 7.

**Files:**
- Modify: `skills/discover/SKILL.md` — Phase 2 (CHUNK)
- Modify: `skills/discover/references/chunking-guidelines.md`

- [ ] **Step 1: Read Phase 2's current end-state**

Run: `sed -n '195,240p' skills/discover/SKILL.md`

Confirm Phase 2 now ends with the new Step 5 (chunk-overload signal check, from Task 5) followed by Step 6 (iterate).

- [ ] **Step 2: Edit `SKILL.md` — insert per-chunk audit step BETWEEN "Step 5" and "Step 6"**

Find this exact line in Phase 2:

```markdown
**Step 6: iterate** with the operator until they approve. They may merge chunks, split further, reorder, or rename.
```

Insert this block immediately above it:

```markdown
**Step 5b: per-chunk audit (mandatory).** This audit runs at the same workflow point as Step 5's signal check, but unconditionally — whether or not Step 5's signals fired. For each chunk, the agent reads the chunk back to itself and writes the answers to the WIP file:

1. *"Could this chunk be split into 2-3 chunks with cleaner boundaries? If yes, propose. If no, justify."*
2. *For each open choice in this chunk: "Is this genuinely more answerable with executor context than now? If yes, why? If no, resolve it."*

**Outcomes for open choices:**

- **Survives self-challenge** → the open choice stays under "Open choices (for the executor to resolve)" in the artifact, AND a one-liner survival justification is recorded with it (e.g., *"deferred because the SDK's `requests` adapter may already cover retry; verifying in-chunk is cheaper than re-litigating here"*).
- **Does not survive** → the agent resolves it now, in this phase. The result moves to "Tested choices" if alternatives were considered, or to "Constraints" if it turns out to be a derived constraint. Removed from "Open choices."

The audit's outputs (split-or-not justification, per-open-choice survival justifications) feed directly into the artifact-time gates (see `references/artifact-gates.md`).

```

- [ ] **Step 3: Edit `chunking-guidelines.md` — add a "Per-chunk audit (mandatory)" section**

Find this exact line:

```markdown
## How to propose chunks
```

Insert this block immediately above it (it should land *after* the "Chunk-overload signals" section added in Task 5, but before "How to propose chunks"):

```markdown
## Per-chunk audit (mandatory)

After the chunk-overload signal check (above), the agent runs a per-chunk audit on every chunk — whether or not signals fired. The audit asks two questions and writes the answers to the WIP file:

1. **Split-or-not:** *"Could this chunk be split into 2-3 chunks with cleaner boundaries? If yes, propose. If no, justify."*
2. **Per-open-choice self-challenge:** for each open choice in the chunk, *"Is this genuinely more answerable with executor context than now? If yes, why? If no, resolve it."*

**Outcomes for open choices:**

- **Survives self-challenge** → kept in the artifact's "Open choices" list with a one-liner survival justification. This justification is later checked by the artifact-time "Open choices survival justification gate" (see `artifact-gates.md`).
- **Does not survive** → resolved in this phase. Result moves to "Tested choices" (with alternatives recorded) or to "Constraints" (if the resolution reveals a derived constraint).

The audit's outputs are load-bearing for the artifact gates. An open choice without a survival justification will block the artifact write.

```

- [ ] **Step 4: Verify**

Run: `sed -n '195,260p' skills/discover/SKILL.md`

Run: `grep -n -A 5 "Per-chunk audit" skills/discover/references/chunking-guidelines.md`

Confirm:
- Phase 2 has Steps 5, 5b, 6 in order
- Step 5b's two audit questions are clearly stated
- Open-choice outcome handling is present
- `chunking-guidelines.md` has the "Per-chunk audit (mandatory)" section
- Both files reference `artifact-gates.md` (which will be created in Task 10)

- [ ] **Step 5: Commit**

```bash
git add skills/discover/SKILL.md skills/discover/references/chunking-guidelines.md
git commit -m "feat(discover): add per-chunk audit and per-open-choice self-challenge to CHUNK phase"
```

---

## Task 7: RED-TEAM — Future-Pull Contamination Check

**Implements:** Mechanism 8.

**Files:**
- Modify: `skills/discover/SKILL.md` — Phase 3 (RED-TEAM) systematic-check list
- Modify: `skills/discover/references/anti-sycophancy.md` — Tech-C section

- [ ] **Step 1: Read Phase 3's existing systematic-check list**

Run: `sed -n '226,265p' skills/discover/SKILL.md`

Confirm Phase 3 step 2 lists 7 numbered checks (contradictions, untested specifics, missing concerns, scope creep, dependency gaps, existence question, stop-the-clock).

- [ ] **Step 2: Edit `SKILL.md` — add an 8th item to the Phase 3 systematic-check list**

Find this exact block:

```markdown
**Step 2: systematically check** for each chunk (or the single problem):

1. Contradictions between chunks or between constraints
2. Untested specifics — assumptions not classified by Technique D
3. Missing concerns — auth, observability, error handling, cost, performance, deployment, testing, security, data lifecycle
4. Scope creep — chunks bigger than they need to be
5. Dependency gaps — would chunk N actually need information from chunk M that isn't captured?
6. Existence question — is there an existing tool? (shallow check; Phase 3.5 does the active research)
7. Stop-the-clock check — what would happen if we stopped here?
```

Replace with:

```markdown
**Step 2: systematically check** for each chunk (or the single problem):

1. Contradictions between chunks or between constraints
2. Untested specifics — assumptions not classified by Technique D
3. Missing concerns — auth, observability, error handling, cost, performance, deployment, testing, security, data lifecycle
4. Scope creep — chunks bigger than they need to be
5. Dependency gaps — would chunk N actually need information from chunk M that isn't captured?
6. Existence question — is there an existing tool? (shallow check; Phase 3.5 does the active research)
7. Stop-the-clock check — what would happen if we stopped here?
8. **Future-pull contamination** — is any design element (constraint or choice) driven by features, scale, or systems that aren't in V1 scope? See severity guidance in `references/anti-sycophancy.md` Tech-C section.
```

- [ ] **Step 3: Edit `anti-sycophancy.md` — add future-pull contamination to Tech-C's "What the red-team checks" list**

Find this exact block in `skills/discover/references/anti-sycophancy.md`:

```markdown
For each chunk (or the single problem):

1. **Contradictions** — between chunks, between constraints, between constraints and chunk goals.
2. **Untested specifics** — assumptions that surfaced but were never classified as constraints-vs-choices. (This catches Technique D misses.)
3. **Missing concerns** — domains/topics that should have been explored but weren't. Cross-reference common architectural concerns: auth, observability, error handling, cost, performance, deployment, testing, security, data lifecycle.
4. **Scope creep** — chunks bigger than they need to be. Could a chunk be split? Is a chunk pulling in concerns that belong elsewhere?
5. **Dependency gaps** — would chunk N actually need information from chunk M that isn't captured in chunk M's outputs? If so, the dependency arrow is wrong or the upstream chunk is incomplete.
6. **Existence question** — "do you even need to build this?" Is there an existing tool or simpler approach? This is a shallow check from training data — Phase 3.5 does the active research. If a strong candidate surfaces here, record it as a CRITICAL finding and let Phase 3.5 verify.
7. **Stop-the-clock check** — what happens if you stop here? What would be lost vs. what would be gained?
```

Replace with:

```markdown
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
```

- [ ] **Step 4: Verify**

Run: `sed -n '226,275p' skills/discover/SKILL.md`

Run: `grep -n -A 12 "Future-pull contamination" skills/discover/references/anti-sycophancy.md`

Confirm:
- Phase 3 step 2 has 8 items, with #8 being "Future-pull contamination"
- Tech-C's checks list has 8 items, with #8 being "Future-pull contamination"
- Severity guidance (CRITICAL/DISCUSS/MINOR) is present
- The "expectation" paragraph notes that frequent RED-TEAM findings here imply Tech-D weakness

- [ ] **Step 5: Commit**

```bash
git add skills/discover/SKILL.md skills/discover/references/anti-sycophancy.md
git commit -m "feat(discover): add future-pull contamination check to RED-TEAM phase"
```

---

## Task 8: Per-Phase Ledger + Per-Fire Visibility

**Implements:** Mechanism 5.

**Files:**
- Modify: `skills/discover/references/checkpoint-protocol.md` — add ledger entry shape
- Modify: `skills/discover/SKILL.md` — add ledger discipline at each phase exit (Phase 1 through Phase 4); add per-fire visibility note to Phase 1's Tech-D section

- [ ] **Step 1: Read `checkpoint-protocol.md` to confirm current WIP format**

Run: `sed -n '1,50p' skills/discover/references/checkpoint-protocol.md`

Confirm the WIP file format section currently shows YAML front matter + Session transcript only.

- [ ] **Step 2: Edit `checkpoint-protocol.md` — add ledger entry shape after the existing transcript example**

Find this exact line at the end of the "WIP file format" section:

```markdown
YAML fields: `topic_slug`, `phase`, `turn_count`, `started`. Nothing else. All discovery content lives in the transcript.
```

Insert this block immediately after it:

```markdown
## Phase-exit ledger entries

In addition to the per-turn transcript, the WIP file accumulates a ledger entry at every phase exit (DISCOVER → CHUNK, CHUNK → RED-TEAM, RED-TEAM → RESEARCH, RESEARCH → ARTIFACT). Each ledger entry is appended to a `## Ledgers` section at the end of the WIP file (created on first use). Format:

```text
─── Phase exit: <FROM> → <TO> (turn N) ───
Constraints (M):
  [V1] <constraint text> (source: <operator quote / external source / inherited from chunk N>)
  [future-pull, V1-justified: <reason>] <constraint text> (source: ...)
  [V2-driven, deferred] note: <text> (source: ...)

Tested choices (K):
  <choice> (alternatives: <list of alternatives considered>)

Unclassified specifics that surfaced this phase (P):
  <specific> — needs Tech-D before phase exits

Want to address the unclassified item now, or proceed to <TO>?
```

- The "Constraints" line format mirrors the labels Tech-D produces (`[V1]`, `[future-pull, V1-justified: ...]`, `[V2-driven, deferred]`).
- The "Unclassified specifics" line is load-bearing: if this list is non-empty at phase exit and the operator chooses to proceed anyway, each unclassified specific is automatically carried into RED-TEAM as a CRITICAL finding.
- The ledger is shown to the operator before the phase-boundary commit, and the operator's decision (proceed / address unclassified items first) is recorded in the next turn block of the transcript.

```

- [ ] **Step 3: Edit `checkpoint-protocol.md` — update the "Phase-boundary commit" section to include ledger surfacing**

Find this exact block:

```markdown
## Phase-boundary commit

At each phase exit, before announcing to the operator that you're moving on:

1. Update the `phase` field in YAML to the next phase value.
2. Write the file.
3. Run:
   ```bash
   git add docs/discovery/.wip/<slug>.wip.md
   git commit -m "chore(discover): checkpoint <slug> — entering <NEXT-PHASE>"
   ```

Phase sequence: `DISCOVER` → `CHUNK` → `RED-TEAM` → `RESEARCH` → `ARTIFACT`
```

Replace with:

```markdown
## Phase-boundary commit

At each phase exit, before announcing to the operator that you're moving on:

1. **Surface the phase-exit ledger** to the operator (see "Phase-exit ledger entries" above). Wait for the operator's acknowledgement.
   - If unclassified specifics are present, the operator chooses whether to address them now or proceed (carrying them into RED-TEAM as CRITICAL findings).
2. **Append the ledger entry** to the `## Ledgers` section of the WIP file.
3. Update the `phase` field in YAML to the next phase value.
4. Write the file.
5. Run:
   ```bash
   git add docs/discovery/.wip/<slug>.wip.md
   git commit -m "chore(discover): checkpoint <slug> — entering <NEXT-PHASE>"
   ```

Phase sequence: `PREMISE CHECK` → `DISCOVER` → `CHUNK` → `RED-TEAM` → `RESEARCH` → `ARTIFACT`. (Phase 0 / PREMISE CHECK does not produce a ledger entry — it produces a `Premise check` section in the transcript instead.)
```

- [ ] **Step 4: Edit `SKILL.md` — add ledger discipline note to each phase's exit criterion**

For each of the four phases below, find the "**Exit:**" line and append a sentence about the ledger.

**Phase 1 (DISCOVER):** find:

```markdown
**Exit:** The operator agrees that discovery is sufficient, OR you propose moving on and the operator approves. Commit the WIP file with `phase: CHUNK` per `references/checkpoint-protocol.md`.
```

Replace with:

```markdown
**Exit:** The operator agrees that discovery is sufficient, OR you propose moving on and the operator approves. Surface the phase-exit ledger (constraints, tested choices, unclassified specifics) per `references/checkpoint-protocol.md`. Commit the WIP file with `phase: CHUNK`.
```

**Phase 2 (CHUNK):** find:

```markdown
**Exit:** Chunk structure approved by operator (or "no chunking needed" approved). Commit the WIP file with `phase: RED-TEAM` per `references/checkpoint-protocol.md`.
```

Replace with:

```markdown
**Exit:** Chunk structure approved by operator (or "no chunking needed" approved). Surface the phase-exit ledger per `references/checkpoint-protocol.md` (the ledger now also includes the per-chunk audit results from Step 5b). Commit the WIP file with `phase: RED-TEAM`.
```

**Phase 3 (RED-TEAM):** find:

```markdown
**Exit:** All CRITICAL findings addressed. Operator approves. Commit the WIP file with `phase: RESEARCH` per `references/checkpoint-protocol.md`.
```

Replace with:

```markdown
**Exit:** All CRITICAL findings addressed. Operator approves. Surface the phase-exit ledger per `references/checkpoint-protocol.md`. Commit the WIP file with `phase: RESEARCH`.
```

**Phase 3.5 (RESEARCH):** find:

```markdown
**Exit:** All chunks classified for build-vs-buy. Operator approves classifications. Chunks restructured. Commit the WIP file with `phase: ARTIFACT` per `references/checkpoint-protocol.md`.
```

Replace with:

```markdown
**Exit:** All chunks classified for build-vs-buy. Operator approves classifications. Chunks restructured. Surface the phase-exit ledger per `references/checkpoint-protocol.md`. Commit the WIP file with `phase: ARTIFACT`.
```

- [ ] **Step 5: Edit `SKILL.md` — add per-fire visibility note to Phase 1's Tech-D subsection**

Find this exact line in Phase 1's "Continuous: Technique D (constraints vs. choices)" subsection:

```markdown
**Do not skip this.** The Path A test demonstrated that adopting specifics without classification produces shallow architectures. This is your most important continuous discipline.
```

Insert this block immediately after it:

```markdown
**Per-fire visibility (high-stakes specifics).** For most classifications, Tech-D fires silently and surfaces the result in the next phase-exit ledger. But for **high-stakes specifics**, the agent shows the classification result inline in the same turn rather than batching. Definition of high-stakes: specifics that, if wrong, would invalidate multiple downstream chunks. Concretely:

- **Named foundational technology** that the rest of the design will sit on top of (database, framework, deployment target, language).
- **Behavioral default that affects every operation** of the agent or system being designed (e.g., "default-ON consultation," "always confirm before write," "X is the source of truth").
- **An item the agent is about to record as a `[future-pull, V1-justified: ...]` constraint** — these need explicit operator buy-in inline, not retrospective audit.

Inline visibility format:

> "Tech-D classification: [item] → [V1] constraint. Source: [your quote / external source]. Recording it. Want to challenge?"

All other Tech-D classifications happen silently and appear in the next phase-exit ledger.
```

- [ ] **Step 6: Verify by re-reading**

Run: `sed -n '1,80p' skills/discover/references/checkpoint-protocol.md`

Run: `grep -n "phase-exit ledger" skills/discover/SKILL.md`

Run: `grep -n "Per-fire visibility" skills/discover/SKILL.md`

Confirm:
- `checkpoint-protocol.md` has the new "Phase-exit ledger entries" section with the ledger format
- `checkpoint-protocol.md` "Phase-boundary commit" section now includes step 1 (surface ledger) before the YAML phase update
- Each phase's Exit criterion in SKILL.md mentions the ledger
- Per-fire visibility section is present in Phase 1's Tech-D subsection with the high-stakes definition and inline format

- [ ] **Step 7: Commit**

```bash
git add skills/discover/references/checkpoint-protocol.md skills/discover/SKILL.md
git commit -m "feat(discover): add per-phase ledger discipline and per-fire visibility for high-stakes Tech-D classifications"
```

---

## Task 9: Artifact Template — Add Required Fields

**Implements:** prerequisite for Mechanism 9 (the gates need these fields to exist).

**Files:**
- Modify: `skills/discover/references/artifact-template.md`

- [ ] **Step 1: Read the existing template**

Run: `sed -n '15,75p' skills/discover/references/artifact-template.md`

Confirm the template's current "Confirmed constraints", "Tested choices", "Open choices" formats.

- [ ] **Step 2: Edit `artifact-template.md` — update "Confirmed constraints" template format**

Find this exact block:

```markdown
## Confirmed constraints

- <constraint>: <why it's a constraint, not a choice>
- <constraint>: ...
```

Replace with:

```markdown
## Confirmed constraints

Each line MUST start with a label produced by Tech-D's V1/future-pull sub-classification, and end with a source annotation:

- `[V1] <constraint text> (source: <operator quote / external source / inherited from chunk N>)`
- `[future-pull, V1-justified: <specific V1 impact>] <constraint text> (source: ...)`

A `[V2-driven, deferred]` item is NOT a V1 constraint — record those under a separate "Deferred (V2 only)" subsection if any exist, not here.
```

- [ ] **Step 3: Edit `artifact-template.md` — update "Tested choices" template format**

Find this exact block:

```markdown
## Tested choices

- <choice>: <alternatives considered, why this was selected>
- <choice>: ...
```

Replace with:

```markdown
## Tested choices

Each line MUST list the alternatives that were considered and the specific rejection reason for each:

- `<choice> (alternatives: <alt 1> [rejected: <reason>], <alt 2> [rejected: <reason>])`

A "Tested choices" entry without alternatives recorded fails the artifact gate.
```

- [ ] **Step 4: Edit `artifact-template.md` — update the chunk-level "Open choices" template format**

Find this exact block:

```markdown
### Open choices (for the executor to resolve)

- <choice>
- <choice>
```

Replace with:

```markdown
### Open choices (for the executor to resolve)

Each open choice MUST include a one-liner survival justification produced during the per-chunk audit (Phase 2 Step 5b). Format:

- `<choice> — Deferred because: <one-liner: why this is more answerable with executor context than now>`
```

- [ ] **Step 5: Edit `artifact-template.md` — update the "Confirmed constraints vs. tested choices" guidance subsection**

Find this exact block:

```markdown
### Confirmed constraints vs. tested choices

These are distinct sections, not interchangeable.

- **Constraints** = externally imposed (company policy, existing infra, compliance, team decision). These cannot be challenged downstream.
- **Tested choices** = surfaced as choices, alternatives explored, this one selected. Downstream executors should NOT re-open these — the alternatives were already considered.
```

Replace with:

```markdown
### Confirmed constraints vs. tested choices

These are distinct sections, not interchangeable.

- **Constraints** = externally imposed OR derived from a V1 need. Each carries a `[V1]` or `[future-pull, V1-justified: <reason>]` label and a source annotation. Downstream executors cannot challenge these. The V1/future-pull label is mandatory; an unlabeled constraint blocks the artifact gate.
- **Tested choices** = surfaced as choices, alternatives explored, this one selected. Each line records the alternatives considered. Downstream executors should NOT re-open these — the alternatives were already considered.
- **Open choices** (per-chunk) = decisions deferred to the executor. Each carries a survival justification explaining why deferral produces a better outcome than resolution-now.
```

- [ ] **Step 6: Verify**

Run: `sed -n '40,75p' skills/discover/references/artifact-template.md`

Run: `sed -n '150,175p' skills/discover/references/artifact-template.md`

Confirm:
- "Confirmed constraints" section now requires `[V1]` or `[future-pull, V1-justified: ...]` labels and source annotations
- "Tested choices" requires alternatives + rejection reasons
- "Open choices" requires survival justification
- "Constraints vs. choices" guidance subsection updated to mention all three labeling rules

- [ ] **Step 7: Commit**

```bash
git add skills/discover/references/artifact-template.md
git commit -m "feat(discover): require provenance, alternatives, and survival justifications in artifact template"
```

---

## Task 10: Artifact Gates (NEW file + Phase 4 wiring)

**Implements:** Mechanism 9.

**Files:**
- Create: `skills/discover/references/artifact-gates.md`
- Modify: `skills/discover/SKILL.md` — Phase 4 (ARTIFACT)

- [ ] **Step 1: Create `artifact-gates.md`**

Create the new file at `skills/discover/references/artifact-gates.md` with this content:

```markdown
# Artifact-Time Gates

> Phase names (DISCOVER, CHUNK, RED-TEAM, RESEARCH, ARTIFACT, DISPATCH) and the overall flow are defined in `../SKILL.md`. This file expands the Phase 4 write-time validation only.

Before writing the discovery artifact to `docs/discovery/<slug>.md`, the agent runs four self-validation gates against the assembled draft. Any failure blocks the write and returns the agent to a fixup loop.

The gates are agent-driven self-validation in the prompt — not external tooling. The agent reads its own draft, runs the four checks, and reports its conclusions to the operator before writing.

## Gate 1: Constraints provenance gate

For each line under "## Confirmed constraints" in the assembled artifact draft, verify both:

- A label is present at the start of the line: either `[V1]` or `[future-pull, V1-justified: <reason>]`.
- A source annotation is present in parens at the end of the line: `(source: <operator quote / external source / inherited from chunk N>)`.

**Fails if:** any line lacks the label or lacks the source annotation. Lines under a separate "Deferred (V2 only)" subsection are not checked here (those use the `[V2-driven, deferred]` label format and are not V1 constraints).

## Gate 2: Tested choices alternatives gate

For each line under "## Tested choices" in the assembled artifact draft, verify:

- The line lists at least one alternative considered.
- Each alternative includes a specific rejection reason.

**Fails if:** any "Tested choices" entry is missing alternatives, or lists alternatives without rejection reasons.

## Gate 3: Open choices survival justification gate

For each entry under "### Open choices (for the executor to resolve)" inside any chunk section, verify:

- A one-liner survival justification is present, in the format produced by Phase 2's per-chunk audit (Step 5b).

**Fails if:** any open choice lacks a survival justification.

## Gate 4: Empty future-pull justification gate

For each line under "## Confirmed constraints" that uses the `[future-pull, V1-justified: <reason>]` label, verify:

- The `<reason>` slot is non-empty and contains a concrete V1 impact statement (not a placeholder, not "TBD," not just "needed for V1").

**Fails if:** any future-pull label has empty or placeholder justification text.

## Failure handling

When any gate fails, the agent does NOT write the artifact. Instead:

1. **Surface the failures to the operator** as a single bulleted list, grouped by gate name. Format:

   ```text
   Artifact gate check failed. Issues:

   Constraints provenance gate (2 failures):
     - "Plane Cloud is the backend" — missing [V1]/[future-pull] label
     - "Single primary operator" — missing source annotation

   Open choices survival justification gate (1 failure):
     - Chunk 1 → "Internal module layout within core/" — missing survival justification

   Cannot write artifact until these are addressed.
   ```

2. **Surface a fixup loop:** for each failure, return to the relevant phase or extend the per-phase ledger to record the missing information. Common fixups:
   - Missing label → return to DISCOVER, run Tech-D's V1/future-pull sub-classification on the constraint, record the result.
   - Missing source annotation → ask the operator (or check the transcript) for the source.
   - Missing alternatives → return to DISCOVER, ask the operator what alternatives were considered for the choice.
   - Missing survival justification → return to CHUNK Step 5b, run the per-open-choice self-challenge for the affected chunk.
   - Empty future-pull justification → ask the operator: *"This constraint is labeled future-pull. What specifically about V1 requires it?"*

3. **Re-run all four gates after each fixup.** A single missed item won't be the only one; re-running catches cascade failures.

4. **Only after all gates pass:** proceed to write the artifact to `docs/discovery/<slug>.md`.

## Anti-patterns

- ❌ **Writing the artifact and then noting the failures.** Gates run BEFORE the write. The artifact must be gate-clean.
- ❌ **Treating a gate failure as advisory.** Gates block the write. If the operator wants to override, the override is recorded in the artifact (e.g., a "Gate overrides" section noting which gate was bypassed and why), and the gate is re-run after recording the override.
- ❌ **Lumping all failures into one generic complaint.** Group by gate name; cite the specific line that failed. The operator needs to know what to fix.
- ❌ **Skipping gates when the draft "looks fine."** The whole point of gates is to catch what looks fine but isn't. Run them every time.
```

- [ ] **Step 2: Edit `SKILL.md` — wire the gates into Phase 4 (ARTIFACT) before the write step**

Find this exact block in Phase 4:

```markdown
**Step 4: write to file** at `docs/discovery/<topic-slug>.md`. Create the `docs/discovery/` directory if it doesn't exist.
```

Replace with:

```markdown
**Step 4a: run artifact-time gates.** Before writing, run the four self-validation gates defined in `references/artifact-gates.md` against the assembled draft. If any gate fails, do NOT write. Surface the failures to the operator (grouped by gate name), enter the fixup loop (returning to the relevant phase as needed), and re-run all four gates after each fixup. Only proceed to Step 4b when all gates pass.

**Step 4b: write to file** at `docs/discovery/<topic-slug>.md`. Create the `docs/discovery/` directory if it doesn't exist.
```

- [ ] **Step 3: Edit `SKILL.md` — re-letter Phase 4's remaining steps**

The existing Step 5 ("stage the artifact") and Step 5b ("finalize the session transcript") and Step 6 ("tell the operator") follow Step 4. Since we inserted Step 4a + 4b, the existing numbering still works (Step 4b → Step 5 → Step 5b → Step 6). No renumbering needed.

Verify the existing flow still reads correctly by running:

Run: `sed -n '320,365p' skills/discover/SKILL.md`

Confirm: 4a → 4b → 5 → 5b → 6 in order.

- [ ] **Step 4: Edit `SKILL.md` — add an anti-pattern entry for skipping gates**

Find Phase 4's "### Anti-patterns" section. The current list ends with "❌ **Forgetting to commit.**". Find this exact line:

```markdown
- ❌ **Forgetting to commit.** The artifact is the durable output. Always commit.
```

Insert this immediately after it:

```markdown
- ❌ **Skipping the artifact gates.** The gates run BEFORE the write, every time. A "looks fine" assessment does not substitute for the four checks.
```

- [ ] **Step 5: Verify by re-reading**

Run: `cat skills/discover/references/artifact-gates.md`

Run: `sed -n '320,375p' skills/discover/SKILL.md`

Confirm:
- `artifact-gates.md` exists with all four gates documented and the failure-handling protocol
- Gate names are used as cross-reference handles (e.g., "Constraints provenance gate"), not numbers
- Phase 4 has Step 4a (gates) before Step 4b (write)
- The "Skipping the artifact gates" anti-pattern is added

- [ ] **Step 6: Commit**

```bash
git add skills/discover/references/artifact-gates.md skills/discover/SKILL.md
git commit -m "feat(discover): add artifact-time gates for provenance, alternatives, and justifications"
```

---

## Task 11: LIMITATIONS Update

**Implements:** documentation of new known limits.

**Files:**
- Modify: `skills/discover/LIMITATIONS.md`

- [ ] **Step 1: Read existing LIMITATIONS.md**

Run: `cat skills/discover/LIMITATIONS.md`

Confirm sections 1-6 exist as documented.

- [ ] **Step 2: Edit `LIMITATIONS.md` — append new limits sections**

Find this exact line at the end of the file (the final paragraph of section 6):

```markdown
**Status:** Specified, structurally supported, not empirically validated. First real recursive run will likely surface integration issues (e.g., constraint inheritance from parent, where to put upstream decisions, how to handle re-runs after parent revisions). Consider this a "first run will be a bit rough" area.
```

Insert this entire block immediately after it:

```markdown

## 7. Phase 0 may add a turn that doesn't surface a real alternative

**Observed:** Hypothetical for tightly-scoped problems where the operator genuinely has considered no-build alternatives and ruled them out.

**Pattern:** The mandatory premise check is one extra turn at session start. For problems where the operator has already done the no-build analysis, this can feel like dead weight.

**Mitigation:** The operator can use the "Don't ask me this" override path (recorded in the WIP, not silently bypassed). The override creates a single audit point — operators who routinely override get a visible record they can self-audit if too many premise checks are being skipped.

## 8. Per-fire visibility is limited to high-stakes specifics

**Observed:** By design — Tech-D fires silently for most classifications and visibly only for high-stakes specifics (named foundational technology, behavioral defaults that affect every operation, future-pull-V1-justified items).

**Pattern:** Subtle drift in low-stakes items still relies on the per-phase ledger to catch. If the operator skips the ledger acknowledgement turn (or proceeds without reviewing it), low-stakes drift can ship into the artifact.

**Mitigation:** The ledger surfaces "Unclassified specifics" as a load-bearing line — anything not classified is shown explicitly. Operators who skip the ledger entirely will trip the artifact gates, since unclassified items won't have the labels the gates require.

## 9. Artifact gates are in-prompt self-validation

**Observed:** The four gates in `references/artifact-gates.md` are agent-driven self-validation, not external tooling.

**Pattern:** Standard reliability profile of in-prompt self-validation. The agent may, in some sessions, satisfice on the gates ("looks fine, write it") rather than running them rigorously. The "Skipping the artifact gates" anti-pattern in SKILL.md is a softer guard than a mechanical check would be.

**Mitigation hypothesis (not implemented):** if real-world use shows agents skipping gates, the design moves from "agent reads its own draft" to a more mechanical check (e.g., a structured validation protocol the agent must produce as evidence of running the gates). For now, accept the standard reliability profile.

## 10. The chunk-overload signal check is now mandatory at CHUNK exit, not advisory at DISPATCH

**Observed:** The signals previously surfaced as an optional prompt at dispatch time; they now surface as a mandatory action at end of CHUNK phase. The change shifts when chunk-decomposition decisions are made (earlier, while context is hot) but adds friction in the CHUNK phase.

**Pattern:** A chunk that the agent borderline-flags but the operator considers fine still requires an explicit override on record. Previously the operator could decline the recursion prompt and move on with no record; now the override goes into the artifact.

**Status:** Intentional. The visibility is the point. If operators routinely override at CHUNK exit, the signals may need re-tuning — but the override-with-record creates the data needed to know that.
```

- [ ] **Step 3: Verify**

Run: `cat skills/discover/LIMITATIONS.md`

Confirm sections 7-10 are appended after section 6.

- [ ] **Step 4: Commit**

```bash
git add skills/discover/LIMITATIONS.md
git commit -m "docs(discover): document new known limits introduced by anti-sycophancy hardening"
```

---

## Task 12: Final Verification — Mental Walkthrough on PM Agent Input

**Implements:** the spec's empirical validation strategy.

**Files:**
- Read: every file modified in tasks 1-11. No edits unless gaps are found.

- [ ] **Step 1: Read each modified file end-to-end to spot any inconsistencies**

Run each in turn:

```bash
cat skills/discover/SKILL.md
cat skills/discover/references/anti-sycophancy.md
cat skills/discover/references/chunking-guidelines.md
cat skills/discover/references/artifact-template.md
cat skills/discover/references/artifact-gates.md
cat skills/discover/references/checkpoint-protocol.md
cat skills/discover/references/dispatch-protocol.md
cat skills/discover/LIMITATIONS.md
```

Look for:
- Cross-references that point to sections that don't exist (e.g., "see X" where X is now elsewhere)
- Phase numbers that disagree across files
- Step labels (a/b/c/...) that conflict
- The "six phases" string anywhere it should now be "seven phases"

- [ ] **Step 2: Mental walkthrough — simulate the agent processing the PM agent input from `/tmp/pm-agent.transcript.md`**

Imagine an agent following the new SKILL.md, given the original PM agent problem statement:

> "I want to create a project management agent with the following goals: [...] The agent will effectively replace a human that will would normally do project management. [...] We will use https://docs.plane.so/ as a backend [...] We will want two versions of the agent: a local one that works with claude code [...] An autonomous agent (on the platform) [...]"

For each mechanism, check whether the new prompt would have caused a different outcome than the original PM agent discovery showed:

- [ ] **Mechanism 1 (Phase 0):** would the agent have asked the premise check? Yes — Phase 0 is mandatory. The agent would have restated the outcome ("you want PM legwork off your plate") and listed concrete no-build paths (e.g., "use Plane MCP from your own Claude installs," "improve the markdown POC").
- [ ] **Mechanism 2 (Tech-B 4-option, turn 1):** would the agent have offered a no-build frame at turn 1? Yes — Tech-B at turn 1 is mandatory, and the no-build frame is one of four required options.
- [ ] **Mechanism 3 (Tech-D sixth category):** would Tech-D have fired on the operator quote *"we don't want a PM agent without expertise..."*? Yes — the sixth category "behavioral defaults / policy quotes" explicitly covers this pattern, and the sixth-category prompt classifies the rule (default-ON it-ops consultation), not the quote.
- [ ] **Mechanism 4 (Tech-D V1/future-pull):** would the `core/ runtime-agnostic` and `structlog from day one` items have been challenged? Yes — every constraint runs the V1/future-pull sub-classification. Both items would have been flagged as future-pull, with the operator either justifying V1 impact or accepting they're V2-driven.
- [ ] **Mechanism 5 (Per-phase ledger):** would the operator have seen the unclassified `default-ON it-ops consultation` item before phase exit? Yes — the ledger surfaces "Unclassified specifics" as a load-bearing line, and the operator can opt to address it before phase exits.
- [ ] **Mechanism 6 (Mandatory action on self-flag):** would Chunk 1 have been split? Yes — Chunk 1 had 3+ open choices (Mechanism 6 signal #1) and the agent self-flagged it as needing recursive /discover (signal #4 in agent's draft red-team thinking). With 2+ signals firing at end of CHUNK phase, the agent would have presented a sub-decomposition in-line.
- [ ] **Mechanism 7 (Per-chunk audit + per-open-choice self-challenge):** would the open choices like "internal module layout within core/" have been resolved or justified? The audit's per-open-choice self-challenge would have asked: "is this genuinely more answerable with executor context than now?" Module layout is a foundational decision; the agent would either have to resolve it now or articulate a specific justification for deferring (e.g., "the SDK's internal organization may inform module layout — easier to decide after touching SDK").
- [ ] **Mechanism 8 (RED-TEAM future-pull check):** would the V2-driven items have been re-caught at RED-TEAM if Tech-D missed them? Yes — RED-TEAM's check #8 explicitly looks for future-pull contamination on every chunk and constraint.
- [ ] **Mechanism 9 (Artifact gates):** would the artifact have been writable as-is? No — without provenance labels (Constraints provenance gate), without alternatives recorded (Tested choices alternatives gate), without survival justifications (Open choices survival justification gate), the gates would have blocked the write and forced a fixup loop.

- [ ] **Step 3: Document any gaps found**

If any mechanism's walkthrough surfaces a gap (e.g., the prompt as written wouldn't actually have caught the issue), record the gap here and apply a targeted fix to the relevant file. If no gaps, write a one-line note here in this step's checkbox: "All mechanisms walked through cleanly on the PM agent input."

- [ ] **Step 4: Final commit (only if step 3 surfaced any fixes)**

If gaps were found and fixed in step 3:

```bash
git add <modified files>
git commit -m "fix(discover): address gaps surfaced during PM agent walkthrough validation"
```

If no gaps were found, skip this commit step.

---

## Self-Review

After writing the complete plan, the following checks were run:

**1. Spec coverage:** All nine mechanisms in the spec map to at least one task:
- Mechanism 1 (Phase 0) → Task 3
- Mechanism 2 (Tech-B 4-option) → Task 4
- Mechanism 3 (Tech-D trigger expansion) → Task 1
- Mechanism 4 (Tech-D V1/future-pull) → Task 2
- Mechanism 5 (Per-phase ledger + per-fire) → Task 8
- Mechanism 6 (Mandatory action on self-flag) → Task 5
- Mechanism 7 (Per-chunk audit + self-challenge) → Task 6
- Mechanism 8 (RED-TEAM future-pull) → Task 7
- Mechanism 9 (Artifact gates) → Task 10 (with template prereq in Task 9)

Plus: LIMITATIONS update (Task 11), empirical validation walkthrough (Task 12). All five spec open questions resolved at the top of this plan.

**2. Placeholder scan:** No "TBD," "TODO," "implement later," or "fill in details" anywhere in this plan. Every code block contains the actual prose to write. Every Edit step shows exact old_string → new_string.

**3. Type consistency:** Label format is consistent across the plan: `[V1]`, `[future-pull, V1-justified: <reason>]`, `[V2-driven, deferred]` — matches Tech-D's outputs (Task 2), the ledger format (Task 8), the artifact template (Task 9), and all four gates (Task 10). Phase letters are consistent: Phase 5 step 2 sub-letters re-letter cleanly after removing the assessment step (Task 5 step 4). Step numbers within Phase 2 add 5b between 5 and 6 (Task 6 step 2) without renumbering 6.
