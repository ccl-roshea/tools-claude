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

- **No multi-paragraph elaborations.** If a turn is more than ~4 sentences, it's exposition, not a Socratic question. Cut it.
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
