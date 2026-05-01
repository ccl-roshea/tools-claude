# Known Limitations

These are real gaps in the current `/discover` skill, observed during the validation runs. None blocks MVP usefulness; all are candidates for future iteration. Recorded here so future readers (and future iterations of the skill) can see what was known at ship time.

## 1. Strawman defaults bypass anti-sycophancy

**Observed:** Path B Test 1 (2026-05-01). When the skill proposes "strawman" defaults for chunk-internal decisions (e.g., Bicep as IaC default, GitHub Actions as CI/CD), it doesn't apply the same constraints-vs-choices rigor (Technique D) that fires on user-introduced specifics. The operator caught Bicep on Turn 22 and pushed back; GitHub Actions slipped through unchallenged.

**Pattern:** Anti-sycophancy *triggers* don't fire reliably on decisions the skill itself proposes when those decisions look "low-stakes" or "default-y." The skill defends well against the user's untested assumptions but not against its own.

**Hypothesis for fix (iteration 3):** When the skill proposes a strawman, frame it explicitly as "I'm proposing X as a default — should I run Technique D on this, or is it good enough for the MVP?" Make the strawman itself subject to the same machinery.

## 2. Soft signals under-fire on long sessions

**Observed:** Iteration 1 Eval 1 ran 40 turns; iteration 2 ran 29 turns. The "10+ turns since a new theme emerged" soft signal didn't fire as aggressively as the spec implies it should. The skill keeps asking sequentially when it could propose moving on.

**Hypothesis for fix:** Make the soft-signal *check* explicit — every N turns, the skill states out loud whether the signals are firing and asks the operator if they want to wrap up. Currently the signals are theoretical thresholds; making them visible gives the operator a chance to call it.

## 3. Operator cost is high

**Observed:** Path B Test 1 took 26 turns of dialogue with detailed operator answers, multi-day session, hours of total operator engagement (vs. ~3 minutes for Path A). The skill produces dramatically better discovery output but at significant operator-attention cost.

**Status:** This is a fundamental tradeoff, not necessarily a fixable bug. The bet is that steering at every step is cheaper than rebuilding from a wrong frame. Path B's +1.5 Correctness gain at 26 turns vs. 7 implies the bet is correct *for important problems*. For small problems, the operator can reasonably skip /discover and go straight to /superpowers.

**Mitigation:** The description explicitly says "Skip this skill for narrow well-scoped bug fixes, single-function changes, or maintenance tasks." Operators should treat /discover as a tool for *important* problems, not all problems.

## 4. Path B validation is N=1

**Observed:** The MVP shipped after passing Test 1 with a wide margin (+3 Coverage, +1.5 Correctness). Tests 2 and 3 (additional real-problem validation per memo §7) were deferred — see `TODO.md`.

**Status:** Sufficient for personal-use go/no-go. Not sufficient for declaring the skill shippable to a broad audience. If the skill is shared with teammates or other users, run Tests 2 and 3 first.

## 5. Eval mode tests structure, not quality

**Observed:** The skill-creator-driven Phase 3 evals all passed (47/48), but they are structural smoke tests — the "user" is a self-answering subagent, which can't reproduce the sycophancy failure mode the skill is designed to prevent. Real validation comes from human operators (Path B).

**Status:** Known intentionally. The eval cases at `evals/evals.json` are useful for catching structural regressions (does the skill load? do phases transition? does WebSearch fire?) but not for measuring quality. Don't trust an eval pass alone — pair with at least one Path-B-style human run before declaring an iteration good.

## 6. Recursive /discover hasn't been tested end-to-end

**Observed:** Phase 5's chunk-complexity assessment was tested in Path B, and it correctly flagged Chunks 1 and 2 for /discover. The operator declined the recursive run for the validation eval, so the recursion path itself was not exercised. The artifact format for sub-discoveries (`docs/discovery/<parent-slug>/<chunk-slug>.md`) is specified but not yet validated against a real run.

**Status:** Specified, structurally supported, not empirically validated. First real recursive run will likely surface integration issues (e.g., constraint inheritance from parent, where to put upstream decisions, how to handle re-runs after parent revisions). Consider this a "first run will be a bit rough" area.
