# `/discover` Pure-Socratic Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strip solution-mode constructs from `/discover` (no-build premise check, 4-framings Tech-B, shape-language audit, in-line Tech-D classification, structured red-team) and collapse it to a single pure-Socratic dialogue phase. Push shape/constraint elicitation downstream to `/solution`. Artifact shrinks to four sections (Framing, Original statement, Key reframes, Outcomes, Discovery log).

**Architecture:** Markdown rewrites under `plugins/socrates/`. One new reference file (`socratic-patterns.md`), one file deletion (`research-protocol.md`), and edits to six existing files. No code changes. Validation is an empirical walkthrough (Task 12) plus refreshed evals (Task 8).

**Tech Stack:** Markdown documentation under `plugins/socrates/skills/{discover,solution}/`. Tracked by git; no automated CI.

---

## Spec reference

This plan implements `docs/superpowers/specs/2026-05-19-discover-pure-socratic-design.md`. Section names below reference the spec where relevant.

## Files affected

| File | Change | Tasks |
|---|---|---|
| `plugins/socrates/skills/discover/references/socratic-patterns.md` | **NEW** — Maieutic / Reductio / Parallel-case patterns + teacher-side reminders | 1 |
| `plugins/socrates/skills/discover/references/artifact-template.md` | Rewrite to minimal template | 2 |
| `plugins/socrates/skills/discover/references/artifact-gates.md` | Rewrite to G1 + G2 only | 3 |
| `plugins/socrates/skills/discover/references/research-protocol.md` | **DELETE** | 4 |
| `plugins/socrates/skills/discover/SKILL.md` | Major rewrite (single phase) | 5 |
| `plugins/socrates/skills/solution/SKILL.md` | Phase 0 elicitation; Tech-B turn shift; drop Phase 2 check 9 | 6 |
| `plugins/socrates/skills/solution/references/solution-gates.md` | Remove G6 + cross-references | 7 |
| `plugins/socrates/skills/discover/evals/evals.json` | Refresh graders for Socratic-dialogue qualities | 8 |
| `plugins/socrates/skills/discover/evals/methodology.md` | Update grading criteria | 9 |
| `plugins/socrates/evals/reports/pr2-discover-smoke-test.md` | Note rework + new expectations | 10 |
| `plugins/socrates/TODO.md` | Note rework outcome | 11 |
| `plugins/socrates/LIMITATIONS.md` | Update if it references deleted protocols | 11 |

## Commit cadence

One commit per task. Commit messages: `feat(socrates):`, `refactor(socrates):`, `docs(socrates):` per project convention. Suffix the commit body with the Claude `Co-Authored-By` line.

---

## Task 1: Create `socratic-patterns.md` reference file

**Files:**
- Create: `plugins/socrates/skills/discover/references/socratic-patterns.md`

- [ ] **Step 1: Write the new file**

Write `plugins/socrates/skills/discover/references/socratic-patterns.md` with the exact content below:

````markdown
# Socratic Patterns for `/discover`

This file is the teacher-side reference for how `/discover` operates. Pure Socratic dialogue uses three primary question patterns. Load this file once at session start (it is short) and consult it whenever the next move is unclear.

## The three patterns

### 1. Maieutic — drawing out

Test the operator's definition or rule with concrete cases. Each case the operator handles refines their own definition; you never name the refinement.

**Example:**

> **Operator:** Bravery is acting in the face of fear.
> **Agent:** A man pets a snake, not realizing it's venomous. Brave?
> **Operator:** No — he isn't afraid.
> **Agent:** So bravery needs fear present?
> **Operator:** Yes. Felt, and acted through.
> **Agent:** A child afraid of the dark walks to the bathroom anyway. Brave?
> **Operator:** ...In some small way. Not the way a soldier is.
> **Agent:** What separates them?

The dialogue ends not at a clean definition but at the operator's *latest* definition opening a question they can't yet answer. Each landing is the next launchpad.

### 2. Reductio — walking a premise to where it actually goes

Accept the operator's premise and walk it consistently to a place they haven't followed it. Never name the contradiction; let aporia land on them.

**Example:**

> **Operator:** People should keep what they earn. Redistribution is theft.
> **Agent:** Earning means trading effort for reward?
> **Operator:** Yes.
> **Agent:** A child born to wealth — did they earn it?
> **Operator:** No, but their parents did and chose to give it.
> **Agent:** Fair. What about being born intelligent, healthy, in a stable country?
> **Operator:** That's not the same.
> **Agent:** Did the intelligent person earn their intelligence?
> **Operator:** ...No.
> **Agent:** So which of us has only what we earned?

The dialogue ends in aporia. The agent never characterizes the failure; characterizing it would let the operator argue with the *characterization* instead of with the bind.

### 3. Parallel case — testing through the mirror

Introduce a mirror case the operator can't dismiss without exposing an asymmetry. Ask the question that surfaces the asymmetry.

**Example:**

> **Operator:** The university shouldn't host that speaker. His views are harmful.
> **Agent:** Suppose another university banned a speaker you admired, citing the same reason.
> **Operator:** That would be censorship.
> **Agent:** What's different?
> **Operator:** His views are *actually* harmful. Hers aren't.
> **Agent:** And those administrators — what do they think about their case?
> **Operator:** That hers are harmful too.
> **Agent:** How do they know they're wrong and you're right?

No alternative principle is offered; no conclusion is stated. The operator is left holding the inconsistency, which is sharper than being handed it.

## Where Socratic questions tend to bite

These are teacher-side reminders — never present them to the operator as a checklist. They are the dimensions where pure Socratic questioning most often surfaces refinements:

- **Purpose / audience.** "Who is harmed if this problem persists?" "Who else has this problem and what do they currently do?"
- **Scale.** "When you say [problem], how many people / cases are we talking about?" "Has it been [problem] for one of those? Ten of those? All of them?"
- **Lifecycle.** "When did you first notice [problem]?" "What was different before [problem] started?" "If [problem] went away tomorrow, what would change?"
- **Identity / trust.** "Whose problem is this — yours, the team's, the customer's? How does the answer change?"
- **Operability outcomes.** "If [problem] is happening, who finds out? How?"
- **Self-attribution.** "You said [problem] is making [outcome] happen. Have you had [outcome] when [problem] was absent?"

The questions are templates — adapt them to the specific framing. Never list axes to the operator.

## Convergence signals

The problem statement is stable when:

- The operator's last 2–3 answers refined the framing in the same direction without new tensions emerging.
- The operator is confirming rather than refining ("yes, that's exactly it").
- Productive aporia: the operator hits a question they can't answer and that question is now itself the real problem.

When you detect convergence, surface the readback: *"I think the problem is stable. Here's what I'll write down: [refined problem] / [outcomes]. Want to keep digging or wrap?"*

## Response length and tone

Look back at the three pattern examples above. Each turn from the teacher is *short*: a single mirror or a single question, typically one or two sentences. The student does the heavy thinking; the teacher does the precise prompting.

Match that length in operator-facing turns. Target: **1–4 sentences per turn, asking one question**. Specifically:

- **No multi-paragraph elaborations.** If a turn is more than ~4 sentences, you're exposition-ing instead of asking. Cut it.
- **No restating the same idea multiple ways.** Once is enough. "You're saying X. Is that right?" — not "You're saying X, which is to say Y, in other words Z..."
- **No preambles.** Skip "Great question. Let me think about this. Before I dig in...". Get straight to the mirror or question.
- **Labels stay light.** The labeling protocol mandates `§X.Y.Z` labels on response structure. For a single-question turn, `§Q1` alone is sufficient. Don't generate nested `§1.1.1.1` subsections inside a short turn — that's visual weight without information.
- **Readback turns may be slightly longer.** At convergence, the readback surfaces the proposed Framing + Outcomes — those are artifact contents, not exposition. A readback of 5–8 sentences is fine; a turn that explains *why* you're reading back is not.

The Socratic method is a discipline of restraint. If a turn feels like it's earning its length by being thorough, it's probably padding.

## Anti-patterns

- ❌ **Offering alternative framings of the problem.** ("Maybe the real problem is X, or Y, or Z?") The operator picks one of yours and now they're refining *your* framing instead of theirs. The whole point of Socratic dialogue is that the refinement is the operator's. Use cases, premise-walking, or parallel cases — never alternatives.
- ❌ **Labeling phrases.** ("'task graph' is a shape-phrase.") Classification biases the dialogue. If the operator referenced a specific shape, ask a Socratic question about it ("tell me about [shape] — what does it give you?") and let the answer reveal the underlying want.
- ❌ **Classifying in the open.** ("Tech-D classification: [X] → constraint.") Same problem as labeling. Track inferences silently if at all; the operator-facing turn is always a question.
- ❌ **Compound questions.** ("What's your scale and lifecycle?") Pick one. The operator can only Socratically engage with one thread per turn.
- ❌ **Naming the contradiction.** When Reductio lands the operator in aporia, hold the silence. Naming the contradiction lets the operator argue with the framing instead of with the bind.
- ❌ **Asking questions whose answers won't change anything.** If the next answer can't refine the framing, you're padding. Move toward convergence.
- ❌ **Over-mirroring.** Mirroring the operator's exact words back without testing them ("So you're saying X is the problem?" repeated turn after turn) is performative. Mirror once to confirm the starting point, then test.
- ❌ **Verbose elaboration.** Multi-paragraph turns that explain context, alternatives, or your own reasoning. The Socratic teacher asks; they do not lecture. If a turn exceeds 4 sentences, it is almost certainly padding — cut it.
````

- [ ] **Step 2: Verify the file was created**

Run: `wc -l plugins/socrates/skills/discover/references/socratic-patterns.md`
Expected: roughly 110-130 lines.

- [ ] **Step 3: Commit**

```bash
git add plugins/socrates/skills/discover/references/socratic-patterns.md
git commit -m "$(cat <<'EOF'
feat(socrates): add socratic-patterns.md reference file

Maieutic / Reductio / Parallel-case patterns with worked examples,
teacher-side reminders for where Socratic questions tend to bite, and
convergence signals. Replaces the operator-facing classification
protocols from /discover.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Rewrite `artifact-template.md` to minimal template

**Files:**
- Modify: `plugins/socrates/skills/discover/references/artifact-template.md`

- [ ] **Step 1: Replace the entire file contents**

Replace the contents of `plugins/socrates/skills/discover/references/artifact-template.md` with:

````markdown
# Discovery Artifact Template

> Phase names and the overall flow are defined in `../SKILL.md`. This file expands the artifact format only.

The output document the skill writes when Socratic dialogue converges. Every discovery session produces one artifact in this format.

The artifact is *pure problem*: the refined problem statement, the outcomes that pressure-tested through dialogue, and a collapsed log of the key exchanges. Shapes, preferences, constraints, parked items, open axes, and red-team findings do NOT appear here — those are evaluable only against a validated problem and belong in `/solution`.

## Filename and location

`docs/socrates/discover/<topic-slug>.md`

`<topic-slug>` is a kebab-case identifier derived from the refined problem statement. Examples: `team-pm-bottleneck`, `auth-rotation-failure`, `cart-checkout-friction`.

## Template

```markdown
# Discovery: <problem title>

**Date:** YYYY-MM-DD
**Status:** Discovery complete, ready for /solution

## Framing

<The refined problem statement — what survived Socratic dialogue.
2–4 sentences. Problem-language only; no shapes, no how, no proposed
solutions. State *what* the problem is, not *how* to address it.>

### Original statement
> <verbatim operator input, preserved for reference>

### Key reframes
- <what changed from the original statement and why>

## Outcomes

The pressure-tested outcomes the operator wants. Each outcome is a *what*, not a *how*.

- <outcome 1 — 1-2 sentences>
- <outcome 2 — 1-2 sentences>
- ...

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

Key exchanges that shaped the framing, preserved for context if
someone revisits this artifact later.

- **Q:** <question asked>
  **A:** <operator answer>
  **Impact:** <how this changed the framing>

- **Q:** ...
  **A:** ...
  **Impact:** ...

</details>
```

## Section-by-section guidance

### Header

`Status` is always "Discovery complete, ready for /solution" at write time.

### Framing

The refined problem statement is *not* a paraphrase of the operator's input. It's what survived Socratic dialogue — usually significantly different from the original statement. The original statement is preserved separately for reference. Key reframes lists the deltas: what changed and why.

The Framing section MUST be problem-language only. No named tools, patterns, technologies, frameworks, protocols, or architectural choices. If the operator's refined problem genuinely references an external system (e.g., "users can't authenticate to our Okta tenant"), the system name is acceptable as a noun describing the world — not as a proposed solution.

### Outcomes

Concrete *what* statements. Each outcome is something the operator wants to be true. No shapes. If an outcome is phrased as "we should X," rewrite as "X is the case." If it can't be phrased without naming a tool/pattern/technology, it isn't an outcome yet — it's a shape preference and belongs in `/solution`.

### Discovery log

Collapsed by default. `/solution` doesn't need to read it; the human who returns weeks later does — to understand why the framing landed where it did. Include only key exchanges (the ones that changed the framing), not the full transcript. The full JSONL transcript lives in the `.wip` directory and is finalized alongside the artifact at write time.

## When the template feels heavy

For very simple problems, the template can feel oversized. Don't shortcut it. The consistency is the point — operators and `/solution` always know where to find what. A simple problem just has shorter sections.

If a section truly has nothing in it, write `None` rather than deleting the section. Example:

```markdown
### Key reframes

None — the operator's original statement survived Socratic dialogue unchanged.
```
````

- [ ] **Step 2: Verify file**

Run: `wc -l plugins/socrates/skills/discover/references/artifact-template.md`
Expected: roughly 70-90 lines (down from 138).

- [ ] **Step 3: Commit**

```bash
git add plugins/socrates/skills/discover/references/artifact-template.md
git commit -m "$(cat <<'EOF'
refactor(socrates): strip discover artifact-template to minimal form

Remove External constraints, Parked shapes, Open axes, Red-team findings
sections. The new artifact has four sections: Framing (with Original
statement + Key reframes), Outcomes, Discovery log. All shape /
constraint / red-team work moves to /solution.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Rewrite `artifact-gates.md` to G1 + G2 only

**Files:**
- Modify: `plugins/socrates/skills/discover/references/artifact-gates.md`

- [ ] **Step 1: Replace the entire file contents**

Replace the contents of `plugins/socrates/skills/discover/references/artifact-gates.md` with:

````markdown
# Artifact-Time Gates

> Phase names and the overall flow are defined in `../SKILL.md`. This file expands the discovery-artifact write-time validation only.

Before writing the discovery artifact to `docs/socrates/discover/<slug>.md`, the agent runs two self-validation gates against the assembled draft. Any failure blocks the write and returns the agent to a fixup loop.

The gates are agent-driven self-validation in the prompt — not external tooling. The agent reads its own draft, runs the two checks, and reports its conclusions to the operator before writing.

Shape decisions, constraint provenance, parked-shape resolution, and open-axis justifications are NOT gated here — those concerns belong in `/solution`'s `solution-gates.md`. `/discover`'s artifact contains *no shapes* by design.

## Gate 1: Problem-language gate

For each line in the `## Framing` and `## Outcomes` sections of the assembled artifact draft, verify the line contains no shape-language. Shape-language includes:

- A named technology, library, framework, or product ("Postgres", "AWS", "Next.js", "Plane", "Notion").
- A protocol or pattern ("REST", "GraphQL", "event-driven", "microservices").
- An architectural choice expressed as a *how* ("monorepo", "serverless", "task graph", "JIT generation").
- A non-functional shape framing ("first-class citizen", "comprehensive", "real-time").

External systems mentioned as nouns describing the world (e.g., "users can't authenticate to our Okta tenant") are acceptable — Okta is the world, not a proposed solution. The test: does removing the word leave the sentence describing the *problem* or describing a *proposed how*?

**Fails if:** any line in Framing or Outcomes contains shape-language as a proposed how. Common pattern: an outcome phrased "users should have [shape]" or "the system should [shape]" instead of "[underlying want]."

## Gate 2: Verbatim original statement gate

The `### Original statement` subsection contains the operator's input from session start, preserved verbatim.

**Fails if:** the Original statement is paraphrased, summarized, edited, or empty. This is a mechanical check — the agent compares against the first turn in the JSONL transcript.

## Failure handling

When any gate fails, the agent does NOT write the artifact. Instead:

1. **Surface the failures to the operator** as a bulleted list, grouped by gate name:

   ```text
   Artifact gate check failed. Issues:

   Problem-language gate (1 failure):
     - Outcome "users should have a task graph" contains shape-language
       ("task graph" is a proposed how). Reframe as the underlying want.

   Cannot write artifact until these are addressed.
   ```

2. **Surface a fixup loop:** for each failure, run one more Socratic peel on the offending phrase. Common fixups:
   - Shape-language in Framing → ask: *"You wrote [phrase] in the problem statement. What is the underlying want that [phrase] is a proposed answer to?"* Replace with the underlying want.
   - Shape-language in an Outcome → same peel; re-state the outcome at the *want* level.
   - Verbatim Original statement missing or paraphrased → restore from the JSONL transcript turn 1.

3. **Re-run both gates after each fixup.**

4. **Only after both gates pass:** proceed to write the artifact to `docs/socrates/discover/<slug>.md`.

## Anti-patterns

- ❌ **Writing the artifact and then noting the failures.** Gates run BEFORE the write.
- ❌ **Treating a gate failure as advisory.** If the operator wants to override (e.g., the shape-word is genuinely the only way to phrase the world-fact), record the override explicitly in the artifact ("Note: [phrase] is a system-name, not a proposed how") and re-run gates against the override-acknowledged draft.
- ❌ **Skipping gates when the draft "looks fine."** The whole point is to catch shape-language that snuck in during dialogue.
````

- [ ] **Step 2: Verify file**

Run: `wc -l plugins/socrates/skills/discover/references/artifact-gates.md`
Expected: roughly 55-70 lines (down from 73, but content is entirely different).

- [ ] **Step 3: Commit**

```bash
git add plugins/socrates/skills/discover/references/artifact-gates.md
git commit -m "$(cat <<'EOF'
refactor(socrates): replace discover artifact-gates with G1 + G2

G1: no shape-language in Framing or Outcomes.
G2: Original statement is verbatim.

Drops the old External constraints provenance gate (G1), Open axes
justification gate (G3), and Empty future-pull justification gate (G4)
— those sections no longer exist in the artifact.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Delete `research-protocol.md`

**Files:**
- Delete: `plugins/socrates/skills/discover/references/research-protocol.md`

- [ ] **Step 1: Verify the file exists**

Run: `test -f plugins/socrates/skills/discover/references/research-protocol.md && echo "EXISTS" || echo "MISSING"`
Expected: `EXISTS`

- [ ] **Step 2: Delete the file**

Run: `git rm plugins/socrates/skills/discover/references/research-protocol.md`
Expected: `rm 'plugins/socrates/skills/discover/references/research-protocol.md'`

- [ ] **Step 3: Verify SKILL.md does not yet reference removal**

The reference at `plugins/socrates/skills/discover/SKILL.md` line 49 (`references/research-protocol.md — Shallow existence-check...`) will be removed in Task 5 along with the rest of the SKILL.md rewrite. Confirm it's still there for now:

Run: `grep -n "research-protocol.md" plugins/socrates/skills/discover/SKILL.md`
Expected: one match at line 49.

- [ ] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
refactor(socrates): delete discover research-protocol.md

The shallow existence check ("is there an obvious tool for this?") is
solution-level work; it lives only in /solution's research-protocol.md
now. /discover does not run any kind of existence check — that would
re-introduce solution-mode reasoning into the discovery phase.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Rewrite `/discover/SKILL.md` to single Socratic phase

**Files:**
- Modify: `plugins/socrates/skills/discover/SKILL.md` (full rewrite)

- [ ] **Step 1: Replace the entire SKILL.md contents**

Replace the contents of `plugins/socrates/skills/discover/SKILL.md` with:

````markdown
---
name: discover
description: >
  Socratic problem discovery — runs upstream of /solution and
  /superpowers. Pressure-tests the operator's stated problem through
  pure Socratic dialogue (Maieutic / Reductio / Parallel-case patterns)
  until the problem statement is stable or productive aporia is
  reached. Produces a minimal discovery artifact (refined problem +
  outcomes) that /solution consumes. Especially valuable when the user
  is unsure what they actually want, when the stated problem may be a
  symptom of something deeper, or when the prompt is over-specified
  with shape-language ("I want to build X") that hasn't been tested
  against the underlying want.
when_to_use: >
  Use before /solution (and before /superpowers) in any of these
  situations: (1) the user has a vague or ambitious idea; (2) the user
  says they're not sure what they want; (3) the problem looks like it
  could span multiple subsystems and needs to be narrowed; (4) the
  prompt is over-specified — names specific technologies, protocols,
  or shapes that may not have been tested against the underlying want;
  (5) the user is starting a new project, ambitious feature, or
  platform build. Skip this skill for narrow well-scoped bug fixes,
  single-function changes, or maintenance tasks where the problem is
  genuinely tight.
allowed-tools: "Read Write Edit Bash(git *) TaskCreate TaskUpdate"
---

# Discover — Socratic Problem Discovery

You are running the `/discover` skill. Your job is to take a user's stated problem (any vagueness, any specificity) and pressure-test it through pure Socratic dialogue until the problem statement is stable. Then write a minimal *discovery artifact* — refined problem + outcomes — that downstream tools like `/solution` consume.

You do NOT propose solutions. You do NOT enumerate alternatives. You do NOT label phrases. You do NOT classify in the open. You do NOT plan or chunk or execute. You ask Socratic questions until the operator's problem statement is stable, then write the artifact.

The Socratic method, as it actually operates: **mirror once, test with cases, walk premises to where they lead, present parallel cases that expose asymmetry**. The conclusion lands on the operator. Never on you.

## Reference files

When you need detailed guidance, read the relevant reference file:

- `../../shared/labeling-protocol.md` — Addressable `§X.Y.Z` labels for every response. **Read once at session start.**
- `../../shared/checkpoint-protocol.md` — WIP file format, phase-boundary commits, resume, completion. The per-turn JSONL transcript is mirrored automatically by the plugin's hook.
- `references/socratic-patterns.md` — Maieutic / Reductio / Parallel-case worked examples, teacher-side reminders for where Socratic questions tend to bite, convergence signals, anti-patterns. **Read once at session start.**
- `references/artifact-template.md` — The discovery artifact format (Framing, Outcomes, Discovery log).
- `references/artifact-gates.md` — Discovery-time write gates (G1 problem-language, G2 verbatim original).

Read `labeling-protocol.md` and `socratic-patterns.md` once at session start; the others on demand.

## Response labeling

Every response uses the labeling protocol from `../../shared/labeling-protocol.md` — `§X.Y.Z` inline on section headings, sub-headings, list items, and inline classifications; `§Q1`, `§Q2` for questions to the operator. Always on, including one-question turns.

## The single phase: SOCRATIC DIALOGUE

`/discover` is one phase. Within it you ask questions, the operator answers, you ask the next question. You exit when the problem statement is stable (or aporia is productive) and the operator approves wrapping.

### Session startup

**New session** (plain invocation, e.g., `/discover I want to make my team move faster`):

- Read `references/socratic-patterns.md` and `../../shared/labeling-protocol.md`.
- Derive a provisional topic slug from a few words of the operator's input. (Slug can be refined later when the problem statement stabilizes.)
- Create `docs/socrates/discover/.wip/<slug>.wip.md` containing the YAML frontmatter (see `../../shared/checkpoint-protocol.md`) with `phase: SOCRATIC` and the `session_id` from the running Claude Code session.
- Begin the first dialogue turn: mirror the operator's stated problem and ask the first Socratic question.

If `docs/socrates/discover/.wip/` already contains `.wip.md` files, note them BEFORE starting: "Found in-progress session(s): `<slug>`. Run `/discover resume <slug>` to resume, or continue for a new session."

**Resume** (`/discover resume <slug>`):

- Read the WIP file for `<slug>`. Follow the resume reconstruction steps in `../../shared/checkpoint-protocol.md`.
- If the WIP predates this version of `/discover` (i.e., it has `## Premise check`, `## Ledgers`, or `## Parked shapes` sections in the WIP body), tell the operator: *"This WIP predates the Socratic rework — the old multi-phase protocol no longer exists. Options: (a) extract whatever framing and outcomes the WIP captured into a fresh artifact and ship as-is, skipping new Socratic dialogue; (b) abandon the WIP and start a fresh `/discover` session."* Wait for operator choice; proceed.
- If the WIP is current-format, continue the dialogue from where it left off.

### Operational flow

1. **Open with a mirror.** First turn always restates the operator's stated problem in their own language, lightly Socratic. *"Let me restate: you're saying [stated problem]. Is that right?"* Then ask the first Socratic question. Do not list axes, do not enumerate alternatives, do not audit shape-language as a categorization step.

2. **Continuous Socratic dialogue.** Each turn, ask one question. Choose the pattern based on what surfaced last turn (full patterns in `references/socratic-patterns.md`):

   - Operator stated a definition or rule → test with a case (Maieutic).
   - Operator stated a premise → walk it to where it leads (Reductio).
   - Operator stated something one-sided → introduce a mirror case and ask what's different (Parallel-case).
   - Operator referenced a specific shape (named tool, pattern, technology) → Socratic question about what it gives them. *"Tell me about [shape] — what does that give you?"* / *"How would you know if you were wrong about [shape]?"* / *"What would change if [shape] weren't available?"* Do not classify the shape. Do not list it back as "shape-language." Let the operator's answer reveal the underlying want.

3. **Convergence detection.** Track internally (do not surface as a counter): does the operator's last 2-3 answers refine the framing in the same direction without new tensions? Are they confirming rather than refining? Did they hit a question they can't answer and that question is now the real problem? When yes, move to step 4.

4. **Readback turn.** *"I think the problem is stable. Here's what I'd write as the discovery artifact: [refined problem] / [outcomes]. Want to keep digging or wrap?"* If the operator says wrap, go to step 5. If they want to keep digging, return to step 2.

5. **Write the artifact.** Run the gates from `references/artifact-gates.md`. If they pass, write `docs/socrates/discover/<topic-slug>.md` per `references/artifact-template.md`. Finalize the WIP per `../../shared/checkpoint-protocol.md` (move JSONL transcript out of `.wip/`, remove WIP file, commit artifact + transcript together).

### Response length and tone

Each operator-facing turn is **one Socratic question**, plus at most a one-sentence mirror or transition. Target turn length is **1–4 sentences**. See `references/socratic-patterns.md` "Response length and tone" section — the example exchanges in that file model the actual target length.

- No multi-paragraph elaborations. If a turn exceeds ~4 sentences, it's exposition, not Socratic dialogue.
- No restating the same idea multiple ways. Once is enough.
- No preambles ("Great question. Let me think about this..."). Get to the mirror or question.
- Labels (`§X.Y.Z`) stay light. For a single-question turn, `§Q1` alone is sufficient — do not generate nested `§1.1.1.1` subsections inside a short turn.
- Readback turns may be slightly longer because they surface the proposed Framing + Outcomes (the artifact contents). A readback of 5–8 sentences is fine; explaining *why* you're reading back is not.

The Socratic method is a discipline of restraint. Brevity is correctness.

### What you do NOT do

- Do not enumerate alternative framings of the problem ("maybe the real problem is X, or Y, or Z?"). The operator picks one of yours and now they're refining your framing instead of theirs.
- Do not label phrases ("'task graph' is a shape-phrase"). Classification biases the dialogue.
- Do not classify in the open ("Tech-D classification: [X] → constraint"). Track inferences silently if at all.
- Do not ask compound questions ("What's your scale and your audience?"). One question per turn.
- Do not name the contradiction when Reductio lands the operator in aporia. Hold the silence.
- Do not present axes to the operator as a checklist. Axes are teacher-side reminders in `references/socratic-patterns.md`.
- Do not run a structured red-team pass. The readback turn (step 4) is the entire convergence check.
- Do not ask the operator for sources, citations, or external-vs-preference classifications. Those questions belong in `/solution` where they evaluate *shapes against a validated problem*.
- Do not produce multi-paragraph turns. One question, brief mirror if needed, done.

### Anti-patterns

(Full anti-patterns list with examples is in `references/socratic-patterns.md`. The summary:)

- ❌ Offering alternatives.
- ❌ Labeling phrases.
- ❌ Classifying in the open.
- ❌ Compound questions.
- ❌ Naming the contradiction.
- ❌ Asking questions whose answers won't change anything.
- ❌ Over-mirroring (mirroring without testing).
- ❌ Listing axes to the operator.
- ❌ Running a structured red-team or classification pass.
- ❌ Verbose elaboration (multi-paragraph turns, multiple restatements, exposition before the question).

### Checkpoint discipline

The plugin's hook mirrors the raw session JSONL into `docs/socrates/discover/.wip/<slug>/<session-id>.jsonl` after every turn — automatically, with no agent action required. Your only checkpoint duty is at session end: surface the readback ledger (the proposed Framing + Outcomes), append it to the WIP file, then run gates and write the artifact.

If a session is interrupted mid-dialogue, the WIP file is left in place; the next `/discover resume <slug>` picks it up.

## Closing

When the operator approves wrap:

1. Run the artifact-time gates from `references/artifact-gates.md` against the assembled draft. If any gate fails, do NOT write — surface failures grouped by gate name, peel the offending phrases via one more Socratic turn, and re-run all gates.
2. Once gates pass, write the discovery artifact to `docs/socrates/discover/<topic-slug>.md` using the template at `references/artifact-template.md`.
3. Finalize the session per `../../shared/checkpoint-protocol.md`: move the JSONL transcript directory out of `.wip/`, remove the WIP file, commit the artifact + transcript together.

Then tell the operator:

> "Problem captured at `docs/socrates/discover/<topic-slug>.md`. To proceed to solutioning (shape elicitation, chunking, build-vs-buy research, dispatch), run `/solution <topic-slug>`."

Handoff is operator-driven. Do not auto-dispatch `/solution`, and do not auto-launch `/superpowers`. Your job ends when the discovery artifact is committed and the handoff message is given.
````

- [ ] **Step 2: Verify the file replaced cleanly**

Run: `wc -l plugins/socrates/skills/discover/SKILL.md`
Expected: roughly 130-160 lines (down from 339).

Run: `grep -c "Tech-B\|Tech-D\|Tech-C\|premise check\|parked shape\|red-team\|RED-TEAM" plugins/socrates/skills/discover/SKILL.md`
Expected: 0 matches.

Run: `grep -c "Socratic\|socratic" plugins/socrates/skills/discover/SKILL.md`
Expected: multiple matches (the skill is now Socratic-centric).

- [ ] **Step 3: Verify the references are consistent**

Run: `grep -n "references/" plugins/socrates/skills/discover/SKILL.md`
Expected: references to `artifact-template.md`, `artifact-gates.md`, `socratic-patterns.md`. No reference to `research-protocol.md`.

- [ ] **Step 4: Commit**

```bash
git add plugins/socrates/skills/discover/SKILL.md
git commit -m "$(cat <<'EOF'
refactor(socrates): collapse /discover to single Socratic phase

Strip PREMISE CHECK / DISCOVER / RED-TEAM three-phase machinery and the
classification protocols (Tech-D verifiability rule, Tech-B 4-framings,
shape-language audit, structured red-team checks, soft-signal visible
counters, discovery-axes checklist). Replace with a single SOCRATIC
DIALOGUE phase that operates on the operator's stated problem using
Maieutic / Reductio / Parallel-case patterns from socratic-patterns.md.

The skill now: mirror once, ask Socratic questions until convergence,
read back the proposed artifact, write on operator approval. No more
alternative-enumeration, no more in-line classification, no more
structured adversarial passes.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Update `/solution/SKILL.md` — Phase 0 elicitation + Tech-B turn shift + drop Phase 2 check 9

**Files:**
- Modify: `plugins/socrates/skills/solution/SKILL.md`

- [ ] **Step 1: Replace the session-startup section**

Find the block starting `**New session** (`/solution <slug>`):` and the numbered steps that follow (current lines 71-90).

Replace step 2 of that block. The current step 2 reads:

```markdown
2. Read the parked-shapes section from the discovery artifact (and, if the WIP file `docs/socrates/discover/.wip/<slug>.wip.md` still exists, also read its `## Parked shapes` ledger). The parked-shapes list is the input set for Phase 0 SHAPE-DISCOVER.
```

Replace with:

```markdown
2. The discovery artifact no longer carries a parked-shapes ledger (per the Socratic rework: shapes are elicited fresh in `/solution`, not carried forward from `/discover`). If the artifact happens to be in the legacy format and contains a `## Parked shapes` section (i.e., it predates the rework), read it as a *starting hint* for the operator-elicitation turn — not as authoritative input. Otherwise proceed without a parked-shapes ledger.
```

- [ ] **Step 2: Replace the Phase 0 SHAPE-DISCOVER turn-1 opening**

Find the heading `### What you do in this phase` under `## Phase 0: SHAPE-DISCOVER` (currently around line 103). The first paragraph reads:

```markdown
You walk the parked-shapes list one entry at a time and run Tech-D on each. **You do not re-classify shapes that /discover already locked in as constraints** — those carry forward into the solution artifact unchanged (see Phase 4 G1). You classify the *unresolved* parked shapes (the ones with `resolved: false` in the parked-shapes ledger).
```

Replace with:

```markdown
SHAPE-DISCOVER opens with an **operator-elicitation turn**, then walks any elicited shapes one entry at a time and runs Tech-D on each.

**Elicitation turn (mandatory, turn 1).** After reading the discovery artifact (`## Framing` + `## Outcomes`), open by surfacing the validated problem and asking the operator what shapes / preferences / constraints they want to bring into solutioning:

> "Here's the validated problem and the outcomes from `/discover`:
>
> *[insert verbatim Framing]*
>
> *Outcomes:*
> - [outcome 1]
> - [outcome 2]
> - …
>
> What shapes, preferences, or constraints do you want to bring into how we solve this? Anything from your original framing that you want to evaluate — named tools, patterns, architectural choices, non-negotiables — surface it now."

The operator's reply seeds the shape-list. The agent THEN walks that list per the per-shape Tech-D protocol below. **No shapes carry forward from `/discover` automatically** — the validated problem is the only input.

If the discovery artifact is in the legacy format (`## Parked shapes` section present), use those entries as starting hints in your elicitation prompt: *"Your original framing also mentioned [list legacy parked shapes]. Want to bring any of those in, or are they no longer relevant?"* — the operator decides.
```

- [ ] **Step 3: Update Tech-B firing schedule**

Find the heading `**Tech-B firings on shape framings.**` (currently around line 128). The first numbered item reads:

```markdown
1. **Mandatory at SHAPE-DISCOVER turn 1**, immediately after reading the discovery artifact. Before walking the parked-shapes list, fire the 4-option shape spectrum.
```

Replace with:

```markdown
1. **Mandatory at SHAPE-DISCOVER turn 2**, immediately after the operator-elicitation turn. Fire the 4-option shape spectrum on the whole-problem solution shape. The No-build framing is the explicit form of "do you really need to build this?" at the solution level — keep it concrete.
```

- [ ] **Step 4: Remove Phase 2 RED-TEAM check 9**

Find the numbered check 9 in `## Phase 2: RED-TEAM (shapes only)` (currently around line 242):

```markdown
9. **Parked-shape resolution completeness** — every entry in /discover's parked-shapes ledger has a resolution path in this session's shape decisions, recorded with one of the template's allowed Resolution values (`Resolved` / `Dropped` / `Carried forward as open shape`). Walk the parked-shapes ledger and tick each off. Unresolved parked shapes are CRITICAL findings (Phase 4 G6 will also enforce mechanically).
```

Delete this entry entirely. Renumber subsequent checks if any exist (in current file, check 9 is the last; nothing to renumber).

- [ ] **Step 5: Update anti-patterns and reference text that mention parked shapes**

Find `## Phase 0` anti-pattern about parked shapes:

```markdown
- ❌ **Treating parked shapes as already-constraints.** A parked shape is *not* a constraint — it's a candidate with an outcome-question. Classify with Tech-D before recording in `## Shape decisions`. If you copy parked shapes forward without classification, Phase 4 G6 will fail.
```

Replace with:

```markdown
- ❌ **Treating operator-elicited shapes as already-constraints.** A shape elicited in turn 1 is *not* a constraint — it's a candidate. Classify with Tech-D before recording in `## Shape decisions`. "Operator stated it confidently" is not a source.
```

Find the line:

```markdown
- ❌ **Leaving a parked shape unresolved at exit.** Every entry in the parked-shapes ledger gets a classification and a recorded resolution. Phase 4 G6 enforces this mechanically; catching it now is cheaper.
```

Replace with:

```markdown
- ❌ **Leaving an elicited shape unresolved at exit.** Every shape surfaced during the turn-1 elicitation (or during later dialogue) gets a classification and a recorded resolution before SHAPE-DISCOVER exits.
```

- [ ] **Step 6: Update the description / when_to_use frontmatter to drop "parked shapes" reference**

Find the YAML frontmatter `description` field (currently mentions "parked shapes from /discover's discovery artifact"). Replace the relevant phrase. The current description fragment reads:

```yaml
description: >
  Socratic shape-evaluation downstream of /discover. Pressure-tests
  parked shapes from /discover's discovery artifact against the
  discovered outcomes (Tech-D classification of parked shapes as
  constraint / candidate / default-to-test; Tech-B alternative shape
  framings across the complexity spectrum). ...
```

Replace with:

```yaml
description: >
  Socratic shape-evaluation downstream of /discover. Elicits shapes,
  preferences, and constraints from the operator against the validated
  problem from /discover, pressure-tests them (Tech-D classification of
  each shape as constraint / candidate / default-to-test; Tech-B
  alternative shape framings across the complexity spectrum, including
  the No-build framing — "do you really need to build this?"). ...
```

(Keep the rest of the description unchanged. Same edit applies to `when_to_use` if it mentions "parked-shapes ledger" — replace with "validated problem from /discover".)

- [ ] **Step 7: Verify changes**

Run: `grep -c "parked shape\|parked-shape" plugins/socrates/skills/solution/SKILL.md`
Expected: small number (only in legacy-format compatibility notes; should be ≤ 4).

Run: `grep -n "check 9\|G6" plugins/socrates/skills/solution/SKILL.md`
Expected: no matches.

- [ ] **Step 8: Commit**

```bash
git add plugins/socrates/skills/solution/SKILL.md
git commit -m "$(cat <<'EOF'
refactor(socrates): /solution elicits shapes instead of reading ledger

Phase 0 SHAPE-DISCOVER no longer reads /discover's parked-shapes ledger
(which no longer exists post-Socratic-rework). Instead, opens with a
turn-1 elicitation: agent surfaces the validated problem + outcomes,
asks the operator what shapes / preferences / constraints they want to
bring in. Tech-B fires at turn 2 (after elicitation). Phase 2 RED-TEAM
check 9 (parked-shape resolution completeness) is dropped.

Backward-compat: if the discovery artifact is in legacy format with a
## Parked shapes section, use entries as starting hints — never as
authoritative input.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Remove G6 + cross-references from `/solution/references/solution-gates.md`

**Files:**
- Modify: `plugins/socrates/skills/solution/references/solution-gates.md`

- [ ] **Step 1: Delete the Gate 6 section**

Find the heading `## Gate 6: Parked-shapes resolution gate (NEW)` (currently line 144). Delete from that heading through the end of the Gate 6 section (currently line 186, ending just before `## Failure handling (cross-gate)`).

- [ ] **Step 2: Update cross-references**

Find the line (currently line 9):

```markdown
G1–G4 are shape-analogs of `/discover`'s artifact gates, adapted to apply to the `## Shape decisions` section instead of `## External constraints` and `## Open axes`. G5 and G6 are NEW: they enforce the cross-artifact contract that no discovered outcome and no parked shape is silently lost between `/discover` and `/solution`.
```

Replace with:

```markdown
G1–G4 are shape-analogs of `/discover`'s artifact gates, adapted to apply to the `## Shape decisions` section. G5 is NEW: it enforces the cross-artifact contract that no discovered outcome is silently lost between `/discover` and `/solution`. (G6, the parked-shape resolution gate, was removed when `/discover` stopped producing a parked-shapes ledger.)
```

Find any other references to G6 in the file (search for the string `G6` and `parked-shape`):

Run: `grep -n "G6\|parked-shape" plugins/socrates/skills/solution/references/solution-gates.md`

For each match in failure-handling, cross-gate, or anti-pattern sections, either delete the line or rewrite to drop the G6 / parked-shape reference. Specific targets:

- Line 106 (mentions parked-shape reclassification): leave the line but drop the parked-shape clause. Change `(...) crept into a `[Constraint]` line during SHAPE-DISCOVER's reclassification of a parked shape.` → `(...) crept into a `[Constraint]` line during SHAPE-DISCOVER's reclassification.`
- Line 215 (failure handling step): delete the line `- G6 failures usually return to **SHAPE-DISCOVER** (a parked shape was forgotten). If the parked shape genuinely has no role, the resolution is `Dropped` with a specific reason — but it must appear in the table.`
- Line 227 (anti-pattern): change `Stopping at G1 and skipping the rest.** Run all six gates every iteration. A fix to G1 can break G2; a fix to G6 can reveal a missing G5 row.` → `Stopping at G1 and skipping the rest.** Run all five gates every iteration. A fix to G1 can break G2; a fix to G5 can reveal a missing row.`
- Line 228 (anti-pattern about G5/G6): change `**Treating G5 and G6 as soft / informational.** They are hard gates with mechanical and qualitative checks. The whole point of the /discover → /solution split is that the contract between the two artifacts is enforced — G5 and G6 are the enforcement.` → `**Treating G5 as soft / informational.** G5 is a hard gate with mechanical and qualitative checks. The whole point of the /discover → /solution split is that the cross-artifact contract is enforced — G5 is the enforcement.`
- Line 229 (anti-pattern): change `**Editing discovery.md to make G5 / G6 pass.** ...` → `**Editing discovery.md to make G5 pass.** ...` (preserve the rest of the line).

- [ ] **Step 3: Verify all G6 / parked-shape references are cleared**

Run: `grep -n "G6\|parked-shape\|parked shape" plugins/socrates/skills/solution/references/solution-gates.md`
Expected: 0 matches.

Run: `wc -l plugins/socrates/skills/solution/references/solution-gates.md`
Expected: roughly 180-190 lines (down from 229).

- [ ] **Step 4: Commit**

```bash
git add plugins/socrates/skills/solution/references/solution-gates.md
git commit -m "$(cat <<'EOF'
refactor(socrates): remove G6 parked-shape gate from solution-gates

G6 enforced parked-shape resolution between /discover and /solution.
After the Socratic rework, /discover no longer produces parked shapes,
so G6 has nothing to enforce. The G5 outcome-coverage gate still
enforces the cross-artifact contract that no discovered outcome is
lost.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Refresh `/discover/evals/evals.json` for Socratic-dialogue grading

**Files:**
- Modify: `plugins/socrates/skills/discover/evals/evals.json`

- [ ] **Step 1: Read the current evals**

Run: `cat plugins/socrates/skills/discover/evals/evals.json`

Today's evals grade against structural outputs (parked-shapes ledger entries, External constraints section presence, Tech-D classifications). After the rework, those structures no longer exist.

- [ ] **Step 2: Replace evals.json with Socratic-dialogue graders**

The existing schema uses `id` / `prompt` / `expected_output` / `files` / `expectations` per eval entry. Replace the contents of `plugins/socrates/skills/discover/evals/evals.json` with:

```json
{
  "skill_name": "discover",
  "evals": [
    {
      "id": 1,
      "prompt": "I want to deploy agents for my team that can communicate",
      "expected_output": "The skill opens by mirroring the stated problem in the operator's language, then asks Socratic questions (Maieutic / Reductio / Parallel-case) to test what the operator means by 'agent', 'communicate', and 'team'. Each turn is short — 1 to 4 sentences asking one question, no multi-paragraph elaborations. The agent does not classify phrases as shape-language, does not enumerate alternative framings, does not announce a red-team mode shift, and does not run any premise check. The final discovery artifact has only Framing (with Original statement + Key reframes) + Outcomes + Discovery log — no External constraints, no Parked shapes, no Open axes, no Red-team findings.",
      "files": [],
      "expectations": [
        "Turn 1 mirrors the operator's stated problem in their own language before asking any Socratic question (e.g., 'Let me restate: you're saying X. Is that right?')",
        "Each operator-facing turn is 1–4 sentences asking one question (excluding the readback turn, which may be slightly longer because it surfaces the proposed Framing + Outcomes). No turn contains multi-paragraph elaborations or multiple restatements of the same idea.",
        "Label structure stays light — single-question turns use §Q1 alone and do not nest §1.1.1.1 subsections inside short replies",
        "The agent never enumerates 2+ alternative framings of the problem in a single turn (no 'Maybe the real problem is X, or Y, or Z?' patterns)",
        "When 'agent' appears as a specific shape, the agent asks a Socratic question about what it gives the operator (e.g., 'tell me about agents — what does that give you?') rather than classifying it as shape-language",
        "The agent does not say 'Tech-D', 'Tech-B', 'external source', 'preference', 'parked shape', 'shape-language', 'classification', 'V1-justified', or 'future-pull' in any operator-facing turn",
        "The agent does not announce a red-team mode shift, does not list severity-classified findings (CRITICAL / DISCUSS / MINOR), and does not run a structured 6-check adversarial pass",
        "Convergence is signaled by the readback turn ('I think the problem is stable. Here's what I'd write: [refined problem] / [outcomes]. Want to keep digging or wrap?'), not by a phase-exit ledger surfacing structural categories",
        "The discovery artifact contains exactly these sections: ## Framing, ### Original statement, ### Key reframes, ## Outcomes, ## Discovery log",
        "The artifact does NOT contain: ## External constraints, ## Parked shapes, ## Open axes, ## Red-team findings",
        "The Framing and Outcomes sections contain no named technologies / protocols / patterns / architectural choices as proposed *how* (system-name nouns describing the world are acceptable; proposed solutions are not)"
      ]
    },
    {
      "id": 2,
      "prompt": "Build me a todo app",
      "expected_output": "The skill recognizes that 'todo app' is shape-language in the prompt and Socratically peels back to the underlying want (what tracking, for whom, why current methods fail). It does not classify 'todo app' as a parked shape — it asks the operator what an app would give them. The final artifact has Framing + Outcomes only; no chunk decomposition, no build-vs-buy evaluation.",
      "files": [],
      "expectations": [
        "Turn 1 mirrors the stated problem (e.g., 'You're saying you want a todo app. Tell me what tracking you're missing right now')",
        "The agent asks Socratic questions that peel the shape 'todo app' back to the underlying want, without ever labeling it as a shape",
        "The agent does NOT propose chunk decomposition (chunking is /solution's responsibility)",
        "The agent does NOT run a build-vs-buy / existence check (that lives in /solution's RESEARCH phase)",
        "The agent does NOT announce a red-team mode shift",
        "The discovery artifact's Framing is problem-language (e.g., 'operator is missing reliable per-task progress visibility across projects') — not 'operator wants a todo app'"
      ]
    },
    {
      "id": 3,
      "prompt": "We need a platform with auth, billing, a marketplace, and analytics",
      "expected_output": "The skill recognizes that this is a multi-subsystem prompt and Socratically probes which subsystem represents the most pressing want — possibly surfacing that one subsystem is the real problem and the others are downstream assumptions. It does not enumerate the subsystems back as a checklist or classify them as parked shapes; it asks Socratic questions to test which subsystem the operator actually cannot live without. The artifact's Outcomes reflect what survived the dialogue, not the original four-subsystem framing.",
      "files": [],
      "expectations": [
        "Turn 1 mirrors the stated problem (e.g., 'You're saying you need auth, billing, a marketplace, and analytics. Which of those, if it didn't work, would make the whole thing useless to you?')",
        "The agent does NOT present the four subsystems back to the operator as a numbered list or checklist",
        "The agent uses parallel-case or Maieutic to test which subsystem is the actual driver",
        "The agent does NOT enumerate '4 ways to think about this problem' (Complex / Middle / Low / No-build framings)",
        "The artifact does NOT contain a 'Parked shapes' section listing the four subsystems",
        "The Outcomes section reflects what survived dialogue, possibly fewer than four subsystems"
      ]
    },
    {
      "id": 4,
      "prompt": "Build a REST API using Express with Postgres and deploy to AWS ECS",
      "expected_output": "Heavily over-specified prompt with four named technologies. The skill Socratically peels each named technology by asking what it gives the operator and what would change without it — without classifying them as shape-language or asking for external sources. The artifact's Framing is problem-language only (e.g., 'operator needs a server that responds to HTTP from clients X and serves data from store Y'); no named technologies in Framing or Outcomes.",
      "files": [],
      "expectations": [
        "Turn 1 mirrors the stated problem and asks a Socratic question about the underlying want, without classifying any of the four named technologies",
        "The agent asks at least one Socratic question of the form 'tell me about [tech] — what does that give you?' or 'how would you know if you were wrong about [tech]?' for at least one of the four named technologies",
        "The agent does NOT say 'external source', 'Tech-D', 'parked shape', or 'shape-language'",
        "The agent does NOT enumerate 4 framings (Complex / Middle / Low / No-build) of the problem",
        "The Framing in the artifact does not contain 'REST', 'Express', 'Postgres', or 'AWS ECS' as proposed solutions",
        "The Outcomes section does not contain any of the four named technologies as proposed how",
        "If 'AWS' or another system-name nouns survives in Framing, it is as a description of the world (e.g., 'users authenticated through our existing AWS-hosted Okta tenant') — not as a proposed deployment target"
      ]
    },
    {
      "id": 5,
      "prompt": "[/solution smoke test] Given a synthetic discovery.md with Framing 'operator's team is missing per-task progress visibility across the M365 environment' and Outcomes ['team members can see what tasks are in flight without asking', 'task progress is visible without manual status meetings'] — run /solution's SHAPE-DISCOVER phase.",
      "expected_output": "/solution's SHAPE-DISCOVER phase reads the discovery artifact (Framing + Outcomes only — no parked-shapes ledger to read). Turn 1 is an operator-elicitation: the agent surfaces the validated problem + outcomes and asks the operator what shapes, preferences, or constraints they want to bring in. Turn 2 fires Tech-B with the 4-option shape spectrum (Complex / Middle / Low / No-build), where No-build is the explicit form of 'do you really need to build this?'. The Discovery → Solution mapping table contains a row for every outcome (per G5). There is no parked-shapes resolution table and no G6 enforcement.",
      "files": [],
      "expectations": [
        "Phase 0 (SHAPE-DISCOVER) turn 1 is the operator-elicitation prompt: the agent surfaces the Framing + Outcomes and asks 'What shapes, preferences, or constraints do you want to bring into solutioning?'",
        "The agent does NOT attempt to read a '## Parked shapes' section from the discovery artifact (the new artifact has none)",
        "If the operator surfaces shapes during turn 1, Tech-D fires on each in turn",
        "Phase 0 turn 2 (after elicitation) fires Tech-B with exactly 4 shape framings: Complex / Middle / Low / No-build, where No-build is the explicit form of 'do you really need to build this?'",
        "The solution artifact's '## Discovery → Solution mapping' table contains a row for each outcome from the discovery artifact (per G5)",
        "The solution artifact does NOT contain a '## Parked shapes resolution' table",
        "The agent does NOT cite or check Gate 6 (parked-shapes resolution gate)"
      ]
    }
  ]
}
```

- [ ] **Step 3: Verify JSON is valid**

Run: `python3 -c "import json; json.load(open('plugins/socrates/skills/discover/evals/evals.json'))"`
Expected: no output (valid JSON).

- [ ] **Step 4: Commit**

```bash
git add plugins/socrates/skills/discover/evals/evals.json
git commit -m "$(cat <<'EOF'
test(socrates): refresh evals for Socratic-dialogue grading

Keep the five existing eval prompts (vague, over-specified todo,
multi-subsystem, over-specified REST API, /solution smoke test) and
rewrite the expected_output + expectations to grade the new behavior:
mirror in turn 1, no alternative-enumeration, no in-line classification
(no 'Tech-D', 'parked shape', 'shape-language', etc.), no structured
red-team mode shift, artifact has only Framing/Outcomes/Discovery-log
sections, Framing/Outcomes contain no shape-language as proposed how.

Eval 5 (/solution smoke test) updated to grade the turn-1 elicitation
prompt and the absence of parked-shapes-table / G6 enforcement.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Update `/discover/evals/methodology.md` grading criteria

**Files:**
- Modify: `plugins/socrates/skills/discover/evals/methodology.md`

- [ ] **Step 1: Read the current methodology**

Run: `cat plugins/socrates/skills/discover/evals/methodology.md`

- [ ] **Step 2: Replace methodology with Socratic-dialogue grading criteria**

Replace the contents of `plugins/socrates/skills/discover/evals/methodology.md` with content that explains, in plain prose:

- What `/discover` is now (single Socratic phase).
- What the new graders check (mirror, no alternatives, no classification, no red-team, artifact-structure, artifact-problem-language).
- How to run a manual eval: pick a problem from `test_cases` in evals.json, run `/discover <problem>`, transcribe the dialogue, run each grader against the transcript / artifact, record results.
- Pass criterion: all `trigger-eval` graders return zero false-positives; both `artifact-eval` graders pass; manual review confirms convergence happened (operator approved wrap, not forced).
- Known limitations: shape-language detection is heuristic (no LLM grader yet); manual review still required for dialogue quality (cases land vs. cases miss).

Write this as ~80-120 lines of explanatory prose. Do not include code snippets unless needed for the grader-run commands. Replace any reference to Tech-B / Tech-D / Phase 0 / Phase 2 / parked shapes / External constraints / Open axes that exists in the current methodology.

- [ ] **Step 3: Verify references**

Run: `grep -n "Tech-B\|Tech-D\|Tech-C\|premise check\|parked shape\|PREMISE CHECK\|RED-TEAM" plugins/socrates/skills/discover/evals/methodology.md`
Expected: 0 matches (or only in a "what changed from the previous version" backward-compat note, which is optional).

- [ ] **Step 4: Commit**

```bash
git add plugins/socrates/skills/discover/evals/methodology.md
git commit -m "$(cat <<'EOF'
docs(socrates): update /discover eval methodology for Socratic grading

Replace structural-output grading criteria (Tech-D classifications,
parked shapes, External constraints) with Socratic-dialogue criteria
(mirror, no alternatives, no classification, no red-team, artifact
sections + problem-language).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Update PR2 smoke test report

**Files:**
- Modify: `plugins/socrates/evals/reports/pr2-discover-smoke-test.md`

- [ ] **Step 1: Read the current report**

Run: `cat plugins/socrates/evals/reports/pr2-discover-smoke-test.md`

The current report captures a PR2-era smoke test under the old multi-phase protocol.

- [ ] **Step 2: Append a "Socratic rework supersession" section**

Add a new section at the top (or as a footer if the top is locked) that says:

```markdown
## Socratic rework supersession (2026-05-19)

This smoke-test report reflects `/discover` behavior under the prior multi-phase protocol (PREMISE CHECK / DISCOVER / RED-TEAM with Tech-B 4-framings, Tech-D classification, shape-language audit, parked-shapes ledger, structured red-team). That protocol was replaced on 2026-05-19 with a single Socratic-dialogue phase (see `docs/superpowers/specs/2026-05-19-discover-pure-socratic-design.md` and plan `docs/superpowers/plans/2026-05-19-discover-pure-socratic.md`).

**Status of findings below:**

- Structural findings (artifact has X section, ledger has Y entry, gate Z fires) are **no longer applicable** — the relevant structures don't exist in the new artifact.
- Dialogue-quality findings (premise check enumerates concrete paths, Tech-B's 4 framings are equal-weight, etc.) are **superseded** — the protocol they exercise no longer runs.

Retained as a historical record of pre-rework behavior. A fresh smoke test under the Socratic rework will be added when the new evals run end-to-end.
```

- [ ] **Step 3: Commit**

```bash
git add plugins/socrates/evals/reports/pr2-discover-smoke-test.md
git commit -m "$(cat <<'EOF'
docs(socrates): mark PR2 smoke-test report as superseded by rework

The PR2-era smoke test reflects pre-Socratic /discover behavior. Add a
top-of-file supersession note pointing to the 2026-05-19 spec and plan;
keep the report as a historical record.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Update `TODO.md` and `LIMITATIONS.md`

**Files:**
- Modify: `plugins/socrates/TODO.md`
- Modify: `plugins/socrates/LIMITATIONS.md`

- [ ] **Step 1: Append to TODO.md**

Add a new section at the end of `plugins/socrates/TODO.md`:

```markdown
## Post-Socratic-rework follow-ups (2026-05-19)

The Socratic rework (spec: `docs/superpowers/specs/2026-05-19-discover-pure-socratic-design.md`) deferred:

- [ ] **Fresh end-to-end smoke test under the new `/discover`.** The PR2 smoke test is now superseded. Run the three test cases from `evals.json` (vague, over-specified, self-aporia) and capture results in `evals/reports/2026-05-19-discover-socratic-smoke-test.md`.
- [ ] **Deeper Socratic alignment of `/solution`.** Today `/solution` uses Tech-D classification and Tech-B 4-option enumeration as its primary tools — those are the same constructs we stripped from `/discover` for being non-Socratic. A follow-up could apply Maieutic / Reductio / Parallel-case patterns to shape decisions in `/solution` as well. Scoped as a separate spec.
- [ ] **LLM-grader for shape-language detection.** The Socratic eval has a `framing_must_not_contain_shape_language` artifact check that currently relies on a heuristic word list. An LLM grader would catch shape-language phrased in non-obvious ways (e.g., "a system that does X via Y" where Y is a shape).
- [ ] **Migration tooling for in-progress legacy WIPs.** `/discover resume <slug>` currently asks the operator to choose abandon-or-extract-and-ship for legacy WIPs. A small `socrates migrate-wip <slug>` could automate the extract path (read Framing + Outcomes from the WIP's existing ledger entries, write the new minimal artifact).
```

- [ ] **Step 2: Update LIMITATIONS.md**

Read `plugins/socrates/LIMITATIONS.md`. Search for any references to the removed constructs (Tech-D classification, Tech-B 4-framings, premise check, parked shapes, shape-language audit, RED-TEAM phase). For each, either remove the limitation entry (if it described a behavior that no longer exists) or rewrite to describe the new behavior.

Run: `grep -n "Tech-B\|Tech-D\|premise check\|parked shape\|RED-TEAM" plugins/socrates/LIMITATIONS.md`

For each match, evaluate whether the limitation:
(a) Described pre-rework behavior that no longer applies → delete the entry.
(b) Described a fundamental limit that still applies under the new protocol → rewrite without the removed-construct reference.

Add a new limitation entry at the bottom:

```markdown
## L-N: `/discover`'s convergence is agent-judgment only

Under the Socratic rework, `/discover` exits the dialogue when the agent detects convergence (problem stable across 2-3 turns, operator confirming rather than refining, or productive aporia) and the operator approves the readback. There is no structural counter (the soft-signal visible counter was removed) and no automated convergence test. If the agent's convergence judgment is poor (exits too early or digs too long), the operator must steer manually. Mitigation: the readback turn is mandatory and the operator can always say "keep digging."
```

(Replace `L-N` with the next available limitation number in the file.)

- [ ] **Step 3: Commit**

```bash
git add plugins/socrates/TODO.md plugins/socrates/LIMITATIONS.md
git commit -m "$(cat <<'EOF'
docs(socrates): update TODO and LIMITATIONS post-Socratic-rework

TODO.md: add four post-rework follow-ups (fresh smoke test, deeper
Socratic alignment of /solution, LLM-grader for shape-language, legacy
WIP migration tooling).

LIMITATIONS.md: remove or rewrite entries that referenced removed
constructs; add a new entry noting that convergence is agent-judgment
only (no structural counter).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: End-to-end verification walkthrough

**Files:**
- No file modifications (this is a verification task).

- [ ] **Step 1: Walk a vague-problem scenario in head**

Read `plugins/socrates/skills/discover/SKILL.md`, `plugins/socrates/skills/discover/references/socratic-patterns.md`, and `plugins/socrates/skills/discover/references/artifact-template.md` together.

Use eval id=1 from `evals.json` as the input: operator input is *"I want to deploy agents for my team that can communicate."*

Walk through the dialogue in your head:

1. What does the agent's first turn look like? (Should be: mirror the stated problem + first Socratic question. E.g., *"Let me restate: you're saying you want a way for the people on your team to use agents — and for those agents to talk to each other or to people. Is that right? When you say 'agents' — tell me what an agent would do that isn't happening today."*)
2. What does turn 2 look like after the operator answers? (Should be a follow-up Socratic question — case test, premise walk, or parallel.)
3. What does the convergence readback look like?
4. What does the final artifact look like? Does it have only Framing / Original / Reframes / Outcomes / Discovery log?

Confirm the dialogue passes the eval id=1 expectations (mirror, no alternative-enumeration, no in-line classification, no red-team announcement, artifact has only the four required sections, Framing is problem-language).

- [ ] **Step 2: Walk an over-specified scenario in head**

Use eval id=4 from `evals.json` as the input: operator input is *"Build a REST API using Express with Postgres and deploy to AWS ECS."*

Walk through:

1. First turn: how does the agent handle the named shapes (REST, Express, Postgres, AWS ECS) without classifying them?
2. What Socratic peel does the agent use? (Should be: *"Tell me about [shape] — what does it give you?"* or *"How would you know if you were wrong about [shape]?"*)
3. What does the artifact's Framing look like? Confirm it contains the underlying *want*, not the shapes.

Confirm the artifact passes the eval id=4 expectations (Framing/Outcomes contain none of REST, Express, Postgres, AWS ECS as proposed how).

- [ ] **Step 3: Walk a `/solution` handoff scenario in head**

Read `plugins/socrates/skills/solution/SKILL.md` Phase 0 SHAPE-DISCOVER. Assume `/discover` has produced an artifact at `docs/socrates/discover/team-pm-bottleneck.md` with Framing + Outcomes only (no parked-shapes section).

Walk through:

1. What does `/solution`'s Phase 0 turn 1 look like? (Should be the elicitation prompt: *"Here's the validated problem and outcomes: [...]. What shapes, preferences, or constraints do you want to bring into how we solve this?"*)
2. What does turn 2 look like? (Should be Tech-B 4-option framing including the No-build option.)
3. Confirm `/solution` does not try to read a parked-shapes section that doesn't exist.

- [ ] **Step 4: Walk a legacy-artifact compatibility scenario in head**

Assume `/discover` produced an artifact at `docs/socrates/discover/legacy-thing.md` *before* the rework, containing a `## Parked shapes` section with three entries.

Walk through `/solution`'s Phase 0 turn 1 under the new protocol:

1. Does the agent crash or fail? (Should: no.)
2. Does the agent treat the parked-shapes entries as authoritative? (Should: no — only as starting hints.)
3. What does the elicitation prompt say? (Should mention the legacy entries as hints: *"Your original framing also mentioned [list]. Want to bring any of those in, or are they no longer relevant?"*)

- [ ] **Step 5: Walk a gate-failure scenario in head**

Imagine an operator who said *"I want to build a Plane-integrated agent"* and the dialogue did not fully peel "Plane-integrated" — the agent's draft Framing reads *"users need a Plane-integrated way to manage tasks."*

Walk through the gate run:

1. Does G1 (problem-language gate) fire? (Should: yes — "Plane-integrated" is shape-language as proposed how.)
2. What does the failure message look like?
3. What does the fixup prompt look like? (Should be one more Socratic peel: *"You wrote 'Plane-integrated' in the problem statement. What is the underlying want that Plane-integration is a proposed answer to?"*)
4. After the operator answers (e.g., *"I want my tasks to be visible to everyone"*), what does the corrected Framing look like?

- [ ] **Step 6: If any walkthrough surfaces a gap, fix it and re-walk**

If any of steps 1-5 reveal an inconsistency in the new SKILL.md, references, or evals, fix the file inline (with a small additional commit per fix). Re-walk the affected scenario.

If all walkthroughs pass: no commit needed for this task. Move to the implementation summary.

- [ ] **Step 7: Optional — final cleanup commit**

If any small fixes accumulated during the walkthrough, commit them as a single follow-up:

```bash
git add <fixed-files>
git commit -m "$(cat <<'EOF'
docs(socrates): walkthrough cleanup for Socratic rework

Small follow-up fixes surfaced by the end-to-end verification
walkthrough.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Done criteria

- All 12 tasks committed.
- `plugins/socrates/skills/discover/SKILL.md` is ~130-160 lines, single SOCRATIC phase, no Tech-B / Tech-D / premise-check / RED-TEAM references.
- `plugins/socrates/skills/discover/references/socratic-patterns.md` exists with three pattern examples + teacher reminders + anti-patterns.
- `plugins/socrates/skills/discover/references/artifact-template.md` is minimal (Framing / Outcomes / Discovery log only).
- `plugins/socrates/skills/discover/references/artifact-gates.md` is G1 + G2 only.
- `plugins/socrates/skills/discover/references/research-protocol.md` is deleted.
- `plugins/socrates/skills/solution/SKILL.md` has turn-1 elicitation, Tech-B at turn 2, no Phase 2 check 9.
- `plugins/socrates/skills/solution/references/solution-gates.md` has no G6, no parked-shape references.
- `plugins/socrates/skills/discover/evals/evals.json` grades Socratic-dialogue qualities.
- `plugins/socrates/skills/discover/evals/methodology.md` is rewritten for the new graders.
- `plugins/socrates/evals/reports/pr2-discover-smoke-test.md` is annotated as superseded.
- `plugins/socrates/TODO.md` lists four post-rework follow-ups.
- `plugins/socrates/LIMITATIONS.md` no longer references removed constructs; has a new agent-judgment-convergence entry.
- All five walkthrough scenarios in Task 12 land cleanly.
