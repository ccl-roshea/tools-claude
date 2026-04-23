# Test Cases: Socratic Discovery Tool vs. /superpowers Alone

**Date:** 2026-04-23
**Purpose:** Empirical validation set for the decision memo at `2026-04-23-socratic-discovery-tool-evaluation.md` §7. Three problem statements at varying levels of thoroughness, run through /superpowers alone and through the Socratic discovery tool, then compared.

**Design principle:** the problem prompts below are what gets pasted in verbatim. They do **not** include our hypotheses about what a good tool should surface — listing those inside the prompt would pre-chew the work and invalidate the test. Our hypotheses live in a separate section below the prompts.

---

## Test 1 — High vagueness (product-level, no context)

**Thoroughness level:** low. User has an intent but has not committed to architecture, audience, scale, protocol, or what "agent" even means.

**Prompt (paste verbatim):**

> I want to be able to deploy agents that are available for my entire team and the agents can communicate with each other.

**Why this one:**
- Classic "sounds like an ask, is actually five asks" statement
- Every substantive noun is under-defined: *deploy*, *agents*, *team*, *available*, *communicate*
- No constraints given — scale, latency, security, budget, tech stack all unspecified
- /superpowers-alone will almost certainly pick a plausible interpretation and build it; whether that matches the user's actual need is the whole test

**What we expect a good Socratic pass to surface (do not show to either tool):**
- What is "an agent" — an autonomous LLM loop, a scheduled job, a chat bot, a skill that another user triggers?
- Team scale (3 people vs. 300) and trust model
- Deploy target — local machines, shared server, cloud, hosted service
- "Available for the entire team" — discoverable? invocable? shared state?
- "Communicate with each other" — message passing, shared memory, RPC, shared filesystem, event bus?
- Sync vs. async; persistence of conversation state
- Identity, auth, observability, cost accounting
- Is this internal tooling, a product feature, a research artifact, or a workflow orchestrator?

---

## Test 2 — Medium thoroughness (feature-level, sounds clear but isn't)

**Thoroughness level:** medium. The statement feels actionable but embeds a large number of implicit decisions that will produce very different implementations depending on how they are resolved.

**Prompt (paste verbatim):**

> Add a notification system to our web app that tells users when important things happen. It should work across devices and not be annoying.

**Why this one:**
- Sounds ordinary enough that most tools will just start building
- "Important things" is the central undefined term — the system either needs rules, ML, user config, or some mix
- "Not annoying" is a quality bar without a definition
- Has real architectural consequences (delivery channels, preference surface, storage of read-state, event taxonomy)
- Useful for testing the tool on mid-sized features where the pitfall is *under-examination*, not total vagueness

**What we expect a good Socratic pass to surface:**
- Who defines "important" — product rules, per-user config, admin-editable rules, ML ranking?
- Delivery channels — in-app, email, push, SMS, webhook — and which is primary
- Real-time vs. batched / digest
- Cross-device: sync read-state, or fire-per-device?
- Preference management surface and defaults
- Historical view, expiry, and clearing semantics
- "Not annoying" as a testable criterion — rate-limiting, batching, quiet hours, per-category opt-out?
- Integration shape — does every feature have to wire in, or is there a centralized event emitter?
- Existing system context not stated (auth, user model, mobile presence)

---

## Test 3 — Fairly thorough (technical, already has design shape)

**Thoroughness level:** high. Input/output, constraint, and success metric are all stated. The test is whether the tool can still add value — or whether it just adds friction — when the prompt is already reasonable.

**Prompt (paste verbatim):**

> Refactor our Python data pipeline to process files incrementally instead of batch-loading everything, using the existing S3 input and Postgres output, while preserving idempotency. Target 10× throughput on the `events` table. We're currently using pandas with a nightly cron; we want to move to something that can run continuously.

**Why this one:**
- Looks well-specified: source, sink, constraint, metric, current state, desired state
- But has hidden decisions that determine success:
  - What does "incrementally" actually mean — per-file, per-record, streaming, micro-batch windows?
  - Ordering guarantees
  - Failure semantics in tension with idempotency (at-least-once vs. exactly-once)
  - Backfill and cutover strategy during the migration itself
  - What is the actual current bottleneck — if we don't know, 10× could be unachievable by any architecture change
- Tests whether the tool is valuable on problems that *look* tight but aren't

**What we expect a good Socratic pass to surface:**
- Identifying the current bottleneck (profiling, not guessing) as a prerequisite
- Defining "incremental" operationally with a concrete unit and window
- Idempotency contract — natural keys vs. dedup tables vs. upsert semantics
- Cutover plan and rollback path
- Observability requirements for a continuous pipeline that weren't needed for a cron
- Whether "continuous" means streaming (Kafka-shaped) or frequent polling (CDC-shaped)
- Dev / test environment strategy given S3 + Postgres

---

## Test protocol

For each of the three prompts, run both paths and record outputs side-by-side.

**Path A — /superpowers alone:**
1. Start a fresh session
2. Paste the prompt verbatim
3. Answer any clarifying questions naturally, without volunteering information not asked for
4. Let /superpowers produce a plan
5. Record: final plan, number of operator turns, total operator typing (approx character count), wall-clock time

**Path B — Socratic discovery tool, then /superpowers:**
1. Start a fresh session of the new tool
2. Paste the prompt verbatim
3. Run the Socratic dialogue loop to completion (operator-terminated)
4. Take the resulting artifact into a fresh /superpowers session as the problem statement
5. Let /superpowers produce a plan
6. Record: Socratic artifact, final plan, *total* operator turns across both tools, total operator typing, wall-clock time

**Important:** the operator in both paths must follow the same rule — answer what is asked, do not volunteer information not asked for. This isolates the tool's ability to *elicit* framing from the operator's generosity.

## Scoring rubric

Score each test on four axes, 1–5:

1. **Coverage** — how many of the "expected to surface" items were actually surfaced (not scripted; judged against the list above after both paths finish)
2. **Correctness of frame** — does the resulting plan reflect what the operator *actually* wanted, in retrospect? (Self-judged by operator after both paths are complete; ties broken by which plan the operator would *actually ship*)
3. **Operator cost** — total typing + turns. Lower is better. Normalize across tests before comparing.
4. **Downstream plan quality** — subjective 1–5 rating of the final /superpowers plan's usefulness to a human about to implement

**Pass criterion for go/no-go validation:** in at least 2 of the 3 tests, Path B beats Path A on Coverage (+1 or more) and Correctness of Frame (+1 or more) while not being worse than Path A by more than +1 on Operator Cost. If Path B wins Coverage/Correctness but *also* costs 3× the operator effort, that is not a pass — it means the tool works but is too expensive to use.

## Known limitations of this validation

- **Operator bias.** Same person runs both paths, knows the "expected" list, may unconsciously cue answers. Mitigation: run all Path A first for all three tests before running any Path B, so memory of the tool's influence is minimal.
- **Single operator.** Real tools get used by different people; one operator's results don't generalize. Fine for go/no-go, not fine for declaring the tool shippable to others.
- **Plan-quality judgment is subjective.** Accept this; the validation is an argument-closer, not a paper.
- **The tool doesn't exist yet.** Path B will be run against an MVP, not a mature product. Early results should be generous on polish, strict on whether the Socratic *mechanism* produces better framing.

## Next step

Run Path A for all three tests first, with results captured in a follow-up doc (`2026-04-23-socratic-test-results-path-a.md`). Path B waits on the MVP being built.
