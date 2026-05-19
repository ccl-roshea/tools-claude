# Discovery Artifact Template

> Phase names and the overall flow are defined in `../SKILL.md`. This file expands the artifact format only.

The output document the skill writes when Socratic dialogue converges. Every discovery session produces one artifact in this format.

The artifact is *pure problem*: the refined problem statement, the outcomes that pressure-tested through dialogue, and a collapsed log of the key exchanges. Shapes, preferences, constraints, parked items, open axes, and red-team findings do NOT appear here — those are evaluable only against a validated problem and belong in `/solution`.

## Filename and location

`docs/socrates/discover/<topic-slug>.md`

`<topic-slug>` is a kebab-case identifier derived from the refined problem statement. Examples: `team-pm-bottleneck`, `auth-rotation-failure`, `cart-checkout-friction`.

## Template

```markdown
# Discovery: <problem title>

**Date:** YYYY-MM-DD
**Status:** Discovery complete, ready for /solution

## Framing

<The refined problem statement — what survived Socratic dialogue.
2–4 sentences. Problem-language only; no shapes, no how, no proposed
solutions. State *what* the problem is, not *how* to address it.>

### Original statement
> <verbatim operator input, preserved for reference>

### Key reframes
- <what changed from the original statement and why>

## Outcomes

The pressure-tested outcomes the operator wants. Each outcome is a *what*, not a *how*.

- <outcome 1 — 1-2 sentences>
- <outcome 2 — 1-2 sentences>
- ...

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

Key exchanges that shaped the framing, preserved for context if
someone revisits this artifact later.

- **Q:** <question asked>
  **A:** <operator answer>
  **Impact:** <how this changed the framing>

- **Q:** ...
  **A:** ...
  **Impact:** ...

</details>
```

## Section-by-section guidance

### Header

`Status` is always "Discovery complete, ready for /solution" at write time.

### Framing

The refined problem statement is *not* a paraphrase of the operator's input. It's what survived Socratic dialogue — usually significantly different from the original statement. The original statement is preserved separately for reference. Key reframes lists the deltas: what changed and why.

The Framing section MUST be problem-language only. No named tools, patterns, technologies, frameworks, protocols, or architectural choices. If the operator's refined problem genuinely references an external system (e.g., "users can't authenticate to our Okta tenant"), the system name is acceptable as a noun describing the world — not as a proposed solution.

### Outcomes

Concrete *what* statements. Each outcome is something the operator wants to be true. No shapes. If an outcome is phrased as "we should X," rewrite as "X is the case." If it can't be phrased without naming a tool/pattern/technology, it isn't an outcome yet — it's a shape preference and belongs in `/solution`.

### Discovery log

Collapsed by default. `/solution` doesn't need to read it; the human who returns weeks later does — to understand why the framing landed where it did. Include only key exchanges (the ones that changed the framing), not the full transcript. The full JSONL transcript lives in the `.wip` directory and is finalized alongside the artifact at write time.

## When the template feels heavy

For very simple problems, the template can feel oversized. Don't shortcut it. The consistency is the point — operators and `/solution` always know where to find what. A simple problem just has shorter sections.

If a section truly has nothing in it, write `None` rather than deleting the section. Example:

```markdown
### Key reframes

None — the operator's original statement survived Socratic dialogue unchanged.
```
