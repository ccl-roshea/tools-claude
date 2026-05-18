# Research Protocol (Shallow Existence Check)

> Phase names (PREMISE CHECK, DISCOVER, RED-TEAM) and the overall flow are defined in `../SKILL.md`. This file expands the discovery-portion existence check only. The rigorous build-vs-buy evaluation (per-chunk candidate scoring, classification, soft limits) lives in `/solution`'s own research protocol.

## Why this file exists

`/discover` is outcome-focused. It does not chunk, it does not pick shapes, and it does not run a rigorous build-vs-buy evaluation. But the *existence question* — "is there already an obvious tool that reaches this outcome?" — is part of pressure-testing the outcomes themselves. If a discovered outcome is trivially served by an existing tool the operator hasn't considered, that is an outcome-level signal worth surfacing before `/solution` ever runs.

This file scopes that shallow check. It exists so the agent has a written floor for "should I mention the existing tool" vs. "should I rigorously evaluate it" — the former belongs in `/discover`, the latter does not.

## When the shallow existence check fires

The check can fire informally in two places:

1. **During Phase 0 PREMISE CHECK.** The no-build path enumeration already surfaces existing tools when they are obvious ("use Plane's MCP directly", "improve the existing markdown POC"). That is the existence check operating in its first natural home. No additional protocol needed.
2. **During Phase 2 RED-TEAM.** If, while reviewing the discovered outcomes, an obvious existing tool would reach an outcome without any building, surface it as a RED-TEAM finding. Severity is usually DISCUSS — the operator should know the tool exists before `/solution` starts shape-discovery on a redundant build.

The check is *shallow* in both places: name the tool, name what outcome it would reach, ask whether the operator has considered it. Do not score it, do not classify it, do not write a candidate evaluation. The deep evaluation is `/solution`'s job.

## What "shallow" means concretely

A shallow existence check produces output like this, recorded as a RED-TEAM DISCUSS finding:

> "Existence check: outcome '[name]' could plausibly be reached by adopting [tool / service / library], which already does [what it does]. I am not scoring it here — that's `/solution`'s job. But before we cement the outcome as a build target: has the operator considered this option, and is there an external source that rules it out?"

That is the whole protocol. It produces a question, not a recommendation, and not a scored evaluation.

A shallow existence check does NOT include:
- Per-chunk searches (no chunks exist yet at /discover).
- A candidate scoring rubric.
- A classification verdict.
- Soft limits on per-session research time.
- Detailed cost / license / lock-in evaluation.

All of the above live in `/solution`'s research protocol, where shape-discovery and chunking have produced the structure that makes scoring meaningful.

## Handoff to `/solution`

If the shallow check surfaces a candidate tool that the operator wants to evaluate seriously, record it in the discovery artifact as part of the relevant RED-TEAM finding — but do NOT evaluate it. `/solution`'s RESEARCH phase will pick it up and run the rigorous build-vs-buy evaluation with proper candidate scoring.

The discovery artifact records the existence-check finding; `/solution` records the evaluation.

## Anti-patterns

- ❌ **Running a rigorous evaluation inside /discover.** Scoring candidates, classifying verdicts, evaluating cost/license/lock-in — all of that is `/solution`'s job. `/discover` only asks the existence question.
- ❌ **Skipping the existence question entirely.** If an obvious tool exists and the operator hasn't considered it, the outcome is half-discovered. Surface the question even if the answer is "yes, considered, ruled out" — record the ruling reason.
- ❌ **Treating the existence check as a Phase of its own.** It isn't. It rides on Phase 0's no-build enumeration and Phase 2's RED-TEAM. No separate phase, no separate ledger.
- ❌ **Refusing to name a tool because "we haven't researched it properly yet."** Naming the tool *is* the check. Proper research is `/solution`'s job; the check exists precisely to flag the question for `/solution` to answer.
