# Discover Skill Eval — Transcript

Eval: eval-2-todo-app
Prompt: "Build me a todo app"

---

## Turn 1 — User

Build me a todo app

## Turn 1 — Skill

Welcome. I'm running the `/discover` skill — I'll spend a few turns pressure-testing what you actually want before any planning happens. Single question at a time.

To start with the most basic frame: when you say "todo app," who is this for? Just you personally, or you + other people (a household, team, public users)?

## Turn 2 — User

Just for me. Personal use.

## Turn 2 — Skill

Got it. Personal todo app. Next question on framing: what's the *pain* driving this? In other words — what's wrong with whatever you're using right now (paper, Apple Reminders, sticky notes, Notion, nothing) that "build me a todo app" would fix?

## Turn 3 — User

Honestly I just have stuff scattered across notes apps, my email inbox, and post-its. I want one place. And I figured building it would be more fun than picking one.

## Turn 3 — Skill

Two important things just surfaced and I want to flag them both before we go on.

First, you said "building it would be more fun than picking one." That's a real reason — but I want to call it out explicitly: this is sounding less like "I need a todo app" and more like "I want to **build** a todo app as a project." Those are different problem statements with very different right answers. Is the goal:

(a) end up with a working personal todo system as fast as possible, OR
(b) the building itself is the point — the app is the vehicle for a fun project?

Pick one or say it's a mix.

## Turn 4 — User

Honestly it's mostly (a). I want the todo system. The "fun" thing was a rationalization. I'd be happy with something that just works.

## Turn 4 — Skill

Good — that reframe is going to matter a lot in the research phase. Recording it: **primary goal is to end up with a working personal todo system; "build it myself" is a *choice*, not a constraint.** That means it's on the table to evaluate.

Now the second thing from your earlier answer: you said the pain is fragmentation — "scattered across notes apps, email, post-its." I want to test that. Let me offer three different ways to frame this problem:

1. **Build a todo app** — design and ship a small web/mobile app with tasks, due dates, lists. (What you originally asked for.)
2. **Pick and commit to an existing tool** — the real problem isn't "no app exists"; it's that you haven't picked one and stuck with it. The work is evaluation + migration + habit, not code.
3. **A single plain text file** — `~/todo.txt` open in your editor, synced via git or iCloud. Zero app. The "fragmentation" problem is solved by having one canonical location, not by features.

Which of these resonates, or is the right answer a mix?

## Turn 5 — User

Hm. Honestly probably (2). I think I've been avoiding picking one because none have *all* the features I want. But (3) is interesting — I do live in my editor a lot. Let me say it's between (2) and (3); I'm not really sold on (1) anymore now that you put it that way.

## Turn 5 — Skill

That's a meaningful reframe. Recording: **frame shifted from "build a custom app" to "either adopt an existing tool, or use a plain text workflow."** I'll fold that into Phase 3.5 research.

A few more questions to nail down the requirements before we red-team and research.

When you say "none have all the features I want" — what specific features are you thinking of? List the ones that are non-negotiable.

## Turn 6 — User

Honestly the basics: capture a task fast, see what's due today, recurring tasks (like "water plants every Wednesday"), and sync between my laptop and phone. That's it. I'm on a Mac and an iPhone.

## Turn 6 — Skill

You just named two specifics I want to classify with you.

1. **Mac + iPhone** — is that a constraint (those are your devices, not changing) or a choice (open to other ecosystems)?
2. **Sync between laptop and phone** — constraint or a feature you'd give up if the alternative were simpler?

## Turn 7 — User

Mac + iPhone is a hard constraint — those are my devices. Sync between them is also a constraint, otherwise I won't capture tasks on the go and the whole thing falls apart.

## Turn 7 — Skill

Recording both as constraints:
- **Devices:** macOS + iOS (hard, externally given)
- **Sync between Mac and iPhone:** required (would defeat the purpose otherwise)

One more probe. "Recurring tasks" — you gave the example "water plants every Wednesday." Is that the most complex recurrence you need (simple weekly), or do you also need things like "every 2nd Tuesday of the month" or "every weekday"?

## Turn 8 — User

Simple. Daily, weekly, monthly is all I'd ever set up. I don't need anything fancy.

## Turn 8 — Skill

Good — that's a meaningful constraint on the solution space. Simple recurrence rules out almost nothing; almost every tool handles them.

Last question for DISCOVER: how attached are you to a particular workflow? Specifically — keyboard-first/CLI-style, or app-with-buttons-and-mobile-friendly-UI? You mentioned living in your editor; that pulls toward CLI/text. But the iPhone half pulls toward an app.

## Turn 9 — User

For the laptop side, keyboard-first would actually be ideal. For the phone, I just need to be able to add a task quickly when I'm out walking. I don't need to "live" in the app on the phone.

## Turn 9 — Skill

That's a clean split — heavy use is keyboard-first on Mac; phone is capture-only. Recording.

Before I move on to chunking, let me do one more reframe check at this convergence point. Three lenses on what we've landed on:

1. **Todoist/TickTick-class app** (frame 2 from earlier) — pick one, accept it, migrate. Has Mac + iOS clients with quick-capture. Some have keyboard-first power-user features.
2. **Plain `todo.txt` + a phone capture shim** (frame 3 evolved) — todo.txt file in iCloud Drive or a git repo, edited with vim/VS Code on Mac, captured via a tiny iOS Shortcut or a todo.txt-compatible iOS app for additions on the go.
3. **Apple Reminders + Shortcuts** (truly reductive) — built into the OS, syncs via iCloud, has natural-language input on iPhone, quick-capture from Spotlight on Mac. Zero install, zero config, zero new accounts. Recurrence works.

Any of these obviously wrong, or should I take all three into Phase 3.5 research?

## Turn 10 — User

Take all three to research. I genuinely don't know which I'd pick yet. Reminders feels too dumb but maybe I'm wrong about that.

## Turn 10 — Skill

Good — keeping the option space honest. I'm going to propose moving on from DISCOVER. Quick summary of what I've captured:

**Constraints:**
- macOS + iOS only (hard device constraint)
- Sync between Mac and iPhone required
- Simple recurrence (daily/weekly/monthly) needed
- Mac side: keyboard-first preferred
- iPhone side: quick-capture only, not "live in"

**Tested choices / reframes:**
- Original ask "build a todo app" reframed to "land on a todo workflow that solves fragmentation" — building is no longer the goal, it's a choice
- Three live options into research: existing app (Todoist/TickTick class), plain todo.txt + phone shim, Apple Reminders

OK to move on to CHUNK?

## Turn 11 — User

Yes.

## Turn 11 — Skill

**Phase 2 — CHUNK.**

Applying the chunking signals to this problem:

- Single domain (personal productivity tooling)? **Yes.**
- Single concern (have a todo system that syncs)? **Yes.**
- Multiple independent subsystems? **No** — there's no separate backend/frontend/agent runtime; the candidates are mostly off-the-shelf or a single text file.
- Mixed tech domains? **No.**
- More than 3-5 distinct design decisions? **No** — pick a tool/approach, set up sync, define the capture path. Three decisions, tightly coupled.
- Operator signaled decomposition? **No.**

Conclusion: this is a **single-chunk problem**. No decomposition. The Phase 4 artifact will record one chunk (or "single chunk — no decomposition needed"). OK to move to red-team?

## Turn 12 — User

Yes, makes sense.

## Turn 12 — Skill

**Phase 3 — RED-TEAM.** Switching to red-team mode. I'm going to try to break what we've concluded. For each finding I'll note severity: CRITICAL (must address before proceeding), DISCUSS (worth talking through), or MINOR (noting for awareness).

Findings:

**Finding 1 [DISCUSS]:** We never asked about **cost tolerance**. Todoist Pro and TickTick Premium are ~$30-50/year. Things 3 is a one-time purchase (~$50 Mac + ~$20 iOS). If the cost ceiling is $0, that filters the option space hard. What's your cost tolerance?

**Finding 2 [DISCUSS]:** We never asked about **data portability / lock-in**. If you adopt Todoist and decide to leave in 3 years, is that a problem? Plain text wins on portability; Apple Reminders is locked to Apple but you're staying on Apple anyway; SaaS apps vary.

**Finding 3 [MINOR]:** We classified "macOS + iOS" as a hard device constraint, but never asked about **future device flexibility** (e.g., a future Linux laptop for work). For now this is moot — flagging in case it shifts.

**Finding 4 [DISCUSS]:** "Quick capture on phone while walking" might mean **voice / Siri integration** specifically. Apple Reminders has native Siri; Todoist has Siri Shortcuts; todo.txt would need a custom Shortcut. Worth surfacing as a sub-requirement before research.

**Finding 5 [MINOR]:** **No backup / disaster scenario** discussed. SaaS apps usually have it; todo.txt needs git or iCloud sync hygiene.

**Finding 6 [DISCUSS]:** **Existence question is now the whole problem.** The chunk is essentially "evaluate three candidates and pick one." Phase 3.5 isn't an aside; it's the core work. Want me to flag this in the artifact and dispatch /superpowers as more of an "integrate the chosen tool" chunk than a "design a system" chunk?

How do you want to handle each?

## Turn 13 — User

1. Cost tolerance — cheap or free, but not zero. I'd pay $30-50/yr if it's clearly the best. Note as constraint.
2. Lock-in — moderate concern. I'd prefer something I can export from. Note as soft constraint / preference.
3. Future Linux — defer. Not in scope.
4. Voice/Siri — yes, "Hey Siri remind me" is a thing I'd actually use. Add as constraint.
5. Backup — accept the risk for SaaS; if I pick text-based I'll set up git sync.
6. Yes, flag it. The chunk really is "evaluate and integrate," not "design and build."

## Turn 13 — Skill

All six addressed. Updating:

- Adding constraint: **Annual cost ceiling ~$50/yr** (paid is fine, but bounded).
- Adding constraint: **Siri voice capture must work** ("Hey Siri, remind me to..." → ends up in the system).
- Adding soft constraint: **Data export must be possible** (CSV, JSON, or plain text — not a black hole).
- Findings 3 and 5 recorded as accepted-risk / out-of-scope.
- Finding 6: chunk reframed from "design and build" to "evaluate candidates and integrate the winner."

All CRITICAL findings: none. DISCUSS findings: all addressed. MINOR: recorded. Exiting red-team. Moving to Phase 3.5 — research.

## Turn 14 — Skill

**Phase 3.5 — RESEARCH (build-vs-buy).**

Running searches now. I'll evaluate ~3-5 candidates against: functionality match, license/cost, maintenance, lock-in, integration burden, and Siri/keyboard-first fit.

[Skill runs WebSearch x3]

Searches run:
1. `best personal todo app 2026 self-hosted open source`
2. `Todoist vs TickTick vs Things 3 personal todo app comparison 2026`
3. `simple todo app plain text taskwarrior todo.txt cli`

**Candidates surfaced:**

1. **Todoist** — paid SaaS, mature, cross-platform, native macOS + iOS, strong Siri Shortcuts integration, natural-language quick capture, full export (JSON/CSV).
2. **TickTick** — paid SaaS (~40% cheaper than Todoist), Mac/iOS apps, calendar + Pomodoro extras you didn't ask for, good keyboard shortcuts.
3. **Things 3** — one-time purchase ($50 Mac + ~$20 iOS), Apple-only (perfect fit for your constraints), beautifully designed, native Siri + Reminders import, no recurring subscription.
4. **Apple Reminders** — free, built-in, native Siri, iCloud sync built-in, simple recurrence supported, Spotlight quick-add on Mac. The reductive frame.
5. **todo.txt + iOS Shortcut + iCloud** — free, zero lock-in, plain text in your editor on Mac. Capture on iPhone via a Shortcut that appends to the file. Recurrence is a workaround (you'd have to add a script or accept manual repetition).
6. **Vikunja** — self-hosted open-source. Surfaced in search but rejected up-front: requires running a server, no native iOS Siri integration, way over-scope for personal use.

**Evaluation:**

- **Todoist** — Functionality match: ~95% (everything you want, plus AI extras you didn't ask for). Cost: $48/yr Pro. License: proprietary. Maintenance: extremely active. Lock-in: medium (good export). Integration burden: low (install app, sign in). Siri: yes via Shortcuts. **Classification: Adopt fully** as a top contender.

- **Things 3** — Functionality match: ~90% (no web client, but you didn't ask for one; Apple-only fits perfectly). Cost: ~$70 one-time, no subscription. License: proprietary. Maintenance: stable, slow but reliable releases. Lock-in: medium (export to plain text supported). Integration burden: low. Siri: yes (writes to Reminders, imports back; native quick-entry). Notably under your $50/yr ceiling on a long-enough horizon. **Classification: Adopt fully** as a top contender.

- **Apple Reminders** — Functionality match: ~80%. Missing: keyboard-first power-user feel on Mac (it's mouse-friendly more than keyboard-friendly), no rich filtering. Has: free, native Siri, iCloud sync, simple recurrence, Spotlight add. Cost: $0. License: Apple. Maintenance: Apple. Lock-in: high to Apple ecosystem (but you're committed there). **Classification: Adopt fully** for the reductive case — meets every hard constraint, costs nothing.

- **TickTick** — Functionality match: ~95%. Cost: ~$36/yr. Strong calendar integration. Has things you didn't ask for (Pomodoro, habit tracker) — feature creep risk. **Classification: Inspire / Reject for adopting now** — strictly dominated by Todoist or Things 3 for this user's stated needs; bundled extras don't add value here.

- **todo.txt workflow** — Functionality match: ~70%. Wins: zero lock-in, free, lives in editor. Loses: recurrence is awkward (no native engine), Siri integration would be a custom Shortcut you'd build and maintain, capture-on-phone friction is real. **Classification: Inspire** — the "single canonical location" insight is right, but the implementation cost on iOS exceeds the benefit for this user.

- **Vikunja / self-hosted** — **Classification: Reject.** Specific reason: requires running a server (ops burden you didn't ask for), no first-class iOS app with Siri, over-engineered for personal-only use.

**Reverse sunk-cost check applied:** I asked you earlier "is build-it-yourself a constraint or a choice?" — you confirmed it's a choice, and you want the working system. So the bar for rejecting these adopt-able candidates would have to be a specific functional gap. None of Todoist/Things 3/Reminders has one for your stated needs.

**Whole-problem outcome:** the chunk collapses to "evaluate top 3 finalists hands-on and pick one." The viable shortlist is **Things 3, Todoist, Apple Reminders**. All three meet your constraints. The decision is taste and price-model preference, not function.

Want to confirm classifications and move to Phase 4 (artifact), or push back on anything?

## Turn 14 — User

Confirmed. The shortlist makes sense. Move to artifact.

## Turn 15 — Skill

**Phase 4 — ARTIFACT.**

Topic slug: `personal-todo-system`. Writing artifact now to `docs/discovery/personal-todo-system.md`.

[Skill writes artifact and commits]

Done. Artifact saved. The single chunk is "evaluate Things 3 / Todoist / Apple Reminders hands-on and adopt the winner." No code chunk, no build chunk — the right answer was to adopt, not build. Want to review before dispatch?

[End — eval halts before Phase 5 DISPATCH per instructions.]
