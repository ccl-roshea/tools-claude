# Response labeling protocol

Every `/discover` response uses this addressing scheme so the operator can target any specific point in a reply.

## Format

- **Sections and sub-sections:** `§N`, `§N.M`, `§N.M.K`, … — hierarchical numeric (depth follows document structure, capped at four levels per the Edge cases), prefixed with `§`.
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
| Inline Tech-D classification line | Yes — gets its own `§N.M.K` address when on its own line |
| Question to the operator | Yes — separate counter `§Q1`, `§Q2` |
| Plain prose paragraph (transition, mode-shift announcement, connective text) | No |
| Code block | No — rendered content within a parent address |
| Horizontal rule (`---`) | No — separator |
| Block quote | Yes — gets its own `§N.M.K` address when it stands as a distinct addressable unit (not when it merely quotes within a larger bullet) |

**Depth follows the document tree, not the element type.** A bullet directly under section `§1` is `§1.1`. A sub-heading under `§1` is also `§1.1`, and a bullet inside that sub-heading is `§1.1.1`. The address says where the item sits, not what kind of item it is.

## Numbering rules

1. **Document order.** Counters increment top-down; sub-counters reset per parent section.
2. **Per-response scope.** Counters reset every turn. Labels are TOC-of-this-message, not persistent IDs across the session. The WIP file's structured ledgers (per `checkpoint-protocol.md`) remain the durable cross-turn references.
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
- **Tables.** Address each row separately when the operator might want to discuss or modify a single row in isolation (e.g., a comparison matrix of options). Address the whole table as one item when rows are jointly meaningful and not separately actionable (e.g., a key-value reference table). When in doubt, prefer the whole-table address — granular row addresses can be added later if asked for.
- **Answer-option bullets under a question.** When a single question is followed by a bulleted list of answer choices the operator picks from, address the choices as sub-parts of the question: `§Q1.1`, `§Q1.2`, etc. (not as `§1`, `§2` content). This keeps the operator's "answer §Q1.2" unambiguous and ties the choices to the question they belong to.
- **Prose-introduced lists.** When a prose paragraph introduces a list (e.g., "Here are four ways to think about this:" followed by 4 items), treat the introducing prose as a virtual section heading. The list items become `§1.1`–`§1.N` under that virtual section, not top-level `§1`–`§N`. This keeps the address space hierarchical and lets you reference the introducing context separately from the items.
- **Inline classification that is also the question.** When a Tech-D probe is the same line as a question to the operator (e.g., "What's the external source for `Claude Code` — is there a regulator, contract, deployed system, prior empirical result, or factual measurement that mandates it?"), address it once as `§Q`, not twice. The question framing is load-bearing; the classification framing is descriptive of what the agent is doing.

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
