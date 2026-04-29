# Discovery: Personal Todo System

**Date:** 2026-04-29
**Status:** Discovery complete, ready for execution
**Chunks:** Single chunk — no decomposition needed

## Execution order

1. Chunk 1: Evaluate-and-adopt todo system (no dependencies)

## Framing

The user wants a single, reliable personal todo system that ends fragmentation across notes apps, email, and post-its. Originally framed as "build me a todo app," but Socratic discovery reframed it: the goal is to *have* a working personal todo workflow, not to *build* one. "Building it myself" is a choice, not a constraint, so off-the-shelf candidates are on the table. Use is personal-only, on macOS + iOS, with keyboard-first power use on Mac and quick-capture on iPhone (including via Siri).

### Original statement

> Build me a todo app

### Key reframes

- **From "build" to "adopt the right tool."** User confirmed primary goal is to end up with a working todo system, not to build software for its own sake. The "fun project" framing was rationalization.
- **From "no app exists for me" to "I haven't picked one and committed."** The pain is fragmentation, which is solved by having a canonical location — not by adding new features.
- **Reductive frame stays alive.** Apple Reminders + Siri (zero install, zero config) was carried into Phase 3.5 alongside the SaaS and plain-text options, because it meets every hard constraint.
- **Chunk shape changed.** Originally would have been a "design and build a todo app" chunk; after research, it's "evaluate three finalists hands-on and adopt the winner."

## Confirmed constraints

- **Devices: macOS + iOS only.** User's actual hardware. Hard constraint, externally given.
- **Sync between Mac and iPhone is required.** Without it, capture-on-the-go fails and the system breaks. User said this would defeat the purpose otherwise.
- **Simple recurrence is needed (daily/weekly/monthly).** Example: "water plants every Wednesday." Nothing more complex.
- **Siri voice capture must work.** "Hey Siri, remind me to..." needs to land in the system. Surfaced in red-team and confirmed.
- **Annual cost ceiling: ~$50/yr.** Paid is fine, but bounded. Not zero, not unlimited.
- **Mac side is keyboard-first.** Heavy use is on Mac; user lives in editor; mouse-driven UIs are a friction.
- **iPhone side is capture-only.** User does not want to "live in" the app on iPhone — just add tasks fast.

## Tested choices

- **Build vs. adopt.** Alternatives considered: build a custom web/mobile app, adopt an existing SaaS tool, use a plain text file. Selected: adopt (with the specific tool TBD by hands-on trial). Rejected build because user's primary goal was the working system, not the project.
- **Existing SaaS vs. plain text vs. OS-native.** All three carried into Phase 3.5 research with equal weight (Technique B). Outcome: shortlist of Things 3, Todoist, Apple Reminders. todo.txt eliminated due to iOS friction; SaaS others (TickTick) eliminated as strictly dominated.
- **Data export importance.** User stated soft preference for exportability ("not a black hole") but accepted that all shortlisted candidates have export paths.

## Chunk 1: Evaluate-and-adopt personal todo system

### Problem statement

End fragmentation of personal task tracking by adopting one canonical todo system that runs on macOS + iOS, syncs between them, supports simple recurrence (daily/weekly/monthly), takes Siri voice capture, has keyboard-first ergonomics on Mac, and stays under ~$50/yr. The hands-on evaluation shortlist is **Things 3**, **Todoist**, and **Apple Reminders** — all three meet the hard constraints, so the decision is taste and pricing-model preference. The chunk's job is to (1) trial each finalist for ~3 days with the user's real tasks, (2) compare them on the user's lived experience, (3) pick one, (4) migrate scattered tasks from email/notes/post-its into the chosen tool, and (5) decommission the alternatives. There is no code to write — this is an evaluation + adoption + migration chunk.

### Constraints (inherited + chunk-specific)

- macOS + iOS only
- Sync between Mac and iPhone is required
- Simple recurrence (daily / weekly / monthly) supported
- Siri voice capture works ("Hey Siri, remind me to...")
- Annual cost ≤ $50/yr (or one-time purchase that amortizes below that)
- Mac side is keyboard-first
- iPhone side is capture-only
- Data export is possible (soft constraint)

### Open choices (for the executor to resolve)

- Which finalist to adopt: Things 3, Todoist, or Apple Reminders. Decision criteria: keyboard-first feel on Mac during the trial, perceived friction of quick-capture on iPhone, subjective fit.
- Trial protocol: how many days each, what counts as "real use," when to switch to the next.
- Migration plan: what scattered tasks exist (email, Apple Notes, post-its) and how to consolidate them into the chosen tool.
- Decommission protocol: what happens to tasks in tools not chosen — delete, archive, ignore?
- (If Things 3 wins) is the ~$70 one-time purchase OK given user said they'd pay $30-50/yr? It amortizes below $50/yr after ~1.5 years, but it's a bigger up-front spend.

### Dependencies

None — this chunk has no prerequisites.

### Recommended executor

`/superpowers:brainstorming` — but the brainstorming session should be framed as "design a 1-week evaluation and migration protocol," NOT "design a todo app." If the executor starts proposing schemas and architectures, the framing has been lost.

## Red-team findings

### Addressed

- **[DISCUSS] Cost tolerance was never asked.** Resolution: added "annual cost ≤ $50/yr" as a constraint. Filtered candidate list (Things 3 amortizes under, Todoist/TickTick fit, expensive enterprise tools eliminated).
- **[DISCUSS] Data portability / lock-in not discussed.** Resolution: added "data export possible" as a soft constraint. All three finalists support export.
- **[DISCUSS] Siri / voice capture not surfaced.** Resolution: added as a hard constraint. Filtered out anything that doesn't have first-class iOS Siri integration (this is what eliminated todo.txt as the primary system — its Siri path requires a custom Shortcut you'd build and maintain).
- **[DISCUSS] The chunk is really an "evaluate and integrate" chunk, not a "design and build" chunk.** Resolution: chunk reframed accordingly. Recommended-executor note explicitly warns the brainstorming session not to drift into building.

### Accepted risks

- **[MINOR] Future device flexibility (e.g., a future Linux work laptop) not factored in.** Accepted — out of scope for current decision; can revisit if hardware changes.
- **[MINOR] Backup / disaster recovery not designed.** Accepted — SaaS candidates handle it; if the user later switches to text-based, they'll set up git sync. Not blocking adoption now.

### Dismissed

None.

## Research outcomes (build-vs-buy)

### Overall problem

- **Searched for:**
  - `best personal todo app 2026 self-hosted open source`
  - `Todoist vs TickTick vs Things 3 personal todo app comparison 2026`
  - `simple todo app plain text taskwarrior todo.txt cli`
- **Candidates evaluated:** Todoist, TickTick, Things 3, Apple Reminders, todo.txt + iOS Shortcut, Vikunja
- **Outcome:** **Adopt fully** — strong shortlist of three (Things 3, Todoist, Apple Reminders) all meet hard constraints; final choice is hands-on trial. The build-from-scratch chunk is eliminated.
- **Effect on chunks:** The original "build a todo app" framing has been replaced. There is no build chunk. The single chunk is now an evaluation-and-integration chunk.

### Chunk 1: Evaluate-and-adopt personal todo system

- **Searched for:** see above (whole-problem search served the chunk).
- **Candidates evaluated:**

  - **Todoist** — *Adopt fully* (top finalist)
    - URL: https://todoist.com
    - Functionality match: ~95% (everything required, plus AI extras not asked for)
    - Cost: $48/yr Pro
    - License: proprietary SaaS
    - Maintenance: extremely active (full AI suite "Todoist Assist" shipped in 2026)
    - Lock-in: medium — full export to JSON/CSV supported
    - Integration burden: low — install app, sign in
    - Reason for classification: clean fit for all hard constraints; native Siri Shortcuts; mature keyboard shortcuts; under cost ceiling.

  - **Things 3** — *Adopt fully* (top finalist)
    - URL: https://culturedcode.com/things/
    - Functionality match: ~90% (Apple-only is a feature here, not a bug)
    - Cost: ~$70 one-time (Mac + iOS combined); amortizes under $50/yr after ~1.5 years
    - License: proprietary
    - Maintenance: stable, slower release cadence but reliable
    - Lock-in: medium — supports plain-text export
    - Integration burden: low
    - Reason for classification: best-in-class keyboard ergonomics on Mac, native Siri/Reminders import, perfect platform fit. Up-front cost is the only consideration.

  - **Apple Reminders** — *Adopt fully* (reductive option, also a finalist)
    - URL: https://www.apple.com/ios/ (built-in)
    - Functionality match: ~80% (loses on power-user keyboard ergonomics; wins on everything else)
    - Cost: $0
    - License: Apple, bundled with OS
    - Maintenance: Apple
    - Lock-in: high to Apple ecosystem (but user is constrained there anyway, so the practical lock-in is zero)
    - Integration burden: zero — already installed
    - Reason for classification: meets every hard constraint, costs nothing, native Siri is best-in-class. The reductive frame deserves an honest trial alongside the paid options. Could turn out to be sufficient.

  - **TickTick** — *Reject*
    - URL: https://ticktick.com
    - Functionality match: ~95%
    - Cost: ~$36/yr Premium
    - License: proprietary SaaS
    - Maintenance: active
    - Lock-in: medium
    - Integration burden: low
    - Reason for classification: strictly dominated for this user's needs. Bundled extras (Pomodoro, habit tracker) add visual noise without adding value to a user who said "just the basics." Todoist is cleaner if going SaaS-paid; Things 3 is better-fitted if going Apple-only.

  - **todo.txt + iOS Shortcut + iCloud** — *Inspire*
    - URL: http://todotxt.org
    - Functionality match: ~70%
    - Cost: $0
    - License: open / public domain format
    - Maintenance: format is stable; ecosystem is active but iOS support is third-party
    - Lock-in: zero — plain text
    - Integration burden: medium-high — need to build/maintain an iOS Shortcut for capture; recurrence has no native engine; Siri path is custom.
    - Reason for classification: the "one canonical location" insight is right and informs how the user should think about whichever tool they pick. But the iOS-side implementation cost is too high for this user's stated tolerance. Note as a fallback if the SaaS finalists prove unworkable.

  - **Vikunja (self-hosted)** — *Reject*
    - URL: https://vikunja.io
    - Functionality match: ~85% on the desktop side, ~30% on mobile/Siri
    - Cost: free software, hosting cost extra
    - License: AGPL-3.0
    - Maintenance: active
    - Lock-in: low (open data formats)
    - Integration burden: high — requires running a server
    - Reason for classification: ops burden user did not sign up for; no first-class iOS app with Siri; over-engineered for personal-only use. The user is not in "I want to run servers" mode.

  **Reverse sunk-cost check applied:** Operator confirmed in Phase 1 that "build it myself" is a choice, not a constraint. Once that was on the record, the bar for rejecting Adopt candidates required a specific functional gap. None of Todoist / Things 3 / Apple Reminders has one for the user's stated needs — so all three are viable adopt-fully outcomes, with the final pick decided by hands-on trial.

- **Outcome:** Chunk replaced with an evaluation-and-integration chunk. There is no custom code to write. Shortlist: Things 3, Todoist, Apple Reminders.

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

- **Q:** Who is this for — just you, or also other people?
  **A:** Just me, personal use.
  **Impact:** Eliminated team/multi-user requirements early; sharply narrowed candidate space.

- **Q:** Is the goal a working todo system as fast as possible, or is the building itself the point?
  **A:** Mostly the working system; "fun project" was rationalization.
  **Impact:** Reframed the whole skill output from "design a custom app" to "find the right adoption path." This was the most important reframe in the session.

- **Q:** [Technique B] Three frames — build a custom app, pick an existing SaaS tool, or use a plain text file. Which resonates?
  **A:** Probably between SaaS and plain text. Not sold on building anymore.
  **Impact:** Carried all three frames into research with equal weight; ensured the reductive frame got honest evaluation.

- **Q:** [Technique D] Mac + iPhone — constraint or choice?
  **A:** Hard constraint.
  **Impact:** Filtered out cross-platform-only services and self-hosted complexity. Made Apple Reminders viable as a reductive option.

- **Q:** [Technique B at convergence] Three lenses on the landed solution — Todoist-class, todo.txt + phone shim, or Apple Reminders + Shortcuts?
  **A:** Take all three to research; Reminders feels too dumb but maybe I'm wrong.
  **Impact:** Kept the reductive frame alive into Phase 3.5, where it survived as a finalist.

- **Q:** [Red-team] Cost tolerance? Lock-in concerns? Voice/Siri capture?
  **A:** $30-50/yr ceiling; want export possible; yes Siri matters.
  **Impact:** Added three constraints that shaped the shortlist. todo.txt fell out of finalist contention because of Siri friction; SaaS finalists fit cleanly under cost ceiling.

</details>
