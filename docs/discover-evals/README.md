# /discover Skill — Evaluation Evidence

Test outputs from validating the `/discover` skill. These are not real discovery work — they're evidence about how the skill behaves on representative prompts.

## Layout

- **`iteration-1/`** — Initial structural smoke tests via skill-creator self-answering subagent. 4 eval prompts (vague-agents, todo-app, multi-subsystem, overspecified). All passed except one borderline assertion. See `iteration-1/SUMMARY.md`.
- **`iteration-2/`** — Re-run of Eval 1 after fixing the borderline assertion (added "Discovery axes to consider" guidance to Phase 1). Confirmed the fix. See `iteration-2/SUMMARY.md`.
- **`produced-artifacts/`** — The discovery artifact files the eval runs produced (i.e., `docs/discovery/<slug>.md` outputs from inside the eval subagent runs). Kept here because they are eval outputs, not real discoveries.

## Path B (Test 1) — primary validation

The Path B clean-room run against the Path A baseline lives elsewhere:

- Transcript: external at `/test-path-b/discovery-transcript.md` (1,024 lines, operator's clean-room session)
- Artifact: external at `/test-path-b/docs/discovery/team-agent-platform.md`
- Scoring: `docs/superpowers/specs/2026-04-23-socratic-discovery-test-cases.md` (Path B results section)

Result: Path B beat Path A by Coverage +3 (2→5) and Correctness of Frame +1.5 (3→4.5). Both axes beat the +1 threshold.

## Validation summary

- **Iteration evals (this directory):** 47/48 → 14/15 across two iterations. Structural smoke test only — pairs same-LLM with same-LLM, can't reproduce sycophancy failure mode.
- **Path B Test 1 (operator-driven):** PASS by wide margin. Real validation.
- **Tests 2 and 3:** deferred (`skills/discover/TODO.md`).

## Skill-creator note

Skill-creator's `<skill-name>-workspace/` convention places eval workspaces next to the skill (`skills/discover-workspace/`). For ship state, we moved this here (`docs/discover-evals/`) to keep `skills/<name>/` reserved for the skill itself. If skill-creator is re-run on `/discover` for iteration 3, it will create `skills/discover-workspace/` again — move the new outputs here after the run for consistency.
