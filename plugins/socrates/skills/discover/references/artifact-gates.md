# Artifact-Time Gates

> Phase names and the overall flow are defined in `../SKILL.md`. This file expands the discovery-artifact write-time validation only.

Before writing the discovery artifact to `docs/socrates/discover/<slug>.md`, the agent runs two self-validation gates against the assembled draft. Any failure blocks the write and returns the agent to a fixup loop.

The gates are agent-driven self-validation in the prompt — not external tooling. The agent reads its own draft, runs the two checks, and reports its conclusions to the operator before writing.

Shape decisions, constraint provenance, parked-shape resolution, and open-axis justifications are NOT gated here — those concerns belong in `/solution`'s `solution-gates.md`. `/discover`'s artifact contains *no shapes* by design.

## Gate 1: Problem-language gate

For each line in the `## Framing` and `## Outcomes` sections of the assembled artifact draft, verify the line contains no shape-language. Shape-language includes:

- A named technology, library, framework, or product ("Postgres", "AWS", "Next.js", "Plane", "Notion").
- A protocol or pattern ("REST", "GraphQL", "event-driven", "microservices").
- An architectural choice expressed as a *how* ("monorepo", "serverless", "task graph", "JIT generation").
- A non-functional shape framing ("first-class citizen", "comprehensive", "real-time").

External systems mentioned as nouns describing the world (e.g., "users can't authenticate to our Okta tenant") are acceptable — Okta is the world, not a proposed solution. The test: does removing the word leave the sentence describing the *problem* or describing a *proposed how*?

**Fails if:** any line in Framing or Outcomes contains shape-language as a proposed how. Common pattern: an outcome phrased "users should have [shape]" or "the system should [shape]" instead of "[underlying want]."

## Gate 2: Verbatim original statement gate

The `### Original statement` subsection contains the operator's input from session start, preserved verbatim.

**Fails if:** the Original statement is paraphrased, summarized, edited, or empty. This is a mechanical check — the agent compares against the first turn in the JSONL transcript.

## Failure handling

When any gate fails, the agent does NOT write the artifact. Instead:

1. **Surface the failures to the operator** as a bulleted list, grouped by gate name:

   ```text
   Artifact gate check failed. Issues:

   Problem-language gate (1 failure):
     - Outcome "users should have a task graph" contains shape-language
       ("task graph" is a proposed how). Reframe as the underlying want.

   Cannot write artifact until these are addressed.
   ```

2. **Surface a fixup loop:** for each failure, run one more Socratic peel on the offending phrase. Common fixups:
   - Shape-language in Framing → ask: *"You wrote [phrase] in the problem statement. What is the underlying want that [phrase] is a proposed answer to?"* Replace with the underlying want.
   - Shape-language in an Outcome → same peel; re-state the outcome at the *want* level.
   - Verbatim Original statement missing or paraphrased → restore from the JSONL transcript turn 1.

3. **Re-run both gates after each fixup.**

4. **Only after both gates pass:** proceed to write the artifact to `docs/socrates/discover/<slug>.md`.

## Anti-patterns

- ❌ **Writing the artifact and then noting the failures.** Gates run BEFORE the write.
- ❌ **Treating a gate failure as advisory.** If the operator wants to override (e.g., the shape-word is genuinely the only way to phrase the world-fact), record the override explicitly in the artifact ("Note: [phrase] is a system-name, not a proposed how") and re-run gates against the override-acknowledged draft.
- ❌ **Skipping gates when the draft "looks fine."** The whole point is to catch shape-language that snuck in during dialogue.
