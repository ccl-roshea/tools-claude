# Discover mirror — crash-resilience via index-stage

## Problem

When the host machine crashes mid-discover-session, the JSONL transcript mirrored by `plugins/discover/hooks/mirror-jsonl.sh` ends up as an untracked file at `docs/discovery/.wip/<slug>/<session-id>.jsonl`. The discover skill's Phase 5b commits everything together via `git mv docs/discovery/.wip/<slug> docs/discovery/<slug>`, but between mirror copies and Phase 5b the JSONL has no git presence. A crash therefore leaves an orphan file that the user must notice and stage by hand before `/discover resume` can work cleanly.

The current `mirror-jsonl.sh` already fires on every `Stop` and `SessionEnd`, so the per-turn copy is in place. What's missing is making each copy *visible to git* between turns, without polluting `main` with per-turn snapshot commits.

## Goal

After every assistant turn, the JSONL mirror should be a tracked, indexed object so that:

- A crash leaves an obvious, recoverable state — `git status` shows the JSONL staged for commit.
- Phase 5b's existing `git mv` + commit ritual continues to work unchanged.
- No per-turn commits land on the working branch.

## Non-goals

- Per-turn commits to `main` (or any branch).
- Orphan-branch / separate-repo transcript archives.
- Detecting promotion events from inside the hook.
- Touching `SKILL.md` finalize logic.

## Design

One file change: `plugins/discover/hooks/mirror-jsonl.sh`. After the existing atomic `cp` → `mv` of the JSONL, add a `git add` of that exact path.

```
CC turn ends
  └─ Stop hook fires
       └─ mirror-jsonl.sh
            ├─ read stdin (transcript_path, cwd, session_id)
            ├─ guard: exactly one .wip.md in $cwd/docs/discovery/.wip/
            ├─ atomic cp+mv → docs/discovery/.wip/<slug>/<session-id>.jsonl
            └─ NEW: git -C "$cwd" add -- docs/discovery/.wip/<slug>/<session-id>.jsonl
```

Roughly three added lines, wrapped in a guard that no-ops if `git` is absent or `$cwd` isn't a worktree.

### Why this fixes the crash gap

Today the JSONL is untracked between Phase 5b commits. Staging it on every turn makes it a tracked blob in the index. After a crash the user gets:

- A working-tree file on disk (as before).
- An index entry pointing at the same blob (NEW) — surfaced in `git status` as "staged for commit."

`/discover resume <slug>` then has both the WIP markdown (committed at phase boundaries) and the JSONL (in the index) available with no manual recovery.

### Error handling

- Wrap `git add` so failures write to stderr and `exit 0`. The hook must never block CC; the file is still on disk if staging fails.
- Use `git -C "$cwd"` so the operation does not depend on script cwd.
- Skip the `git add` entirely if `git -C "$cwd" rev-parse --git-dir` fails (not a worktree).
- Pre-commit hook collision is not a concern: `git add` does not invoke pre-commit hooks; only `git commit` does.

### Known caveats

- **Staged-file leak:** if the user runs `git commit` (no path args) for unrelated work during a discover session, the staged JSONL rides along. Mitigation: the discover workflow already discourages mid-session unrelated commits; documented as a known limit. A pre-commit warning could be added later; out of scope.
- **Multiple sessions in same WIP:** the existing script already bails if there are 0 or 2+ `.wip.md` files, so behavior stays consistent.

## Testing

- **Static:** shellcheck pass on the modified script.
- **Manual smoke:**
  1. In a test repo with `docs/discovery/.wip/test.wip.md`, trigger a CC `Stop`. Verify `git status` shows the JSONL as staged.
  2. Kill CC abruptly (`kill -9`) mid-turn. Re-run `git status`. Verify the JSONL from the prior `Stop` is still staged.
  3. Run a mock Phase 5b: `git mv docs/discovery/.wip/test docs/discovery/test && git rm docs/discovery/.wip/test.wip.md && git commit`. Verify the JSONL is in the resulting commit.
- **Idempotency:** run the hook twice on the same transcript; `git add` of an unchanged path is a no-op.

## Alternatives considered

- **Detect-and-commit hook:** a `PostToolUse` hook detects the promotion event and runs the commit, removing Phase 5b's manual step. Bigger refactor; reshuffles the finalize ritual. Rejected as over-scoped.
- **Commit-on-`SessionEnd`:** simplest cadence but `SessionEnd` does not fire on crashes — the exact failure mode this design targets. Rejected.
- **Per-turn commits to orphan branch:** clean isolation from `main` history but introduces a parallel branch users must remember. Rejected after the user opted for a single commit at promotion.
