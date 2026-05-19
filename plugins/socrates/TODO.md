# Deferred Work

Items that were in the original implementation plan but deferred for the MVP ship. None blocks the skill being useful today; all strengthen it for broader use.

## Validation

- [ ] **Test 2 — additional real-problem validation.** Per memo §7, run a second real problem (different domain from agent-platform) through both Path A (/superpowers alone) and Path B (/discover → /superpowers). Score Coverage and Correctness. Adds to the validation N.
- [ ] **Test 3 — additional real-problem validation.** Same as Test 2, third domain.
- [ ] **Aggregate pass criterion** — confirm Path B wins in at least 2 of 3 tests. With Test 1 already passing convincingly, only one of Tests 2/3 needs to win for aggregate pass.

These are gating only if the skill is being shared with others. For solo use, Test 1's wide margin is sufficient evidence.

## Description optimization (full automated loop)

- [ ] **Run skill-creator's automated description loop** — `python -m scripts.run_loop --eval-set <trigger-evals> --skill-path skills/discover --model <model> --max-iterations 5`. The MVP shipped with a manual description tightening (added explicit over-specified-prompt trigger case). The full loop generates 20 trigger eval queries (mix should-trigger / should-not-trigger), iterates the description against them, picks the version with the best held-out test score. Worth doing if false-positive or false-negative triggering becomes a real problem in use.

## Iteration candidates (from LIMITATIONS.md)

(Both addressed in PR 1, 2026-05-15.)

## Future capability (deferred per spec)

- [ ] **Per-node executor dispatch.** The original spec named this as the most differentiating long-term feature. Currently the artifact recommends an executor per chunk as a human-readable annotation; there's no automated routing. Build when there are multiple specialist executors worth dispatching to.
- [ ] **Parallel dispatch.** Currently chunks run sequentially even when independent. Worth building when operator can context-switch between multiple in-flight /superpowers sessions, OR when /superpowers can run autonomously enough to not need HITL per turn.
- [x] **Cross-session resume.** ~~Currently a session that hits its budget and stops loses state.~~ Resolved by the JSONL-mirror hook: each Claude Code session that touches a discovery now writes its own `<session-id>.jsonl` into `docs/discovery/.wip/<slug>/`, and the WIP file's ledger entries provide the structured resume context. `/discover resume <slug>` reads the ledgers and continues; the new session's JSONL accumulates alongside the prior ones.

## PR 3 candidates

Forward-looking work surfaced by PR 2 that should be considered for the next iteration.

- [ ] **Multi-domain support / expert registry / domain-aware routing.** The plugin currently treats all problems with one generic Socratic frame. Real domain expertise (security, infra, ML, frontend, etc.) would require a registry of domain experts and routing of CHUNK questions to the right one. Build when cross-domain problems become the common case.
- [ ] **Per-node executor dispatch automation (beyond /superpowers).** Pairs with the long-standing executor-dispatch item above, but specifically: automate the dispatch step so the operator doesn't manually copy chunk prompts into /superpowers. Requires a stable dispatch interface across executors.
- [ ] **HIPAA scaffolding / PHI primitives.** Domain primitives for healthcare problems — PHI-aware question templates, BAA-aware build-vs-buy filters, encryption-at-rest defaults baked into the artifact gates. Currently no domain has special-case scaffolding.
- [ ] **Eval mode automation for the new behaviors.** Refresh `evals/evals.json` beyond the partial fix in Task 13 to cover PR 2's new behaviors (session-id JSONL matching, /solution standalone error path, plugin-root LIMITATIONS placement). Today's evals are structural smoke tests; the new behaviors need at least one positive and one negative case each.
- [ ] **Migration tooling for existing `docs/discovery/` artifacts to `docs/socrates/discover/`.** PR 1 changed the artifact path convention. Operators with existing `docs/discovery/<slug>/` directories from earlier sessions have no automated way to migrate. Build a small `socrates migrate` script when the install base is large enough to matter.

## Post-Socratic-rework follow-ups (2026-05-19)

The Socratic rework (spec: `docs/superpowers/specs/2026-05-19-discover-pure-socratic-design.md`) deferred:

- [ ] **Fresh end-to-end smoke test under the new `/discover`.** The PR2 smoke test is now superseded. Run the three test cases from `evals.json` (vague, over-specified, self-aporia) and capture results in `evals/reports/2026-05-19-discover-socratic-smoke-test.md`.
- [ ] **Deeper Socratic alignment of `/solution`.** Today `/solution` uses Tech-D classification and Tech-B 4-option enumeration as its primary tools — those are the same constructs we stripped from `/discover` for being non-Socratic. A follow-up could apply Maieutic / Reductio / Parallel-case patterns to shape decisions in `/solution` as well. Scoped as a separate spec.
- [ ] **LLM-grader for shape-language detection.** The Socratic eval has a `framing_must_not_contain_shape_language` artifact check that currently relies on a heuristic word list. An LLM grader would catch shape-language phrased in non-obvious ways (e.g., "a system that does X via Y" where Y is a shape).
- [ ] **Migration tooling for in-progress legacy WIPs.** `/discover resume <slug>` currently asks the operator to choose abandon-or-extract-and-ship for legacy WIPs. A small `socrates migrate-wip <slug>` could automate the extract path (read Framing + Outcomes from the WIP's existing ledger entries, write the new minimal artifact).
