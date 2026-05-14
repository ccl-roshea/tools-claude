# Discover response labeling — addressable §X.Y.Z

## Problem

Discover responses are dense, multi-section synthesis turns: phase-exit ledgers, Tech-B 4-option frames, chunk proposals, red-team findings, research summaries. Today the labeling inside those responses is ad-hoc — the agent numbers Tech-D classifications `1.`/`2.`, letters status-flow options `A.`/`B.`, but leaves section headings, sub-headings, bullets, and trailing questions unlabeled. The operator cannot reliably target a specific point with "address §X.Y" because there is no §X.Y to point at; "respond to point 2" is ambiguous between the second tech-D entry and an unrelated bullet.

The asymmetry is the worst of both worlds: the agent looks structured but the structure isn't addressable.

## Goal

Every discover response is internally addressable. Operator can quote any section, sub-section, list item, inline classification, or question by a stable inline label.

## Non-goals

- Persistent IDs across turns or sessions. Labels are TOC-of-this-message, not durable cross-turn references.
- Automated TOC at the top of responses.
- Labeling plain prose paragraphs (transitions, mode-shift announcements, connective text).
- Code changes. The protocol is descriptive instruction for the agent, parallel in shape to the existing continuous Tech-D rule.

## Design

One new reference file plus two small SKILL.md edits.

### What gets labeled

- **Section headings.** Top-level `§1`, sub-headings `§1.1`, deeper `§1.1.3` etc.
- **List items.** Bullets and numbered items inside a section: `- §1.1.1 Markdown-as-store...`. The `§` address supersedes any in-content `1.`/`2.` numbering — those collapse into the address.
- **Inline Tech-D classifications.** When the agent surfaces a classification mid-turn, that line is addressable.
- **Questions to the operator.** Separate counter, prefixed `Q`: `§Q1 Which is closer to the truth?`. Multi-paragraph questions (setup + the actual ask) count as one `§Q`; paragraphs are connective tissue, the question is the atom.

### What is not labeled

Plain prose paragraphs — transitions, mode-shift announcements ("Switching to red-team mode…"), connective text between sections. They are rarely the target of "respond to point X"; the operator can quote if needed. Labeling every paragraph would dilute the scheme.

### Numbering rules

- **Hierarchical numeric** with `§` prefix to prevent collision with in-content numbering.
- **Document order.** Counters increment top-down; sub-counters reset per parent.
- **Per-response scope.** Counters reset every turn. Labels are TOC-of-this-message, not persistent IDs across the session — the WIP file's structured ledgers (per `references/checkpoint-protocol.md`) remain the durable cross-turn references and should not compete with this.
- **Questions get a parallel counter.** `§Q1`, `§Q2` — independent of `§N` so the section count does not dilute when questions accumulate, and questions are visually easy to scan for.

### Activation

Always on. Every discover response gets labels, including a one-question turn (`§Q1 …`). Constant presence is the predictability — the operator never wonders whether this turn has addresses.

### Worked example

The synthesis excerpt from the brainstorming session would re-render as:

```
§1 POC synthesis (cross-referenced code + your narrative)

§1.1 What carries forward (worked):
- §1.1.1 Markdown-as-store with checkbox-line + indented frontmatter — …
- §1.1.2 Graph primitives in pm_data.py — …
- §1.1.3 Content-hash doc regeneration — …
- §1.1.4 A2A via synchronous Task(...) — …
- §1.1.5 Briefing as static-derived view — …

§1.2 What changes (didn't work / wasn't there):
- §1.2.1 JIT vs upfront grooming — …
- §1.2.2 One-shot task-instruction generation — …
…

§1.3 Tech-D classifications (inline, five new)
- §1.3.1 JIT decomposition → [V1] constraint. …
- §1.3.2 Multi-step task-instruction generation → [V1] constraint. …
…

§2 Status-flow tension to flag
- §2.1 Junior edits frontmatter directly. …
- §2.2 A Claude Code slash command. …
- §2.3 Overlay tool provides status-change UI. …
- §2.4 Separate, narrower agent for status mutations. …

§Q1 Was "agent-chat for status" successful because the agent did
intelligent things, or just because it was a more ergonomic shape
than editing markdown by hand?
```

The previously-ad-hoc lettered options (A/B/C/D) collapse into the §2.x scheme; the previously-numbered Tech-D items (1–5) collapse into §1.3.x. The trailing question — three paragraphs in the original — is one `§Q1`.

## Where it lives

- **New:** `plugins/discover/skills/discover/references/labeling-protocol.md` — full rules, the worked example above, edge cases.
- **SKILL.md edits:**
  1. Entry in the "Reference files" list pointing at the new file.
  2. A short always-on rule in the body, parallel in tone to how Tech-D is described as continuous: *"Every response uses the labeling protocol from `references/labeling-protocol.md` — `§X.Y.Z` inline on headings, list items, inline classifications, and questions."*

This keeps SKILL.md from bloating while making the rule unmissable to the agent at session start.

## Verification

1. **Re-render check.** Take the synthesis excerpt from the operator's prompt and re-render under the protocol (see worked example above). Confirm every point that previously felt unaddressable now has a label.
2. **Eval transcript walk.** Pick one transcript from `docs/discover-evals/iteration-2/` and walk 2-3 turns mentally through the protocol. Confirm labels would render cleanly without disrupting content, and that the per-response counter reset behaves sensibly across turn boundaries.

No code change beyond the new reference file + the two SKILL.md edits.

## Alternatives considered

- **Slug + index format (e.g. `POC.cf.3`).** Self-describing but forces the agent to coin a slug per section, which drifts inconsistently across sessions. Rejected for a mechanical numeric scheme.
- **Auto-threshold activation (labels only when the response has 2+ sections / 5+ items).** Lighter on small turns but introduces unpredictability — operator never knows whether labels will be present. Rejected in favor of always-on.
- **Inline + TOC at top of message.** TOC adds navigation value on long synthesis turns but is overhead on short ones. Rejected to keep the scheme uniformly lightweight; inline is sufficient because operators read top-down anyway.
- **Persistent IDs across turns.** Would compete with the WIP file's structured ledgers and create false impressions of stability when responses get re-drafted. Rejected.
