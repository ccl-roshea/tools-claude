# Evaluation Methodology for `/discover` Sessions

This document explains how to evaluate a `/discover` session against the evals in `evals.json`. It is the human-operator guide for understanding what the graders check, how to run a manual eval, what counts as a pass, and where the methodology has known limits.

## What `/discover` is now

`/discover` is a single Socratic-dialogue phase. The skill takes the operator's stated problem, mirrors it once, and then asks one Socratic question per turn (Maieutic, Reductio, or Parallel-case) until the problem statement is stable or productive aporia is reached. When the operator approves wrapping, the skill writes a minimal discovery artifact with four sections: `## Framing` (with `### Original statement` and `### Key reframes`), `## Outcomes`, and `## Discovery log`.

There is no premise check, no red-team pass, no structured alternative-framings turn, no shape-language classification, no parked-shapes ledger, and no external-constraints section. The artifact is problem-language only. All shape elicitation and build-vs-buy research happen downstream in `/solution`.

The skill reference is `plugins/socrates/skills/discover/SKILL.md`. The artifact format is in `references/artifact-template.md`. The artifact gates are in `references/artifact-gates.md`.

## What the graders check

`evals.json` has five test cases. Each test case has a `prompt` (what you feed `/discover`) and an `expectations` list (what a reviewer checks in the resulting transcript and artifact). The expectations cluster into six grader-criteria areas:

**Mirror.** Turn 1 must restate the operator's stated problem in the operator's own language before asking any Socratic question. The expectation is explicit: the agent opens by saying "Let me restate: you're saying X. Is that right?" before doing anything else.

**No alternatives.** The agent must not enumerate two or more alternative framings of the problem in a single turn. The Socratic method works by having the operator refine *their own* framing, not by having the agent present framings for selection. Any turn containing "Maybe the real problem is X, or Y, or Z?" is a failure on this grader.

**No classification.** The agent must not label phrases as shape-language, must not say "Tech-D", "parked shape", "external source", "V1-justified", "future-pull", or "classification" in any operator-facing turn. When a named technology or pattern appears, the grader checks that the agent asked a Socratic question about what it gives the operator — not that it was classified or listed back.

**No red-team.** The agent must not announce a red-team mode shift, must not produce severity-classified findings (CRITICAL / DISCUSS / MINOR), and must not run a structured adversarial-checks pass. Convergence is signaled by the readback turn, not by a phase-exit ledger.

**Artifact structure.** The written artifact must contain exactly the sections `## Framing`, `### Original statement`, `### Key reframes`, `## Outcomes`, and `## Discovery log`. It must NOT contain `## External constraints`, `## Parked shapes`, `## Open axes`, or `## Red-team findings`.

**Artifact problem-language.** The `## Framing` and `## Outcomes` sections must contain no named technologies, protocols, patterns, or architectural choices proposed as *how*. System-name nouns that describe the world (e.g., "our existing AWS-hosted Okta tenant") are acceptable; proposed deployment targets, frameworks, or tool choices are not.

## How to run a manual eval

1. Open `evals/evals.json` and pick one test case by `id`. Note its `prompt`.

2. Start a fresh Claude Code session in this repository and run `/discover <prompt>`. Do not intervene except to answer the agent's Socratic questions naturally, as a real operator would.

3. Once the session completes (artifact written to `docs/socrates/discover/<slug>.md`), export the session transcript. The plugin mirrors it automatically to `docs/socrates/discover/.wip/<slug>/<session-id>.jsonl` during the session; after artifact commit it moves to `docs/socrates/discover/<slug>/`.

4. Open the test case's `expectations` list. For each expectation, check whether it is satisfied in the transcript or artifact. Each expectation is binary: observable in the record or not.

   - For transcript-side expectations (turn 1 mirrors, no "Tech-D" in operator turns, turn length, no red-team announcement): scan the JSONL assistant turns.
   - For artifact-side expectations (correct sections present, absent sections absent, Framing contains no named technologies): read `docs/socrates/discover/<slug>.md`.

5. Record a pass/fail per expectation. Write up any failures with transcript turn numbers or artifact line numbers as evidence.

6. Repeat for each remaining test case in `evals.json` (currently five cases, covering vague multi-word prompts, shape-language prompts, multi-subsystem prompts, and over-specified technology prompts).

## Pass criterion

A test case passes when every expectation in its `expectations` list is satisfied — observable as true in the transcript or artifact. There is no partial credit: a single failed expectation is a test-case failure.

A full eval run passes when all five test cases pass. Because the expectations are binary and ground-observable, no LLM grader is required; a human reviewer can check them directly.

Convergence quality (did the cases actually land for the operator? did aporia happen or did the operator just give up?) requires a separate manual judgment. The expectations list does not capture convergence quality directly — it captures structural compliance. A session can pass every expectation and still have produced weak dialogue. Manual review of the transcript's question quality is always required for a complete evaluation.

## Known limitations

**Shape-language detection is heuristic.** The expectation "the agent asked a Socratic question about what it gives the operator" (rather than classifying the shape) is checked by reading the transcript — there is no automated LLM grader that scores whether the question was genuinely Socratic versus a surface-level rewrite. A question like "What does 'Express' give you?" satisfies the literal expectation; a question like "If Express weren't available, what would change for you?" is better. The methodology does not distinguish these mechanically.

**Dialogue quality requires manual review.** The cases-land vs. cases-miss distinction — whether the Socratic questions actually moved the operator's framing, whether Reductio produced productive aporia, whether Parallel-case exposed an asymmetry the operator hadn't seen — is undetectable from binary expectations alone. Each full eval run should include a qualitative read of at least one complete transcript by a human reviewer who notes whether the dialogue moved.

**Single-session samples.** Each test case runs against one session. Stochastic variation in the model means a single pass or fail may not be representative. For high-confidence eval results, run each test case two to three times and report the mode.

**No cross-session baseline.** The methodology grades sessions in isolation. There is no established distribution of scores to compare against.
