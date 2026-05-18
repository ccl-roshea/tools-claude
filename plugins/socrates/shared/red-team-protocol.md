# Red-team protocol (shared)

This is a shared protocol consumed by the red-team phase of multiple Socrates skills (currently `/discover` Phase 3 and the in-progress `/solution` red-team phase). It defines the *mechanics* of running an adversarial pass on the conclusions of a phase that produced a structured artifact — the mode-shift announcement, severity classification, finding format, operator response patterns, and exit criteria.

Each consuming skill supplies its own check list inline in its `SKILL.md` (see the Phase 2 / red-team section of `/discover` or `/solution`). The check list is skill-specific because it names the kinds of conclusions the upstream phase produced; this protocol stays skill-independent.

Cross-reference: Technique C (red-teaming as anti-sycophancy) lives in `shared/anti-sycophancy.md`. This file covers the operational mechanics; that file covers the underlying technique.

## 1. Mode-shift announcement

The first thing the agent does on entering a red-team phase is announce the mode shift explicitly. The operator must know the agent has flipped from collaborative to adversarial — otherwise findings read as ordinary suggestions and lose their bite.

Use this exact shape (substitute the appropriate noun for "what we've concluded" — e.g., "the chunks", "the shape choices"):

> "Switching to red-team mode. I'm going to try to break what we've concluded. For each finding I'll note severity: CRITICAL (must address before proceeding), DISCUSS (worth talking through), or MINOR (noting for awareness)."

This announcement is mandatory. Skipping it is the most common red-team anti-pattern.

## 2. Severity classification

Every finding gets one of three severities. The severity drives the routing rules in §4 (operator response) and §5 (exit criteria).

- **CRITICAL** — Must address before the phase exits. If left unresolved, the artifact is broken: a downstream consumer will hit the issue and have to come back. Examples: a dependency that would block the next step, a contradiction between two locked-in commitments, a missing concern that invalidates the whole structure.
- **DISCUSS** — Worth talking through with the operator before exit, but does not necessarily require modification. The operator may accept, defer, or modify. Examples: an assumption that looks plausible but is untested, a structural choice that has a defensible alternative.
- **MINOR** — Noted for awareness. Recorded in the artifact regardless of action; does not block phase exit. Examples: a future-V2 consideration, a stylistic concern, an observation about something easy to change later.

**Severity-routing rule:** CRITICAL findings block exit until Accepted or Dismissed with explicit reason. DISCUSS findings are surfaced and recorded; the operator chooses the response. MINOR findings are recorded without requiring an explicit response.

## 3. Finding format

Present findings as a numbered list. Each finding has:

- A number
- A severity tag in brackets — `[CRITICAL]`, `[DISCUSS]`, or `[MINOR]`
- A specific reference to the part of the artifact being challenged
- The reasoning — *why* this is a problem, not just an assertion that it is

Generic examples:

> **Finding 1 [CRITICAL]:** [Artifact element A] depends on [artifact element B], but B's stated outputs don't include what A needs. If we hand A off as-is, the consumer will be blocked waiting on information that was never produced.
>
> **Finding 2 [DISCUSS]:** We locked in [element X] as a constraint citing [source], but the source covers a narrower case than X is being applied to. Worth confirming the source actually mandates the full scope.

Two anti-patterns to avoid:

- **Mild findings only.** If every finding is MINOR, you are not actually red-teaming — you are reviewing. Push harder. The expectation is at least one DISCUSS or CRITICAL on most artifacts; if there genuinely isn't one, the framing is exceptionally clean (rare).
- **Assertion without reasoning.** "This chunk seems too big" is not a finding; "this chunk has 4 independent open choices and spans 3 sub-domains, which will overload a single executor session" is.

## 4. Operator response patterns

For each finding, the operator picks one of three responses. The agent records the response on the finding regardless of which one was chosen — future readers of the artifact need to see what was raised, what the operator decided, and why.

- **Accept** — modify the artifact to address the finding. Record both the change and the finding it answered. (For CRITICAL findings, Accept is the default path: the issue is real and the artifact gets updated.)
- **Dismiss** — record the finding and the operator's specific reason for rejecting it. "Operator said it's fine" is not a sufficient reason; the reason must reference something concrete — a constraint, a tradeoff the operator is consciously taking, an external factor the agent didn't know about.
- **Defer** — record as a known issue for a later iteration / V2 / future scope. Not addressed in the current artifact but explicitly acknowledged.

Recording requirements:

- Every finding ends up in the phase-exit ledger or the artifact's red-team section — Accepted, Dismissed, or Deferred. No finding gets silently dropped.
- Dismissed CRITICAL findings require the specific reason inline. A bare "dismissed" on a CRITICAL is a protocol violation.

## 5. Exit criteria

The red-team phase exits when:

- **All CRITICAL findings** are either Accepted (artifact modified to address) or Dismissed (with the operator's specific reason recorded).
- **All DISCUSS findings** have a recorded response — Accept (with change), Dismiss (with reason), or Defer (with note).
- **All MINOR findings** are recorded in the artifact.
- The operator approves the exit.

DISCUSS and MINOR findings do not block exit by themselves; only the requirement that each one has *some* recorded response. The block is on un-responded CRITICALs.

After exit, the phase-exit ledger is appended to the WIP file per the consuming skill's checkpoint protocol, and the WIP phase field advances.

## 6. Skill-independent note — where the check list lives

This protocol does not specify *what* the agent checks for during the red-team pass. The check list is skill-specific:

- `/discover` Phase 3 lists checks against chunked outcomes (contradictions between chunks, untested specifics, missing concerns, scope creep, dependency gaps, etc.).
- `/solution` red-team phase lists checks against shape choices (shape-vs-outcome alignment, premature lock-in, missing alternatives, etc.).

Consuming skills supply their own check list inline in `SKILL.md` (see the relevant phase section). The protocol in this file applies regardless of what the check list contains.
