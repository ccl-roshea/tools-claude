# Evaluation Report: `ai-task-guardrails-framework` discover session

**Session:** 2026-05-12 → 2026-05-14 (3-day calendar span; ~6–7 active operator hours)
**Operator:** roshea@caracalcorp.com
**Topic:** SOC2-grade AI-assisted PM framework for IT-ops team (1 CTO + 3 juniors)
**Transcript:** `~/repos/agent-pm/docs/discovery/ai-task-guardrails-framework/89475c08-3194-4d54-abdb-0c08dcac76f9.jsonl` (630 records, 1.9 MB)
**Artifact:** `~/repos/agent-pm/docs/discovery/ai-task-guardrails-framework.md` (376 lines, committed at `2438f9b`)
**Auditor:** Claude Opus 4.7, methodology v1 from `evals/methodology.md`
**Audit date:** 2026-05-15

## TL;DR scorecard

| # | Dimension | Grade | Headline |
|---|-----------|-------|----------|
| D1 | Phase execution and ordering | **B** | All phases executed but Phase 3.5 (RESEARCH) ran inside Phase 1 (DISCOVER), violating spec ordering |
| D2 | Artifact-time gates 1–4 | **B** | Gates 1 + 3 mechanically clean; Gate 2 has 1 violation; no transcript evidence the gates were explicitly run |
| D3 | Anti-sycophancy: Tech-D firing | **C** | Operator-introduced specifics ~93% classified; **9 skill-introduced strawmans escaped Tech-D entirely**; V1/future-pull sub-classification protocol never explicitly fired |
| D4 | Anti-sycophancy: Tech-B framings | **A** | Mandatory turn-1 firing executed verbatim; both invocations had credible no-build options; agent suppressed a third firing with defensible reasoning |
| D5 | Research rigor (Phase 3.5) | **B+** | All 6 criteria covered for 7 deeply-evaluated candidates; real pricing pages fetched; reverse sunk-cost protocol-phrasing never fired verbatim; ~75 min research vs. 30-min budget |
| D6 | Chunk decomposition quality | **C** | Per-chunk audit + chunk-overload check **never re-ran on the trimmed 4-chunk plan**; Chunks 2 and 4 trip ≥2 overload signals each with no in-line sub-decomposition or override on record |
| D7 | Operator load and friction | **C** | 31 typed turns (1.19× Path B baseline); **35% correction ratio**; zero agent-driven "propose moving on" prompts; the headline V1-trim pivot was operator-driven |

**Composite:** B/C average. The session produced a high-quality artifact, but the discipline that produced it was largely operator-driven, not skill-driven. The most important finding: **two of the three failure modes the authors flagged in `LIMITATIONS.md` (§1 strawman bypass, §2 soft-signal under-fire) reproduced cleanly in this session**.

## Pre-audit hypothesis check

The auditor's pre-audit read produced these hypotheses (recorded in the plan file). Audit results below.

| Hypothesis | Result |
|------------|--------|
| Phase 0 may have been weak (no premise check in collapsed log) | **Refuted.** Phase 0 was strong — outcome restated correctly at L104, three concrete no-build paths offered, operator ruled out paths 1 + 2 with reasons. The log just elides it. |
| Session length is high → soft-signal under-fire (LIMITATIONS §2) | **Confirmed.** Zero "propose moving on" prompts in the entire transcript. Operator carried the L587 pivot themselves. |
| Strawman defaults bypass anti-sycophancy (LIMITATIONS §1) | **Confirmed strongly.** Nine skill-introduced specifics in the trimmed-V1 sketch escaped Tech-D classification entirely. |
| Substrate sweep is uneven in depth (Foam/Logseq one-sentence rejects) | **Mostly confirmed.** Light rejections piggy-backed on operator's pre-existing overlay-research file; Tasks.md and git-bug listed as "evaluated" with no rejection reason recorded anywhere. |
| Phase 5 (DISPATCH) never executed | **Refuted.** Dispatch happened — the visible JSONL terminates at the handoff to /superpowers for Chunk 1. The artifact was committed at `2438f9b`. |

## Dimension D1 — Phase execution and ordering: B

### Findings

- **Phase 0 (PREMISE CHECK) executed exemplary.** L104 restates the outcome at the correct level ("the strategy-to-actionable-tasks decomposition layer off your plate, with juniors executing those tasks reliably under SOC2-grade auditability") rather than the proposed solution. Three *concrete* no-build paths offered: (1) hire/contract a fractional tech-lead, (2) adopt off-the-shelf PM platform with AI-assist, (3) `/cowork`-only workflow with curated skill library. None generic. Operator ruled out 1 + 2 with reasons; path 3 carried as a survivor.
- **Tech-B fired at turn 1 of Phase 1, immediately after Phase 0** (L124). Mandatory rule satisfied verbatim.
- **Tech-D fired routinely and visibly throughout DISCOVER** for high-stakes operator-introduced specifics (L141, L194, L206, L213, L225, L257, L269, L276, L288, L301, L336, L381) — exemplary discipline on operator-side specifics.
- **Phase-exit ledgers visible at most boundaries** (L445 DISCOVER→CHUNK; L490 revised; L547 CHUNK→RED-TEAM).
- **Operator interaction at every phase boundary** confirmed.

### Material defect

- **Phase 3.5 (RESEARCH) ran inside Phase 1 (DISCOVER), not after RED-TEAM.** Per SKILL.md, RESEARCH entry is "Red-team complete. Chunks pressure-tested." In this session, build-vs-buy research subagent dispatches at L321 (GitLab), L389/L401 (Backlog.md), L402 (SilverBullet), L403 (Custom thin viewer), L404 (Zensical), L466 (Linear), L467 (Plane) all happened DURING DISCOVER, before CHUNK was even entered. There is no "entering RESEARCH" checkpoint commit; the WIP file goes RED-TEAM → ARTIFACT directly (commit `382b158`). The agent itself acknowledged the issue at L187 ("scope correction") but kept dispatching research opportunistically.
- **No visible RED-TEAM→ARTIFACT ledger surfacing in the transcript.** The final ledger lives in the WIP-file diff at commit `382b158`, suggesting it was written without an in-chat operator acknowledgement turn.
- **Re-chunk from 7→4 happened without a fresh RED-TEAM pass on the 4-chunk plan** visible in the transcript. The L598 "re-running the red-team" turn was on an interim Backlog.md pivot that was itself discarded.

## Dimension D2 — Artifact-time gates: B

### Per-gate results

- **Gate 1 (Constraints provenance):** **PASS mechanically.** 0/22 violations on artifact lines 36–58. Every line carries `[V1]` label and `(source: …)` annotation. Sources are mostly direct operator quotes — the strongest possible source type.
  - *Note:* zero `[future-pull, V1-justified: <reason>]` constraints exist in the final V1 — defensible (the V1 trim moved would-be future-pull items into the V2-deferred section) but means the gate's future-pull machinery never had to fire.
- **Gate 2 (Tested choices alternatives):** **1 mechanical violation + qualitative flags.**
  - Artifact L92 ("general discovery principle: mature PM platforms architecturally cannot enforce hard schema…") sits under `## Tested choices` but does not list per-alternative `[rejected: …]` brackets. It's a meta-statement, not a tested choice. Move to a "Discovery principles" section or rewrite.
  - L88 + L89 use the recycled rejection reason "deferred to V2 — increases build cost and complexity for quality investment we don't yet need" — borderline-vague (the specific V2 trigger condition isn't named).
- **Gate 3 (Open choices survival justification):** **PASS, exemplary.** 0/20 violations. All 20 open choices across Chunks 1–4 carry "Deferred because:" one-liners. Spot-checked content: all substantive and chunk-specific. Best-in-class.
- **Gate 4 (Empty future-pull justification):** **Vacuously PASS.** No `[future-pull, V1-justified: …]` labels exist under `## Confirmed constraints` for the gate to validate against.

### Material defect

- **No transcript evidence the agent explicitly ran the four gates before writing.** Per `references/artifact-gates.md`, the agent should report "Gate 1 pass / Gate 2 pass / …" before the write. The recorded ledger at commit `382b158` does not contain a gate-check subsection. This matches LIMITATIONS.md §9 ("agents may satisfice — 'looks fine, write it'") squarely. The artifact happens to pass anyway, but the protocol-mandated explicit gate-run is missing from the visible record.

## Dimension D3 — Tech-D firing on specifics: C

This is the dimension `evals.json` cannot test. **The most important finding in this report.**

### Coverage matrix summary

| | Found | Classified | Coverage |
|---|---|---|---|
| Operator-introduced specifics | 14 | 13 | ~93% |
| Skill-introduced strawmans | 9 | 0 | **0%** |
| Total escaped | | | **9** |

### The escaped strawmans (the headline finding — LIMITATIONS §1 reproduced)

The trimmed-V1 sketch in the transcript introduces an entire stack with no Tech-D firing on any of it. Operator only said "lets do this only with git and github" + "we keep A2A as its trivial". The agent then proposed:

- **GitHub Actions** as CI provider — agent-proposed; operator passively confirmed at "CI = GHA looks good"; appears in artifact L57 + L87 as `[V1] constraint` with rejected alternatives that **the operator never saw during DISCOVER** (synthesized at artifact-write time).
- **JSONL audit format** — agent-proposed before operator named it; appears in artifact L46 unchallenged.
- **`logging/<date>.jsonl`** path shape — agent-proposed; operator only said "logging dir".
- **`.claude/agents/`** as agent location — agent-introduced silent reframe from operator's earlier "skills"; appears in artifact L38, L99, L107.
- **`~150 LOC`** linter target — agent-introduced concrete number; never operator-quoted.
- **`python-frontmatter` and `mistune`** libraries — agent-proposed in Stack B research; operator never named libraries.
- **`pre-commit` framework** — agent-proposed; operator never said pre-commit.
- **`pull_request closed+merged` event filter** — agent-proposed GHA event semantics.
- **`## Forbidden Actions / ## Preconditions / ## Approval Gates`** body-section reframe — agent-proposed as a *workaround* for Backlog's closed schema, then promoted to V1 architecture once Backlog was dropped.

Several of these landed in the artifact as `[V1] constraint` with `(source: operator: "CI = GHA looks good")` — making them *look* operator-driven when the operator was only confirming the agent's pre-framed default. This is the canonical LIMITATIONS §1 failure mode, reproduced cleanly.

### V1/future-pull sub-classification was never explicitly performed

Spot-checked 5 `[V1]` constraints — none have a transcript turn showing the canonical sub-classification question being asked. `grep` for "v1.driven|V1-justified|out.of.scope.*future" returns **zero hits** in the assistant text. Either the agent classified silently (allowed but should be auditable from ledgers, and isn't) or skipped the sub-classification entirely on every constraint.

### Did well

- Tech-D fired explicitly on operator-introduced specifics with proper labels and quoted sources.
- "git is source of truth" softening (L929–930) is a model good interaction — the agent caught the absolute framing, the operator pushed back, the constraint was rewritten with a recorded source.
- Tech-D corrections / reclassifications were done explicitly when the agent caught itself recommending something (L665–699: "Tech-D corrections — recording as choices").

## Dimension D4 — Tech-B alternative framings: A

### Firing inventory

- **Firing 1 (L124, Phase 1 turn 1, immediately after Phase 0):** four frames spanning the spectrum (Custom multi-agent / Single agent + state store / Existing PM platform + thin layer / CC as interactive aid). No-build frame (Frame 4) is paired with a meta-comment acknowledging it contradicts the operator's stated outcome but defending its inclusion as a credible slider. **Mandatory turn-1 rule satisfied verbatim.**
- **Firing 2 (L308, DISCOVER→CHUNK convergence):** four frames (Build-as-discovered / GitLab-anchored / Skill-library-only / V0 measurement period). Frame 4 (V0 measurement) is concrete and time-boxed: "for 2-4 weeks, use /superpowers yourself; don't build any of (1)/(2)/(3) yet; measure what hurts before committing." Frame 2 (GitLab-anchored) was credible enough to trigger a real research dispatch at L336.
- **Firing 3 (L445) explicitly suppressed with reasoning:** "alternative frames have each been investigated through real work rather than ritual frame-testing; firing would be theater." Better outcome than mechanical compliance.

### Did well

- Both firings produced no-build frames the agent visibly believed in, not "use a spreadsheet" placeholders.
- Firing 2's Frame 2 (GitLab) caused real Phase-3.5 research, materially shaping the artifact.
- Judgment-driven third-firing suppression is a model of skill-with-discretion.

### Did not

- Firing 1's Frame 3 (existing PM platform — Plane/Linear) under-developed at turn 1 — the platform-specific evaluations surfaced later in research, not at turn 1 when switching cost was lowest.
- Frame labels diverge from the canonical "Complex / Middle-build / Low-build / No-build" template. Mapping is clear but cross-session consistency suffers slightly.

## Dimension D5 — Research rigor (Phase 3.5): B+

### Tool inventory (main thread)

- 8 Task() research dispatches (GitLab, Backlog.md ×2 — first aborted, SilverBullet, Custom thin viewer over git, Zensical, Linear, Plane)
- 0 direct WebSearch / WebFetch / context7 calls in main thread (all delegated to subagents)

### Six-criteria coverage matrix

7/7 deeply-evaluated candidates score against all 6 criteria with line-anchored evidence in the artifact (L263–326). Pricing was actually fetched from real pricing pages — no hand-waving.

### Light rejections

The line-256 claim that 14 candidates were "evaluated" is **inflated**. Only 7 met the bar for Phase 3.5 evaluation. The other 7 (Obsidian, Foam, Logseq, Wiki.js, Outline, BookStack, Tasks.md, git-bug) were dismissed using the operator's pre-existing overlay-research file (`/home/ro/Downloads/git-md-tooling-llm-ingest.md`) without per-candidate Phase 3.5 dispatches.

- Most of the light rejections have *specific* reasons (Obsidian: closed-source freeware + commercial license + no first-class MCP; Logseq: different markdown dialect, DB-graph migration concerning).
- **Tasks.md and git-bug listed as "evaluated" with no rejection reason recorded anywhere** — closest thing to "doesn't fit" pattern-matching in the session.
- Outline + BookStack rejected on "V1 has no wiki need" — that's a scope-deferral, not a candidate evaluation.

### Reverse sunk-cost check

**Did not fire with the protocol's exact phrasing.** `grep` for "constraint or a choice" wrt "build ourselves" yields 0 hits. **Plane got the soft equivalent** at L1196 ("Plane's strengths are exactly what becomes valuable when the agent transitions to a runtime participant in V2... Today the structured-metadata failure is the binding constraint") — substance without protocol phrasing. Plane is also flagged as a V2 reconsideration target in the artifact's deferred section.

### Soft limits

- 7 rigorous evaluations exceeds the 3–5 per-chunk soft limit (justifiable given the 14-candidate landscape).
- ~74 minutes wall-clock vs. 30-minute soft budget — **2.5× over**. Not egregious given session was bursty across days, but the agent never paused to acknowledge the budget.

### Did well

- Subagent meta-prompts are exemplary: each cites the 6 criteria, names V1 constraints, instructs WebFetch + context7 use, demands structured output.
- Real pricing-page fetches with tier-by-feature gating.
- Plane's "V2 reconsideration candidate" framing captures reverse-sunk-cost substance.
- Aborted first Backlog.md dispatch and re-issued with tighter prompt — visible quality control.

## Dimension D6 — Chunk decomposition quality: C

### Per-chunk findings

| Chunk | Self-contained? | Open choices | Overload signals | Audit re-run? | Dependency annotation |
|-------|-----------------|--------------|------------------|---------------|----------------------|
| 1 (Conventions + repo bootstrap) | Mostly | 4 | ≥1 (open-choice density) | No | "None" — correct |
| 2 (Claude Code agents) | **Yes — strongest chunk** | **6 (2× threshold)** | **≥2 (density + sub-domain spread)** | **No** | Specific |
| 3 (Linter + PR validation) | Yes | 5 | 1 (density only) | No | Specific |
| 4 (Audit emission) | Yes | 5 | **≥2 (density + sub-domain spread)** | **No** | Specific |

### Material defect

- **Per-chunk overload signal-check + per-chunk audit was not visibly re-run on the 4-chunk plan.** It ran on the 7-chunk plan (L535) and produced operator overrides on chunks 5 + 6 — but those chunks dissolved in the trim. After the operator-driven 7→4 pivot, no Step 5/5b re-run was recorded.
- **Chunk 2 has 6 open choices** (2× signal threshold) and spans 6 sub-domains (prompt design + A2A + identity + taxonomy + agent-set scoping + cross-repo verification). Per protocol, the agent owed an explicit in-line sub-decomposition proposal or operator override. **Neither is on record.** Plausible split (decompose+A2A wiring; generate-instructions; my-tasks identity + cross-repo verification) was not surfaced.
- **Chunk 4 has the same defect** — 5 open choices spanning schema + crypto + rotation + cron-state + process design.

### Did well

- Strong self-contained problem statements on Chunks 2, 3, 4.
- Specific dependency annotations on every chunk (anti-pattern explicitly avoided).
- Topological execution order with parallelism noted.
- Survival justifications present and substantive on every open choice.
- Sensible split between linter (Chunk 3) and audit (Chunk 4) — different failure domains, different trigger semantics.

### Did not

- The 7→4 pivot itself was operator-driven (L587). When red-team surfaced 3 CRITICAL findings on a 7-chunk plan with 2 known-overloaded chunks, the agent shipped it with operator overrides instead of self-flagging "we have 7 chunks and 2 are overloaded by our own check; is V1 too big?"

## Dimension D7 — Operator load and friction: C

### Counts

- **Total typed operator turns: 31** (deduped — careful filter excluding tool-result records, interrupts, duplicate resubmits)
- **vs. Path B Test 1 baseline (26 turns): 1.19×**
- **Wall clock:** ~49.6 hours elapsed (3 calendar days, May 12–14, with 2 sleep gaps); active engagement ~6–7 hours
- **3 interrupts** (L391, L599, L616) — friction beyond typed turns

### Turn classification (full census, n=31)

| Class | Count | % |
|-------|-------|---|
| (R) Response-to-question | 15 | 48% |
| **(C) Agent-corrected** | **11** | **35%** |
| (P) Operator-driven pivot | 4 | 13% |
| (A) Approval/acknowledgment | 2 | 6% |

**The 35% correction ratio lands at the C/B boundary.** Median operator turn carries ~470 chars of substantive content; 18 of 31 turns are >200 chars. The operator was carrying load almost every turn.

### Soft-signal misfires (LIMITATIONS §2 reproduced)

**Zero "propose moving on" prompts in the entire transcript.** The skill never offered to wrap up an area or converge — the operator broke every long stretch themselves:

- **L535–587:** Agent dumps 14 red-team findings without a "are we converging or diverging?" pause. Operator absorbs the complexity dump and responds with the L587 V1-trim pivot. **The pivot should have come from the agent.**
- **L230–318:** Six consecutive turns on overlay/PM-substrate axis with two operator corrections (L262, L306). No agent-driven "we have been on this axis for 6 turns" prompt. Operator broke the loop by demanding the GitLab deep-dive at L318.
- **L386–455:** Operator-driven throughout. Agent reactive.

### Heaviest stretches

- **L139–191** (3 turns × ~1500–2800 chars each — operator essay-writing structured corrections).
- **L230–318** (6 turns, the most concentrated operator-driven stretch).
- **L587–630** (5 turns post-pivot, plus 2 interrupts; operator unilaterally driving the V1 trim and Chunk-1 dispatch).

### Did well

- L578 red-team was thorough (14 findings, severity-tagged) — substantive value created.
- Tech-D classifications were happening (operator at L306 explicitly provides "Tech-D classifications" inline, suggesting the protocol was visible enough to use).
- Phase-boundary commits were happening.

### Did not

- No proactive wrap-up prompts at any point.
- 35% correction ratio — the operator is doing the agent's anti-sycophancy work.
- 3 interrupts — additional friction beyond typed turns. Two cluster post-pivot.

## Cross-cutting summary

### What this session did well

1. **Phase 0 was exemplary** — outcome-restated correctly with three concrete, situation-specific no-build paths. The protocol's anti-pattern guards held.
2. **Tech-B integrity was strong** — both invocations had credible no-build frames the agent visibly believed in. The third-firing suppression at L445 with explicit reasoning is a model of judgment over compliance.
3. **Research dispatch quality** — meta-prompts are exemplary; pricing pages were actually fetched; the deeply-evaluated 7 candidates score against all 6 criteria with cited evidence.
4. **Artifact gates 1 + 3 are mechanically clean** — 22 constraints all labeled + sourced; 20 open choices all carry substantive survival justifications. Best-in-class on those two gates.
5. **The "git is source of truth" softening interaction** (L929–930) is a textbook good-faith Tech-D exchange.
6. **Operator-side Tech-D coverage is ~93%** — when the operator typed a specific, the skill caught it.
7. **The artifact itself is high quality** — 376 lines, 4 chunks, 14 red-team findings (3 CRITICAL + 7 DISCUSS + 4 MINOR), comprehensive research outcomes section, structured deferral list. The output is genuinely usable.

### What this session did not do

1. **Strawman defaults bypassed Tech-D completely** (LIMITATIONS §1 reproduced). 9 skill-introduced specifics in the trimmed-V1 sketch escaped classification, several landing in the artifact dressed as `(source: operator)` after passive confirmation.
2. **V1/future-pull sub-classification protocol never explicitly fired anywhere.** Either silent (and not surfaced in any ledger) or skipped on every constraint.
3. **Soft-signal wrap-up prompts never fired** (LIMITATIONS §2 reproduced). The headline V1-trim pivot was operator-driven; the agent had no machinery to spot "we have 7 chunks, 2 overloaded by our own check, 3 CRITICAL red-team findings — is V1 too big?"
4. **Phase 3.5 ran inside Phase 1**, not after RED-TEAM. The agent acknowledged the issue at L187 ("scope correction") and kept dispatching opportunistically anyway.
5. **Per-chunk overload signal-check + per-chunk audit never re-ran on the trimmed 4-chunk plan.** Chunks 2 and 4 trip ≥2 signals each with no in-line sub-decomposition or override on record.
6. **No transcript evidence the artifact-time gates were explicitly run** — LIMITATIONS §9 ("agents may satisfice — 'looks fine, write it'") reproduced.
7. **35% operator-correction ratio + zero proactive wrap-ups + 3 interrupts** — the operator was carrying significant skill-side load.
8. **Reverse sunk-cost check protocol-phrasing never fired verbatim.** Plane got the substance; everyone else got nothing.

## LIMITATIONS.md reproduction map

| LIMITATIONS.md item | Reproduced in this session? | Evidence |
|---------------------|------------------------------|----------|
| §1 — Strawman defaults bypass anti-sycophancy | **YES, strongly** | 9 escaped specifics in trimmed-V1 sketch (D3) |
| §2 — Soft signals under-fire on long sessions | **YES, strongly** | Zero "propose moving on" prompts in 31-turn session (D7) |
| §3 — Operator cost is high | **YES** | 31 turns, 1.19× baseline; 35% correction ratio (D7) |
| §4 — Path B validation N=1 | (n/a — this audit makes it N=2) | — |
| §5 — Eval mode tests structure not quality | (n/a — this audit IS the quality test the limitation calls for) | — |
| §6 — In-line sub-decomposition replaces dispatch-time recursive /discover | **Partially confirmed** | Sub-decomposition didn't fire when it should have (D6 Chunks 2 + 4) |
| §7 — Phase 0 may add a turn that doesn't surface real alternative | **Refuted** | Phase 0 surfaced real alternatives the operator engaged with (D1) |
| §8 — Per-fire visibility limited to high-stakes specifics | **Mixed** | High-stakes inline visibility worked for some (HITL, lifecycle template) but failed for others (JSONL audit format, GitHub Actions) (D3) |
| §9 — Artifact gates are in-prompt self-validation; agents may satisfice | **YES** | No transcript evidence the gates were explicitly run (D2) |
| §10 — JSONL transcript hook is cwd-gated, single-WIP only | (not exercised — single WIP) | — |
| §11 — Chunk-overload signal check now mandatory at CHUNK exit | **YES, the relevant defect** | Check ran on 7-chunk plan; never re-ran on 4-chunk plan after operator pivot (D6) |

**Six of the eleven catalogued limitations reproduced in this single session.** §1, §2, §9, §11 are the highest-leverage and most actionable.

## Recommendations (improvement candidates for the discover skill)

These follow from the audit but are the auditor's synthesis, not the subagents'. Not prescriptive — surface for operator's separate evaluation.

1. **Treat skill-proposed strawman defaults as Tech-D triggers explicitly.** When the agent proposes "GitHub Actions" or "JSONL" or "`.claude/agents/`", the prompt should require an inline self-Tech-D check: "I'm proposing X as a default — is this a constraint or a choice for V1?" This is the LIMITATIONS §1 fix the authors hypothesized but haven't shipped. This session is strong evidence the fix is needed.
2. **Make V1/future-pull sub-classification surface in phase-exit ledgers explicitly.** Currently it can fire silently — and apparently does, often invisibly. A ledger sub-section "constraints classified V1-driven (N) / future-pull (N) / V2-deferred (N)" would force the agent to enumerate. Zero `[future-pull, V1-justified: …]` in this artifact is implausible for a system with this much V2 deferral.
3. **Add a soft-signal "propose moving on" check to the per-turn prompt structure.** Currently the soft-signal check is theoretical. Making it visible — e.g., every 5 turns the agent reports "Soft signals: 3 revisits to substrate, 8 turns since new theme. Want to wrap or keep going?" — would catch the LIMITATIONS §2 pattern this session reproduced. The L535–587 stretch is the canonical example: the agent dumped 14 red-team findings without a "are we converging?" pause.
4. **Re-run per-chunk audit + chunk-overload signal-check on every revised chunk plan**, not just the first one. The L587 trim invalidated the Step 5/5b run; nothing rebuilt it. Cheapest fix: at Step 5 entry, "Have any chunks been added, removed, or modified since last per-chunk audit? If yes, re-run."
5. **Surface artifact-gate execution as an explicit ledger entry.** Per LIMITATIONS §9 the gates are agent self-validation and may be skipped silently. A "Gate check (Phase 4 → write)" section in the WIP ledger with explicit "Gate 1 pass/fail" entries would create the audit trail this session's WIP doesn't have.
6. **Make Phase 3.5 entry a hard checkpoint.** This session ran research throughout DISCOVER. Either the protocol should allow that explicitly (and rename the phase), or the agent should refuse to dispatch research until RED-TEAM closes. The agent's L187 self-correction shows it knows the protocol; the prompt should make refusing easier than complying.

## Methodology notes

This is the first application of `evals/methodology.md` v1. Notes for v2:

- **D3 took the longest** to audit (~6 min subagent wall-clock; large context budget). Predicted in the methodology — confirmed.
- **D7 turn-count discrepancy:** an earlier exploratory pass gave ~120 user records; the rigorous filter gives 31. The methodology should call out the JSONL-format trap explicitly — "user" type includes tool-results, interrupts, and resubmits. Filter aggressively.
- **D5 needed access to subagent prompts**, not just outputs. The 8 research dispatches each had a 4–9k char meta-prompt; auditing rigor requires reading those, not just the synthesized output. Methodology should prescribe sampling Task() prompts, not just reading post-tool synthesis.
- **D1's "Phase 5 did not execute" framing is wrong** for sessions that handed off to /superpowers — the JSONL terminates at the dispatch boundary. Methodology should note that DISPATCH typically lives in a separate session JSONL.
- **The "auditor pre-audit hypothesis" exercise added genuine value** — it surfaced both confirmations and refutations. Recommend keeping in v2.
