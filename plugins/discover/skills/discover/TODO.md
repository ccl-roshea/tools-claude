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

- [ ] **Strawman challenge.** Make strawman defaults the skill proposes subject to the same Technique D classification as user-introduced specifics. Pattern observed in Path B: Bicep / GitHub Actions slipped through unchallenged.
- [ ] **Visible soft signals.** Make the "should we move on?" check explicit every N turns so the operator can see when it's firing.
- [ ] **Recursive /discover end-to-end test.** First real recursive run will surface integration issues; do this when the next genuinely-multi-chunk problem comes up.

## Future capability (deferred per spec)

- [ ] **Per-node executor dispatch.** The original spec named this as the most differentiating long-term feature. Currently the artifact recommends an executor per chunk as a human-readable annotation; there's no automated routing. Build when there are multiple specialist executors worth dispatching to.
- [ ] **Parallel dispatch.** Currently chunks run sequentially even when independent. Worth building when operator can context-switch between multiple in-flight /superpowers sessions, OR when /superpowers can run autonomously enough to not need HITL per turn.
- [x] **Cross-session resume.** ~~Currently a session that hits its budget and stops loses state.~~ Resolved by the JSONL-mirror hook: each Claude Code session that touches a discovery now writes its own `<session-id>.jsonl` into `docs/discovery/.wip/<slug>/`, and the WIP file's ledger entries provide the structured resume context. `/discover resume <slug>` reads the ledgers and continues; the new session's JSONL accumulates alongside the prior ones.
