# Discover Response Labeling Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make every `/discover` response addressable by inline `§X.Y.Z` labels on every heading, sub-heading, list item, and inline classification, plus a parallel `§Q1`/`§Q2` counter for questions to the operator. The operator can then target any specific point with "address §1.2.3" instead of "address the second bullet under that section."

**Architecture:** Add one new reference file `plugins/discover/skills/discover/references/labeling-protocol.md` containing the full rules + a worked example, then make two small `SKILL.md` edits — a list entry and a new always-on section. No code changes; the protocol is descriptive instruction for the agent, parallel in shape to the existing continuous Tech-D rule. Design rationale and alternatives are in `docs/plans/2026-05-14-discover-response-labeling-design.md`.

**Tech Stack:** Markdown only. No build, no tests, no scripts.

---

### Task 1: Create the labeling-protocol reference file

**Files:**
- Create: `plugins/discover/skills/discover/references/labeling-protocol.md`

**Step 1: Write the file**

Create `plugins/discover/skills/discover/references/labeling-protocol.md` with this exact content:

````markdown
# Response labeling protocol

Every `/discover` response uses this addressing scheme so the operator can target any specific point in a reply.

## Format

- **Sections and sub-sections:** `§N`, `§N.M`, `§N.M.K` — hierarchical numeric, prefixed with `§`.
- **Questions to the operator:** `§Q1`, `§Q2` — parallel counter, prefixed `Q`.

The `§` prefix prevents collision with in-content numbering (numbered list items, lettered options).

## What gets labeled

| Element | Labeled? |
|---|---|
| Top-level section heading | Yes — `§N` |
| Sub-heading | Yes — `§N.M`, `§N.M.K` |
| Bullet inside a section | Yes — `§N.M.K` |
| Numbered list item | Yes — `§N.M.K` (the `§` address replaces any inline `1.`/`2.`) |
| Lettered option (A./B./C.) | Yes — collapse into `§N.M.K` numerics |
| Inline Tech-D classification line | Yes — addressable as the bullet/section it appears in |
| Question to the operator | Yes — separate counter `§Q1`, `§Q2` |
| Plain prose paragraph (transition, mode-shift announcement, connective text) | No |
| Code block | No — rendered content within a parent address |
| Horizontal rule (`---`) | No — separator |
| Block quote | Yes — labeled as the bullet/paragraph it stands in for |

## Numbering rules

1. **Document order.** Counters increment top-down; sub-counters reset per parent section.
2. **Per-response scope.** Counters reset every turn. Labels are TOC-of-this-message, not persistent IDs across the session. The WIP file's structured ledgers (per `references/checkpoint-protocol.md`) remain the durable cross-turn references.
3. **Parallel question counter.** `§Q1`, `§Q2` are independent of `§N` so the section count does not dilute when questions accumulate, and questions are visually easy to scan for.
4. **Multi-paragraph questions count as one `§Q`.** Setup paragraphs, conditional guidance ("if A → B; if X → Y"), and the actual ask collapse into a single `§Q`. The question is the atom.
5. **Always on.** Every response gets labels — including a one-question turn (`§Q1 …`). Predictability is the point; the operator never wonders whether labels are present.

## Placement

The label sits inline at the start of the addressable line:

- Headings: `## §1 POC synthesis`
- Bullets: `- §1.1.1 Markdown-as-store with checkbox-line...`
- Questions: `§Q1 Which is closer to the truth?`

Do not put labels in a separate column or in an end-of-message TOC.

## Edge cases

- **Existing in-content numbering.** When the content already uses `1.`, `2.`, or A./B./C. options, the `§` address replaces it. Do not double-label; pick the `§` scheme.
- **Nested bullets.** Each level adds a digit: top bullet `§1.1.1`, its sub-bullet `§1.1.1.1`. Limit to four levels deep; deeper structures usually want flattening.
- **Single-section responses with no enclosing heading.** If the entire response is just bullets with no parent heading, address them directly: `§1`, `§2`, `§3` for the bullets themselves.
- **Tables.** Treat each row as an addressable item only if rows are independent points the operator might target; otherwise the table gets one address.

## Worked example

Original synthesis (as it appeared without labels):

```
POC synthesis (cross-referenced code + your narrative)

What carries forward (worked):
- Markdown-as-store with checkbox-line + indented frontmatter — ...
- Graph primitives in pm_data.py — ...
...

Tech-D classifications (inline, five new)
1. JIT decomposition → [V1] constraint. ...
2. Multi-step task-instruction generation → [V1] constraint. ...
...

Status-flow tension to flag
- A. Junior edits frontmatter directly. ...
- B. A Claude Code slash command. ...
...

Which is closer to the truth?
```

Re-rendered under the protocol:

```
§1 POC synthesis (cross-referenced code + your narrative)

§1.1 What carries forward (worked):
- §1.1.1 Markdown-as-store with checkbox-line + indented frontmatter — ...
- §1.1.2 Graph primitives in pm_data.py — ...
...

§1.2 Tech-D classifications (inline, five new)
- §1.2.1 JIT decomposition → [V1] constraint. ...
- §1.2.2 Multi-step task-instruction generation → [V1] constraint. ...
...

§2 Status-flow tension to flag
- §2.1 Junior edits frontmatter directly. ...
- §2.2 A Claude Code slash command. ...
...

§Q1 Which is closer to the truth?
```

Notes on the transformation:

- The previously-numbered Tech-D items (1–5) collapse into `§1.2.1`–`§1.2.5`.
- The previously-lettered status-flow options (A–D) collapse into `§2.1`–`§2.4`.
- The trailing question — three paragraphs of setup + conditional + ask in the original — is a single `§Q1`.
````

**Step 2: Verify the file reads cleanly**

Run: `cat plugins/discover/skills/discover/references/labeling-protocol.md | head -20`
Expected: header + Format section visible, no truncation.

Run: `wc -l plugins/discover/skills/discover/references/labeling-protocol.md`
Expected: ~95–110 lines.

**Step 3: Commit**

```bash
git add plugins/discover/skills/discover/references/labeling-protocol.md
git commit -m "docs(discover): add response labeling protocol reference"
```

---

### Task 2: Wire the labeling protocol into SKILL.md

**Files:**
- Modify: `plugins/discover/skills/discover/SKILL.md` (one entry inserted at line 45-ish; one new section inserted between line 47 and line 49)

**Step 1: Add the reference-file list entry**

In `plugins/discover/skills/discover/SKILL.md`, find the Reference files list (currently lines 40–45). Append one new entry as the last list item, after the existing `references/checkpoint-protocol.md` line:

```markdown
- `references/labeling-protocol.md` — addressable `§X.Y.Z` labels for every response
```

The list should now have seven entries instead of six.

**Step 2: Add the always-on labeling section**

In the same file, insert a new top-level section between the existing `## Reference files` block (which ends at line 47 with the line `You should read these on demand, not all at once at session start.`) and the existing `## The seven phases` heading (currently line 49).

Insert this exact block (with one blank line above the `## Response labeling` heading and one blank line below the closing paragraph):

```markdown
## Response labeling

Every response uses the labeling protocol from `references/labeling-protocol.md` — `§X.Y.Z` inline on section headings, sub-headings, list items, and inline classifications; `§Q1`, `§Q2` for questions to the operator. Always on, including one-question turns.

This is the one reference file you should read once at session start (it is short) rather than on demand — the protocol applies to every response from turn 1 onward.
```

**Step 3: Verify the edits read cleanly**

Run: `sed -n '36,60p' plugins/discover/skills/discover/SKILL.md`
Expected:
- The `## Reference files` list now contains seven entries (last one is `labeling-protocol.md`).
- A new `## Response labeling` section sits between `## Reference files` and `## The seven phases`.
- No accidental duplicate headings, no broken list spacing.

Run: `grep -n '^## ' plugins/discover/skills/discover/SKILL.md | head`
Expected: the `## Response labeling` entry appears between `## Reference files` and `## The seven phases`.

**Step 4: Commit**

```bash
git add plugins/discover/skills/discover/SKILL.md
git commit -m "docs(discover): wire labeling protocol into SKILL.md"
```

---

### Task 3: Verification

No automated test exists for skill prose. Verification is two cross-checks the executor performs by hand and writes up.

**Step 1: Re-render check**

Open the design doc's worked example:

Run: `sed -n '/Worked example/,/Alternatives considered/p' docs/plans/2026-05-14-discover-response-labeling-design.md`

Confirm:
- Every bullet in the original synthesis would now have a `§N.M.K` address.
- The trailing 3-paragraph question collapses to one `§Q1`.
- The lettered options (A–D) and numbered items (1–5) from the original are absorbed into the `§` scheme rather than left as parallel labels.

If any of those three checks fail, return to the protocol file and tighten the rules.

**Step 2: Eval transcript walk**

Open one real eval transcript:

Run: `wc -l docs/discover-evals/iteration-2/eval-1-vague-agents/with_skill/outputs/transcript.md`

Then read the first 3 assistant turns (use `Read` with `limit: 200`). For each turn, mentally apply the protocol and answer:

1. Would the labels render cleanly without disrupting content?
2. Are there ambiguous cases the protocol does not cover? (If yes, list them and update the edge-cases section in `labeling-protocol.md`.)
3. Does the per-response counter reset feel sensible, or does the operator lose useful context across turn boundaries? (If the latter, the design has a flaw — surface it before declaring done.)

**Step 3: Verify the working tree is clean and the three commits land cleanly**

Run: `git log --oneline -3`
Expected: three commits — design doc (already on `main`), protocol reference file, SKILL.md wiring.

Run: `git status`
Expected: clean working tree.

**Step 4: No commit for the verification step itself.** The verification is a read-only cross-check; if it passes, nothing to commit. If it surfaces a fix, fold the fix into a follow-up commit on `references/labeling-protocol.md` with message `docs(discover): tighten labeling protocol after eval walk`.

---

## Notes for the executor

- **No code change.** This plan is entirely Markdown. Do not introduce scripts, tests, or hooks.
- **Do not edit any other reference files** in `plugins/discover/skills/discover/references/`. The labeling protocol is a peer; it does not modify Tech-B/C/D, chunking, research, dispatch, or checkpoint protocols.
- **Do not add a TOC at the top of responses.** The design explicitly chose inline-only labels; adding a TOC is out of scope.
- **Do not bake activation thresholds in.** The protocol is always on. If during the eval walk you find the always-on rule painful on tiny responses, surface that as a finding rather than silently introducing a threshold.
- **Existing /discover sessions in flight.** This change takes effect from the next session start. Mid-session resumes will pick up the new protocol on their next assistant turn; there is no migration of prior turns' content.
