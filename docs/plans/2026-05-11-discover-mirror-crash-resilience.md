# Discover Mirror Crash-Resilience Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the discover-plugin JSONL mirror crash-resilient by staging each per-turn snapshot into the git index, so a crashed session leaves a tracked, recoverable file instead of an untracked orphan.

**Architecture:** Modify the existing `Stop`-fired hook `plugins/discover/hooks/mirror-jsonl.sh` to run `git add` on the mirrored JSONL after the atomic `cp+mv`. No new hooks, no `SKILL.md` change. Design rationale and alternatives are in `docs/plans/2026-05-11-discover-mirror-crash-resilience-design.md`.

**Tech Stack:** Bash, jq, git, shellcheck. Self-contained Bash smoke test (no test framework dependency).

---

### Task 1: Write the failing smoke test

**Files:**
- Create: `plugins/discover/hooks/test-mirror-jsonl.sh`

**Step 1: Write the test script**

```bash
#!/usr/bin/env bash
# Smoke test for plugins/discover/hooks/mirror-jsonl.sh
# Runs in a throwaway tempdir; verifies the hook copies AND stages the JSONL.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$script_dir/mirror-jsonl.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Set up a fake project repo
git -C "$tmp" init -q
git -C "$tmp" config user.email test@example.com
git -C "$tmp" config user.name test

# Set up the discovery WIP state the hook expects
mkdir -p "$tmp/docs/discovery/.wip"
echo "# WIP" >"$tmp/docs/discovery/.wip/foo.wip.md"

# Fake CC transcript (lives outside the project, like the real one)
transcript="$tmp/.fake-cc/abc123.jsonl"
mkdir -p "$(dirname "$transcript")"
printf '{"turn":1}\n{"turn":2}\n' >"$transcript"

# Drive the hook
payload="$(jq -n \
  --arg t "$transcript" \
  --arg c "$tmp" \
  --arg s "abc123" \
  '{transcript_path:$t, cwd:$c, session_id:$s}')"
echo "$payload" | bash "$hook"

# Assert 1: the JSONL was copied to the expected path
mirror="$tmp/docs/discovery/.wip/foo/abc123.jsonl"
if [[ ! -f "$mirror" ]]; then
  echo "FAIL: mirror file not created at $mirror" >&2
  exit 1
fi
if ! cmp -s "$transcript" "$mirror"; then
  echo "FAIL: mirror contents differ from source transcript" >&2
  exit 1
fi

# Assert 2: the JSONL is staged in the git index
staged="$(git -C "$tmp" diff --cached --name-only)"
expected="docs/discovery/.wip/foo/abc123.jsonl"
if ! grep -qx "$expected" <<<"$staged"; then
  echo "FAIL: expected $expected in git index, got:" >&2
  echo "$staged" >&2
  exit 1
fi

echo "PASS"
```

**Step 2: Make it executable**

Run: `chmod +x plugins/discover/hooks/test-mirror-jsonl.sh`

**Step 3: Run the test to verify it fails**

Run: `bash plugins/discover/hooks/test-mirror-jsonl.sh`
Expected: exits non-zero with `FAIL: expected docs/discovery/.wip/foo/abc123.jsonl in git index, got:` (empty staged list). Assert 1 passes because the existing script already copies; Assert 2 fails because the script does not yet stage.

**Step 4: Commit the failing test**

```bash
git add plugins/discover/hooks/test-mirror-jsonl.sh
git commit -m "test(discover): add smoke test for mirror-jsonl staging"
```

---

### Task 2: Implement the `git add` step

**Files:**
- Modify: `plugins/discover/hooks/mirror-jsonl.sh` (append after line 38)

**Step 1: Edit `mirror-jsonl.sh`**

Append after `mv "$tmp" "$dest_dir/${session_id}.jsonl"`:

```bash

# Stage the mirror into the git index so a crash leaves a recoverable,
# tracked file instead of an untracked orphan. Phase 5b's git mv of the
# whole .wip/<slug>/ directory picks the staged blob up unchanged.
mirror_path="$dest_dir/${session_id}.jsonl"
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  if ! git -C "$cwd" add -- "$mirror_path" 2>/dev/null; then
    echo "discover/mirror-jsonl: git add of $mirror_path failed; mirror is on disk but not staged" >&2
  fi
fi
```

Note: the `2>/dev/null` on `git add` suppresses the routine "path is ignored by .gitignore" message in case a user has gitignored `.wip/`. The stderr branch handles harder failures (locked index, repo corruption).

**Step 2: Run shellcheck**

Run: `shellcheck plugins/discover/hooks/mirror-jsonl.sh`
Expected: no warnings.

**Step 3: Run the test to verify it passes**

Run: `bash plugins/discover/hooks/test-mirror-jsonl.sh`
Expected: `PASS`.

**Step 4: Commit**

```bash
git add plugins/discover/hooks/mirror-jsonl.sh
git commit -m "feat(discover): stage JSONL mirror in git index after each Stop"
```

---

### Task 3: Add a non-git-repo guard test

**Files:**
- Modify: `plugins/discover/hooks/test-mirror-jsonl.sh` (append a second test case)

**Step 1: Append the test case**

Before the final `echo "PASS"` line, add:

```bash

# --- Case 2: cwd is not a git repo. Hook should still copy, not crash. ---
tmp2="$(mktemp -d)"
trap 'rm -rf "$tmp" "$tmp2"' EXIT

mkdir -p "$tmp2/docs/discovery/.wip"
echo "# WIP" >"$tmp2/docs/discovery/.wip/bar.wip.md"
transcript2="$tmp2/.fake-cc/def456.jsonl"
mkdir -p "$(dirname "$transcript2")"
printf '{"turn":1}\n' >"$transcript2"

payload2="$(jq -n \
  --arg t "$transcript2" \
  --arg c "$tmp2" \
  --arg s "def456" \
  '{transcript_path:$t, cwd:$c, session_id:$s}')"
echo "$payload2" | bash "$hook"

mirror2="$tmp2/docs/discovery/.wip/bar/def456.jsonl"
if [[ ! -f "$mirror2" ]]; then
  echo "FAIL (case 2): mirror file not created in non-git cwd" >&2
  exit 1
fi
```

**Step 2: Run the full test**

Run: `bash plugins/discover/hooks/test-mirror-jsonl.sh`
Expected: `PASS`.

**Step 3: Commit**

```bash
git add plugins/discover/hooks/test-mirror-jsonl.sh
git commit -m "test(discover): cover non-git cwd path in mirror-jsonl test"
```

---

### Task 4: Final verification

**Step 1: Run shellcheck on both scripts**

Run: `shellcheck plugins/discover/hooks/mirror-jsonl.sh plugins/discover/hooks/test-mirror-jsonl.sh`
Expected: no warnings.

**Step 2: Run the smoke test one more time**

Run: `bash plugins/discover/hooks/test-mirror-jsonl.sh`
Expected: `PASS`.

**Step 3: Inspect the diff**

Run: `git log --oneline -3`
Expected: three commits — failing-test, implementation, non-git-guard test.

**Step 4: Sanity-check the script reads cleanly**

Run: `cat plugins/discover/hooks/mirror-jsonl.sh`
Expected: the new staging block sits cleanly after the existing atomic mv; the file is still under ~50 lines.

---

## Notes for the executor

- **No `SKILL.md` change is needed.** Phase 5b's `git mv docs/discovery/.wip/<slug> docs/discovery/<slug>` already picks up the staged blob — it just renames the index entry instead of creating one from scratch.
- **No `hooks.json` change is needed.** The hook is already wired to `Stop` and `SessionEnd`.
- **Do not add per-turn commits.** The user explicitly chose to commit once at promotion (Phase 5b). The job of this change is only to make the JSONL tracked between turns.
- **Idempotency:** `git add` on an unchanged path is a no-op, so running the hook twice in a row on the same transcript adds no churn.
