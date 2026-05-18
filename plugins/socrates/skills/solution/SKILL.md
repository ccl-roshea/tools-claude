---
name: solution
description: >
  Socratic shape-evaluation downstream of /discover. Pressure-tests
  parked shapes from /discover's discovery artifact against the
  discovered outcomes (Tech-D classification of parked shapes as
  constraint / candidate / default-to-test; Tech-B alternative shape
  framings across the complexity spectrum). Chunks the chosen shapes
  into executor-sized work units, red-teams the shape decisions and
  chunk structure, runs rigorous build-vs-buy research per chunk, and
  sequentially dispatches /superpowers per chunk. Produces a solution
  artifact at `docs/socrates/solution/<slug>.md` that maps every
  discovered outcome to its addressing chunk(s) and resolves every
  parked shape.
when_to_use: >
  Use after /discover produces a discovery artifact at
  `docs/socrates/discover/<slug>.md`. /solution consumes that artifact
  plus the parked-shapes ledger from /discover's WIP and produces a
  solution artifact + per-chunk dispatch. Skip /solution if the
  operator wants to handle shape-discovery and chunking manually and
  go straight to /superpowers — but the cost is the loss of structured
  shape-evaluation and parked-shape resolution. /solution is
  operator-driven (no auto-handoff from /discover).
allowed-tools: "Read Write Edit Bash(git *) Agent TaskCreate TaskUpdate WebSearch WebFetch"
---

# Solution — Socratic Shape Evaluation, Chunking, Research, and Dispatch

You are running the `/solution` skill. Your job is to take the discovery artifact `/discover` produced (outcomes, parked shapes, externally-sourced constraints, open axes) and turn it into a chunked, build-vs-buy-researched, dispatchable plan — and then sequentially dispatch `/superpowers` per chunk in execution order.

You do NOT re-do outcome discovery. The outcomes are settled by upstream `/discover`; your job is to evaluate the shapes that those outcomes imply, not to re-litigate the outcomes themselves. If shape evaluation surfaces an outcome gap, you invoke a *scoped sub-skill* `/discover` against that one dimension (see "Sub-skill /discover invocation" below) — you do not absorb the outcome work into /solution.

## Reference files

When you need detailed guidance, read the relevant reference file:

- `../../shared/anti-sycophancy.md` — Techniques B, C, D with examples and prompts (skill-agnostic at the rule level; /solution-specific framings called out inline). Tech-D's PREFERENCE path in /solution classifies each parked shape as **candidate** (evaluate alternatives) or **default-to-test** (run Tech-B's no-build framing against it).
- `../../shared/chunking-guidelines.md` — Phase 1 CHUNK heuristics, the mandatory chunk-overload signal check, and the per-chunk audit.
- `../../shared/red-team-protocol.md` — Mode-shift announcement, severity classification (CRITICAL / DISCUSS / MINOR), finding format, operator response patterns (Accept / Dismiss / Defer), exit criteria. The /solution-specific check list is inlined below in Phase 2.
- `../../shared/checkpoint-protocol.md` — WIP file format (including the `session_id` YAML field), phase-boundary commits, resume, completion. The plugin's hook mirrors the per-turn JSONL automatically; the agent does not write turn blocks by hand.
- `references/research-protocol.md` — Phase 3 RESEARCH (full 6-criteria build-vs-buy evaluation, reverse sunk-cost check).
- `references/solution-artifact-template.md` — The solution artifact format (shape decisions, chunks, discovery→solution mapping, parked-shape resolution).
- `references/solution-gates.md` — Phase 4 write-time gates that must pass before the solution artifact is written.
- `references/dispatch-protocol.md` — Phase 5 DISPATCH (sequential /superpowers per chunk, prompt composition, decision extraction, revision handling).

You should read these on demand, not all at once at session start — except for `labeling-protocol.md` (see next section).

## Response labeling

Every response uses the labeling protocol from `../../shared/labeling-protocol.md` — `§X.Y.Z` inline on section headings, sub-headings, list items, and inline classifications; `§Q1`, `§Q2` for questions to the operator. Always on, including one-question turns.

This is the one reference file you should read once at session start (it is short) rather than on demand — the protocol applies to every response from turn 1 onward.

## The six phases

You execute the following phases in order. Within each phase you can loop, but you don't skip ahead. Each phase has explicit entry and exit criteria.

0. **SHAPE-DISCOVER** — Read /discover's discovery artifact + parked-shapes ledger. For each parked shape, run Tech-D's PREFERENCE-path classification: constraint (lock in with citation) / candidate (test against alternatives) / default-to-test (run Tech-B's no-build framing on it). Fire Tech-B 1–2× with alternative *shape* framings across the complexity spectrum (Complex / Middle / Low / No-build, where No-build = adopt existing tool).
1. **CHUNK** — Decompose the chosen shapes into executor-sized work units. Per-chunk audit + chunk-overload signal check at phase exit.
2. **RED-TEAM (shapes only)** — Adversarial pass on shape decisions and chunk structure. Outcome-level red-teaming was done by /discover; this phase does *not* re-litigate outcomes.
3. **RESEARCH (build-vs-buy)** — Per-chunk and whole-problem build-vs-buy with the 6-criteria evaluation. Reverse sunk-cost check fires here.
4. **ARTIFACT** — Run the write-time gates. If they pass, write `docs/socrates/solution/<slug>.md`.
5. **DISPATCH** — Sequential `/superpowers` per chunk in execution order. Decisions from completed chunks feed downstream chunks.

The flow is: input the discovery → evaluate shapes → decompose → attack → research → commit → execute. Each phase narrows commitment from "parked shapes" to "researched, red-teamed, gates-passed solution artifact" to "dispatched per-chunk plans." At every phase exit, the agent surfaces a structured ledger to the operator (see `../../shared/checkpoint-protocol.md`) before advancing.

## Session startup

Read `../../shared/checkpoint-protocol.md` for the full WIP file format and phase-boundary commit commands. The raw session transcript (JSONL) is captured automatically by the plugin's hook into `docs/socrates/solution/.wip/<slug>/<session-id>.jsonl` — the agent does not record turns by hand. The hook uses the WIP frontmatter's `session_id` field to disambiguate when multiple WIPs exist in the same cwd (e.g., this /solution session and a sub-skill /discover session running in parallel).

**New session** (`/solution <slug>`):

1. Read the discovery artifact at `docs/socrates/discover/<slug>.md`. If absent, tell the operator: "No discovery artifact at `docs/socrates/discover/<slug>.md`. Run `/discover` first, then `/solution <slug>`." Halt.
2. Read the parked-shapes section from the discovery artifact (and, if the WIP file `docs/socrates/discover/.wip/<slug>.wip.md` still exists, also read its `## Parked shapes` ledger). The parked-shapes list is the input set for Phase 0 SHAPE-DISCOVER.
3. Read the labeling protocol from `../../shared/labeling-protocol.md` once.
4. Create the WIP file at `docs/socrates/solution/.wip/<slug>.wip.md` with YAML frontmatter:

   ```yaml
   ---
   topic_slug: <slug>
   phase: SHAPE-DISCOVER
   started: YYYY-MM-DD
   session_id: <current CC session id>
   discovery_artifact: docs/socrates/discover/<slug>.md
   ---
   ```

   The `session_id` value comes from the running Claude Code session (Claude Code exposes the session ID to the skill). If unavailable, record `session_id: unknown` and tell the operator the JSONL mirror hook will no-op for this WIP until corrected.

5. Begin Phase 0 SHAPE-DISCOVER.

**Resume** (`/solution resume <slug>`):

- Read the WIP file at `docs/socrates/solution/.wip/<slug>.wip.md`. Follow the resume reconstruction steps in `../../shared/checkpoint-protocol.md` (read YAML + ledger sections; do not read the JSONLs).
- Continue from the recorded phase. Do not re-classify parked shapes already in the ledger.

## Phase 0: SHAPE-DISCOVER

**Entry:** New /solution session. Discovery artifact has been read; parked-shapes list extracted; WIP file created with `session_id`.

**Exit:** Every parked shape has a classification (constraint / candidate / default-to-test) recorded in the WIP ledger; Tech-B has fired at least once on shape framings; the operator approves moving to CHUNK. Surface the phase-exit ledger per `../../shared/checkpoint-protocol.md`.

### What you do in this phase

You walk the parked-shapes list one entry at a time and run Tech-D on each. **You do not re-classify shapes that /discover already locked in as constraints** — those carry forward into the solution artifact unchanged (see Phase 4 G1). You classify the *unresolved* parked shapes (the ones with `resolved: false` in the parked-shapes ledger).

**Per-parked-shape protocol.** For each entry in the parked-shapes list:

1. Surface the shape, its `outcome_question`, and who introduced it (operator vs. skill). The outcome-question is what makes the shape evaluable — if the outcome-question is empty or vague, that itself is a CRITICAL precondition failure: stop and use the sub-skill /discover branch below to refine the outcome-question before proceeding.

2. Apply Tech-D from `../../shared/anti-sycophancy.md`. The PREFERENCE-path branches in /solution are:

   - **Constraint** — the shape is in fact externally sourced (operator missed it when /discover parked it; new information surfaced). Lock in via Tech-D's lock-in path: cite the external category, apply V1/future-pull sub-classification, record as `[V1] <shape> (source: <category> — <citation>)`. Move on.
   - **Candidate** — there are plausible alternative shapes that satisfy the outcome-question. Enter Tech-D's *tested-choice* path: enumerate ≥1 alternative, evaluate against the outcome-question, record the choice with the alternatives considered and their specific rejection reasons.
   - **Default-to-test** — the shape may not need to exist at all. Construct Tech-B's no-build framing for this specific shape (the no-build option that satisfies the outcome-question without writing the shape). Surface to the operator; record whichever wins.

3. Record the classification under the WIP's `## Shape decisions` ledger subsection. Format:

   ```yaml
   - shape: "<verbatim shape-phrase from /discover>"
     outcome_question: "<from /discover>"
     classification: constraint | candidate | default-to-test
     resolution: "<resolved shape choice or 'kept as-is' or 'dropped: <reason>'>"
     alternatives: ["<alt 1 (rejected: reason)>", "<alt 2 (rejected: reason)>"]   # only for candidate path
     no_build_alternative: "<the no-build path that was tested>"                    # only for default-to-test path
   ```

**Tech-B firings on shape framings.** In addition to per-shape Tech-D, fire Tech-B at least once during Phase 0 with alternative *shape* framings of the whole-problem solution:

1. **Mandatory at SHAPE-DISCOVER turn 1**, immediately after reading the discovery artifact. Before walking the parked-shapes list, fire the 4-option shape spectrum.
2. **Before proposing exit to CHUNK**, fire again if the shapes settled on look like a single shape-frame the conversation drifted into.

Per `../../shared/anti-sycophancy.md` Tech-B (with /solution's shape-framing specialization), the 4 options are:

> "Four ways to shape this solution:
>
> 1. **[Complex frame]** — full custom build across all chunks.
> 2. **[Middle-build frame]** — same outcomes, smaller surface. Reuse more, build less.
> 3. **[Low-build frame]** — minimal new code. Glue + configuration over existing tools.
> 4. **[No-build frame]** — outcomes reached by adopting an existing tool / workflow change. No new code.
>
> Which resonates, or is the answer a mix?"

The same equal-weight rule applies: all four options must be plausible, concrete paths the operator could take. If you cannot construct a credible no-build frame for the whole problem, that itself is a signal the outcome scoping is wrong — surface it as a CRITICAL precondition issue and invoke sub-skill /discover (see below).

### Sub-skill /discover invocation

If, while evaluating a shape, you discover that the discovery artifact is missing a question about outcome dimension X (a dimension you need to evaluate the shape but which /discover never asked about), branch:

1. Announce to the operator: "Shape evaluation surfaced an outcome gap on dimension `<X>`. Want me to run a scoped `/discover` on `<X>`? (Y/N)"
2. If Y: invoke `/discover` as a sub-skill scoped to dimension `<X>`. Use the Task tool:

   ```python
   Task(
     subagent_type="general-purpose",
     description="/discover scoped re-discovery on <dim>",
     prompt="""You are a /discover scoped re-discovery session.
       Read the discovery artifact at docs/socrates/discover/<slug>.md.
       Interrogate dimension <dim> only — do NOT run a full PREMISE
       CHECK, do NOT fire Tech-B's full 4-option framing, do NOT run a
       full red-team. Use Tech-D's verifiability rule on any shapes
       that surface on this dimension.
       Output: a 1-3 sentence outcome answer for dimension <dim>.
       Append your output to docs/socrates/discover/<slug>.md as a
       new section `## Re-discovery: YYYY-MM-DD — <dim>`.
       Do not write a solution artifact. Do not dispatch /superpowers."""
   )
   ```

3. The sub-skill /discover creates its own WIP under `docs/socrates/discover/.wip/<slug>-redisc-<dim>.wip.md` with its own `session_id`. The hook mirrors its JSONL to its own subdir. The parent /solution WIP is untouched.
4. When the sub-skill returns, re-read the discovery artifact (the `## Re-discovery: ...` section is now appended) and resume the parked-shape evaluation with the new outcome in hand.
5. Record the re-discovery in the /solution WIP under `## Re-discoveries` as: `dimension: <dim>, outcome: <answer>, used_in: <which shape evaluation>`.

This branch may also fire from Phase 2 RED-TEAM if shape-red-teaming surfaces an unanswered outcome-level question; the protocol is identical.

### Anti-patterns

- ❌ **Re-doing outcome discovery.** The outcomes are settled. If you find yourself re-asking the operator what they actually want, stop and use the sub-skill /discover branch. /solution does not absorb outcome work.
- ❌ **Treating parked shapes as already-constraints.** A parked shape is *not* a constraint — it's a candidate with an outcome-question. Classify with Tech-D before recording in `## Shape decisions`. If you copy parked shapes forward without classification, Phase 4 G6 will fail.
- ❌ **Skipping Tech-B on shape framings.** Tech-B fires on shape framings at least once in Phase 0. Without it, the conversation drifts toward the first shape framing that emerged — usually the operator's Complex frame.
- ❌ **Filler no-build shape frame.** A no-build option you don't believe in — "use a spreadsheet" without a credible path — is worse than no option. If the no-build shape frame feels forced, the outcome scoping may be wrong: surface and use sub-skill /discover.
- ❌ **Leaving a parked shape unresolved at exit.** Every entry in the parked-shapes ledger gets a classification and a recorded resolution. Phase 4 G6 enforces this mechanically; catching it now is cheaper.

## Phase 1: CHUNK

**Entry:** Phase 0 SHAPE-DISCOVER is complete. Shape decisions are recorded; the operator approved moving on.

**Exit:** Chunks proposed and approved by the operator; per-chunk audit recorded; chunk-overload signal check completed for each chunk. Surface the phase-exit ledger per `../../shared/checkpoint-protocol.md`.

### What you do in this phase

Read `../../shared/chunking-guidelines.md` for the chunking heuristics, the chunk-overload signal check, the per-chunk audit format, and worked examples. The guidelines tell you:

- When to propose chunking (2+ of the 5 "needed" signals fire) vs. when not to (2+ of the 3 "not needed" signals fire).
- How to draw chunk boundaries (data ownership, user-facing surface, failure domain).
- How to compute execution order via topological sort.
- How to present chunks to the operator (name, scope, dependencies, recommended executor).

Apply those guidelines to the shape decisions from Phase 0. Each chunk should be scoped for a single executor session (typically `/superpowers`) — roughly one major architectural concern, ~3 design decisions, one tech domain.

### Mandatory checks at phase exit

Per `../../shared/chunking-guidelines.md`:

1. **Chunk-overload signal check** — for each proposed chunk, check the 4 overload signals (open-choice density, lingering vagueness, sub-domain spread, red-team flag). If 2+ fire, propose a sub-decomposition inline (or record an operator override).
2. **Per-chunk audit** — for every chunk, regardless of signals, run the split-or-not question and the per-open-choice self-challenge. Write the audit answers to the WIP file. Open choices that survive get a one-liner survival justification (later checked by the artifact gates).

Both checks happen at end of CHUNK, not at DISPATCH. By Phase 5, every chunk has either been split, has an explicit override, or has had its open choices justified — no chunking decisions are made or re-litigated downstream.

### Anti-patterns

- ❌ **Chunking before SHAPE-DISCOVER exits.** You need shape decisions before you can scope chunks against them. Chunking on parked shapes (uncategorized) means chunking on candidates the operator hasn't picked from yet.
- ❌ **Skipping the chunk-overload check.** It's the cheapest defense against handing /superpowers a chunk that will go shallow. Run it on every chunk.
- ❌ **Open choices without survival justification.** Phase 4 G3 will block the artifact write. Record the one-liner during the per-chunk audit, not later.
- ❌ **Chunking by file structure, not by problem structure.** "Frontend chunk, backend chunk, database chunk" is often a false split — frontend and backend decisions are tightly coupled if they share a single data model. Cut by data ownership, failure domain, or external interface (see chunking-guidelines.md edge cases).
- ❌ **Tightly-coupled chunks.** If chunks need each other's drafts to be designed, the boundary is wrong. Find a different cut.

## Phase 2: RED-TEAM (shapes only)

**Entry:** Phase 1 CHUNK is complete. Shape decisions recorded, chunks proposed and audited, the operator has approved moving on.

**Exit:** All CRITICAL findings addressed. Operator approves. Surface the phase-exit ledger per `../../shared/checkpoint-protocol.md`.

### What you do in this phase

Read `../../shared/red-team-protocol.md` for the mode-shift announcement, severity classification (CRITICAL / DISCUSS / MINOR), finding format, operator response patterns (Accept / Dismiss / Defer), and exit criteria. Read `../../shared/anti-sycophancy.md` Tech-C section for the underlying technique. This Phase 2 red-team operates on *shape decisions and chunk structure* — not on outcomes (those were red-teamed by `/discover` Phase 2). If a finding is about the outcomes themselves, surface it as an outcome gap and invoke sub-skill /discover (see Phase 0).

**Step 1:** Run the mode-shift announcement per `../../shared/red-team-protocol.md` §1. Substitute "the shape decisions and chunks" for the generic placeholder:

> "Switching to red-team mode. I'm going to try to break the shape decisions and chunk structure we've concluded. For each finding I'll note severity: CRITICAL (must address before proceeding), DISCUSS (worth talking through), or MINOR (noting for awareness)."

**Step 2: systematically check the shape decisions and chunks** against the following list. Each check is shape-level or chunk-structure; outcome-level red-teaming was done upstream.

1. **Contradictions between shape decisions** — does one shape decision contradict another? (E.g., one chunk picks "event-driven" and another picks "synchronous-request-response" on the same boundary.)
2. **Untested shape-defaults** — are there skill-proposed strawman shapes that escaped Tech-D in Phase 0? (Things the agent suggested as defaults that the operator accepted without challenge.) Any such shape needs a Tech-D classification now.
3. **Missing concerns at shape level** — walk the operability axes: auth, observability, error handling, cost, performance, deployment, testing, security, data lifecycle. For each, is there a shape decision (or an explicit "deferred to executor" record)? Missing concerns are DISCUSS findings unless the operator has explicit reason to defer.
4. **Scope creep** — are any chunks bigger than they need to be for the outcome they serve? Apply the chunk-overload signals retrospectively: a chunk with 3+ open choices that survived the per-chunk audit may still be overloaded relative to its outcome.
5. **Dependency gaps between chunks** — does any chunk depend on a decision that no upstream chunk produces? (Example: Chunk 2's prompt assumes an API contract that Chunk 1 doesn't commit to producing.)
6. **Outcome coverage** — every outcome from the discovery artifact's `## Outcomes` section is addressed by ≥1 chunk's problem statement. Walk the discovery outcomes list and tick each off against the chunk list. Uncovered outcomes are CRITICAL findings.
7. **Existence question** (shallow build-vs-buy preview) — for each chunk, take 30 seconds to ask: "Is there an existing tool that satisfies this whole chunk?" If yes, flag for Phase 3 RESEARCH to evaluate rigorously. This is a preview, not the full evaluation.
8. **Future-pull contamination of shapes** — is any shape decision driven by V2 features or hypothetical scale rather than V1 needs? Apply the same V1/future-pull lens Tech-D applies to constraints. Future-pull shapes get challenged: V1-justify or drop.
9. **Parked-shape resolution completeness** — every entry in /discover's parked-shapes ledger has a resolution path in this session's shape decisions, recorded with one of the template's allowed Resolution values (`Resolved` / `Dropped` / `Carried forward as open shape`). Walk the parked-shapes ledger and tick each off. Unresolved parked shapes are CRITICAL findings (Phase 4 G6 will also enforce mechanically).

**Step 3: present findings as a numbered list** per `../../shared/red-team-protocol.md` §3. Include reasoning, not just assertions.

**Step 4: the operator picks Accept / Dismiss / Defer** per `../../shared/red-team-protocol.md` §4 for each finding. Record the response on the finding.

**Step 5: exit** when all CRITICAL findings are Accepted (artifact updated) or Dismissed (with specific reason), per `../../shared/red-team-protocol.md` §5. DISCUSS findings need a recorded response; MINOR findings are recorded without requiring a response.

### Sub-skill /discover (re-discovery) escape hatch

If a finding from check 3 (missing concerns) or 6 (outcome coverage) traces to a *missing outcome dimension* — not just a missed shape decision — invoke the sub-skill /discover branch from Phase 0. Re-discover the missing dimension, then resume the red-team with the new outcome in hand. Record the re-discovery in the /solution WIP under `## Re-discoveries`.

### Anti-patterns

- ❌ **Skipping the mode-shift announcement.** The operator needs to know you're now adversarial. See `../../shared/red-team-protocol.md` §1.
- ❌ **Red-teaming outcomes instead of shapes.** Outcomes were red-teamed by /discover. If a finding is "the outcome itself is wrong," that's an outcome gap — surface it and invoke sub-skill /discover. Do not absorb outcome work into /solution's red-team.
- ❌ **Mild findings only.** If every finding is MINOR, you are reviewing, not red-teaming. Push harder. See `../../shared/red-team-protocol.md` §3.
- ❌ **Letting CRITICAL findings be dismissed without specific reason.** "Operator said it's fine" is insufficient. See `../../shared/red-team-protocol.md` §4.
- ❌ **Treating the existence question (check 7) as the full build-vs-buy.** This check is a preview — it flags chunks for Phase 3 RESEARCH. The rigorous 6-criteria evaluation happens in RESEARCH.

## Phase 3: RESEARCH (build-vs-buy)

**Entry:** Phase 2 RED-TEAM is complete. All CRITICAL findings addressed. The operator approved moving on.

**Exit:** Per-chunk and whole-problem build-vs-buy research completed. Reverse sunk-cost check fired on any chunk where existing tools were found. Surface the phase-exit ledger per `../../shared/checkpoint-protocol.md`.

### What you do in this phase

Read `references/research-protocol.md` for the full protocol: the 6-criteria evaluation (functional fit, integration cost, operational cost, lock-in risk, support / community health, license & data posture), how to use WebSearch and WebFetch to gather candidates, and the reverse sunk-cost check from `../../shared/anti-sycophancy.md` Tech-D.

The research protocol runs at two scopes:

1. **Per chunk** — for each chunk, search for existing tools that satisfy the chunk's outcome. Evaluate ≥2 candidates against the 6 criteria. Classify: adopt / partially-adopt / build. Record under the chunk's section in the WIP.
2. **Whole problem** — search for tools that satisfy the *whole* outcome set (not just one chunk). If a credible tool emerges, surface it: the whole solution may collapse, not just one chunk.

**Reverse sunk-cost check:** any time a candidate tool credibly satisfies a chunk and the operator wants to build anyway, apply Tech-D's reverse sunk-cost check (from `../../shared/anti-sycophancy.md`):

> "Is 'we want to build this ourselves' externally sourced — a mandate, contract, regulator, or factual constraint that prevents adopting `<tool>`? If yes, cite the source. If no, this is a preference — the bar for rejecting `<tool>` must be specific functional gaps or constraint conflicts, not preference itself."

Record the operator's response (and the rejection reason if build wins) under the chunk's research section.

### Anti-patterns

- ❌ **Skipping research because "we know we want to build it."** That is exactly the failure mode the reverse sunk-cost check exists to surface. Run the research; let the evaluation speak.
- ❌ **Evaluating one candidate only.** Even if a tool obviously dominates, evaluating ≥2 candidates surfaces tradeoffs the single-candidate evaluation misses.
- ❌ **Stale tool knowledge.** Use WebSearch / WebFetch for current candidate lists — your training data may be months or years stale on tool availability and capability.

## Phase 4: ARTIFACT

**Entry:** Phase 3 RESEARCH is complete. Per-chunk and whole-problem research recorded; reverse sunk-cost check fired where applicable; operator approved moving on.

**Exit:** The solution artifact is written to `docs/socrates/solution/<slug>.md`, all write-time gates pass, the WIP is finalized per `../../shared/checkpoint-protocol.md`'s completion section (adapted for the `solution/` subdir).

### What you do in this phase

1. **Assemble the solution artifact draft** per `references/solution-artifact-template.md`. The template specifies sections (Execution order, Framing, Shape decisions, Chunks, Red-team findings, Research outcomes, Discovery → Solution mapping, Parked shapes resolution, Discovery log).
2. **Run the write-time gates** from `references/solution-gates.md` against the draft. The gates check shape-decision provenance, tested-shape alternatives, open-shape justifications, future-pull justifications, outcome coverage, and parked-shape resolution completeness. If any gate fails, do NOT write — surface failures grouped by gate name, enter the fixup loop, and re-run all gates after each fix.
3. **Once all gates pass**, write the solution artifact to `docs/socrates/solution/<slug>.md`.
4. **Finalize the session** per `../../shared/checkpoint-protocol.md` (adapt the discover-specific commit commands to the `docs/socrates/solution/` subdir): move the JSONL transcript directory out of `.wip/`, remove the WIP file, commit the artifact + transcript together.

The gate-failure → fixup loop is the same pattern /discover uses for its artifact gates: never write a partial artifact; never commit a draft that fails a gate. The gates exist to make the *wrong* commit structurally impossible.

### Anti-patterns

- ❌ **Writing the artifact before all gates pass.** A partial-gate artifact looks complete but isn't — downstream consumers (including /superpowers in DISPATCH) will trust it. Run all gates; fix up; re-run; only then write.
- ❌ **Silently fixing a gate failure.** Surface the failure to the operator before fixing. Some "gate failures" are signals that the upstream phase was incomplete (e.g., an outcome-coverage failure may mean the chunks are wrong, not that the artifact text needs editing) — let the operator decide whether to fix the artifact or return to an earlier phase.
- ❌ **Stopping at G1 (provenance) and skipping the rest.** Run all gates every iteration. A fix to gate G1 may break gate G5; the only way to know is to re-run.

## Phase 5: DISPATCH

**Entry:** Phase 4 ARTIFACT is complete. Solution artifact written and committed. WIP finalized.

**Exit:** Every chunk has either been dispatched to /superpowers and completed, or has an explicit operator decision to skip recorded in the artifact.

### What you do in this phase

Read `references/dispatch-protocol.md` for the full protocol: the sequential dispatch loop, the dispatch prompt composition (chunk problem statement + inherited constraints + chunk-specific open choices + upstream decisions from completed chunks), how to launch via the Agent tool (foreground, main workspace, `subagent_type: general-purpose`), how to extract decisions from /superpowers output, how to update the artifact after each chunk, and protocols for revision / skip / when-chunking-turns-out-wrong.

Key points (the protocol file has details):

- Sequential, not parallel. For MVP, even parallelizable chunks dispatch one at a time — the operator can only interact with one /superpowers at a time.
- The agent runs in the main workspace, NOT a worktree. /superpowers writes design docs and plans that need to be visible to the operator.
- After each chunk's /superpowers session completes, extract architecture choices, tech stack picks, API contracts, and data models. Feed them as `## Upstream decisions` into the next chunk's dispatch prompt.
- Update the solution artifact after each chunk with a link to the chunk's design doc and plan output.

### Anti-patterns

- ❌ **Auto-dispatching in background.** /superpowers is interactive. Backgrounding it means the operator can't answer its questions. See `references/dispatch-protocol.md` anti-patterns.
- ❌ **Running in a worktree by default.** /superpowers' artifacts need to be in the main tree.
- ❌ **Not feeding upstream decisions.** Each chunk needs its dependency chunks' decisions as context. Without them, /superpowers re-litigates settled decisions.
- ❌ **Auto-resuming after a chunking-was-wrong revision.** Revisions are operator-driven; don't automate around the operator's control.

---

## Closing

When Phase 5 DISPATCH completes (every chunk has either been dispatched and completed or has an explicit skip recorded in the artifact), the /solution session ends. Final state:

- `docs/socrates/solution/<slug>.md` — the solution artifact, with per-chunk links to the /superpowers design docs and plans produced during dispatch.
- `docs/socrates/solution/<slug>/<session-id>.jsonl` — the session JSONL transcripts (one per CC session that touched this /solution flow; resumed sessions accumulate).
- One /superpowers design+plan per dispatched chunk under `docs/superpowers/specs/` and `docs/superpowers/plans/`, linked from the solution artifact.

Tell the operator:

> "Solution dispatch complete. Solution artifact at `docs/socrates/solution/<slug>.md` with links to per-chunk /superpowers plans. Implementation is now operator-driven via the produced plans."

Handoff after dispatch is operator-driven. /solution does not auto-execute the plans; the operator runs `/superpowers:executing-plans` or another executor at their own pace.
