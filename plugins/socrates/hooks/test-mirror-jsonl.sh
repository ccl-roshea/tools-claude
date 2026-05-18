#!/usr/bin/env bash
# Smoke test for plugins/socrates/hooks/mirror-jsonl.sh
#
# Covers PR2 §7 behavior: hook must read the current CC session_id from its
# stdin JSON payload and match it against the `session_id:` field in YAML
# frontmatter of WIP files under either docs/socrates/discover/.wip/ or
# docs/socrates/solution/.wip/. Only the matching slug's dir receives the
# JSONL mirror. This disambiguates the sub-skill case where /solution
# dispatches a sub-/discover and two WIPs exist simultaneously in different
# subdirs with distinct session IDs.
#
# Session-id source assumption: Claude Code already provides session_id in
# the hook's stdin JSON payload (see the existing mirror-jsonl.sh and the
# `session_id:$s` field set by the PASSing baseline test). No env-var
# mechanism is needed; the hook simply needs to (a) read session_id from
# stdin (already does) and (b) cross-check it against WIP frontmatter
# instead of relying on "exactly one WIP in cwd".

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook="$script_dir/mirror-jsonl.sh"

# Track all tempdirs so the trap can clean every case, even on failure.
# Use a single parent dir so cleanup is one rm -rf, avoiding subshell-array
# pitfalls (mk_tmp runs inside $(...) and cannot mutate a parent-shell array).
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mk_tmp() {
  local d
  d="$(mktemp -d -p "$TMP_ROOT")"
  git -C "$d" init -q
  git -C "$d" config user.email test@example.com
  git -C "$d" config user.name test
  echo "$d"
}

# Write a WIP file with `session_id: <id>` in YAML frontmatter, per the
# PR2 §7 contract (Phase 0 / SHAPE-DISCOVER stamp the session_id at WIP
# creation time).
write_wip() {
  local path="$1" sid="$2"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<EOF
---
session_id: $sid
---
# WIP
EOF
}

drive_hook() {
  local transcript="$1" cwd="$2" sid="$3"
  local payload
  payload="$(jq -n \
    --arg t "$transcript" \
    --arg c "$cwd" \
    --arg s "$sid" \
    '{transcript_path:$t, cwd:$c, session_id:$s}')"
  echo "$payload" | bash "$hook"
}

fake_transcript() {
  local cwd="$1" sid="$2"
  local path="$cwd/.fake-cc/$sid.jsonl"
  mkdir -p "$(dirname "$path")"
  printf '{"turn":1}\n{"turn":2}\n' >"$path"
  echo "$path"
}

# --- Case 1: single /discover WIP whose frontmatter session_id matches. ---
case1() {
  local tmp sid transcript expected
  tmp="$(mk_tmp)"
  sid="sess-discover-001"
  write_wip "$tmp/docs/socrates/discover/.wip/foo.wip.md" "$sid"
  transcript="$(fake_transcript "$tmp" "$sid")"

  drive_hook "$transcript" "$tmp" "$sid"

  expected="$tmp/docs/socrates/discover/.wip/foo/$sid.jsonl"
  if [[ ! -f "$expected" ]]; then
    echo "FAIL (case 1): mirror not created at $expected" >&2
    return 1
  fi
  if ! cmp -s "$transcript" "$expected"; then
    echo "FAIL (case 1): mirror contents differ from source transcript" >&2
    return 1
  fi
  local staged
  staged="$(git -C "$tmp" diff --cached --name-only)"
  if ! grep -qx "docs/socrates/discover/.wip/foo/$sid.jsonl" <<<"$staged"; then
    echo "FAIL (case 1): expected staged file missing, got:" >&2
    echo "$staged" >&2
    return 1
  fi
  echo "case 1 PASS"
}

# --- Case 2: single /solution WIP whose frontmatter session_id matches. ---
case2() {
  local tmp sid transcript expected
  tmp="$(mk_tmp)"
  sid="sess-solution-002"
  write_wip "$tmp/docs/socrates/solution/.wip/bar.wip.md" "$sid"
  transcript="$(fake_transcript "$tmp" "$sid")"

  drive_hook "$transcript" "$tmp" "$sid"

  expected="$tmp/docs/socrates/solution/.wip/bar/$sid.jsonl"
  if [[ ! -f "$expected" ]]; then
    echo "FAIL (case 2): mirror not created at $expected" >&2
    return 1
  fi
  if ! cmp -s "$transcript" "$expected"; then
    echo "FAIL (case 2): mirror contents differ from source transcript" >&2
    return 1
  fi
  local staged
  staged="$(git -C "$tmp" diff --cached --name-only)"
  if ! grep -qx "docs/socrates/solution/.wip/bar/$sid.jsonl" <<<"$staged"; then
    echo "FAIL (case 2): expected staged file missing, got:" >&2
    echo "$staged" >&2
    return 1
  fi
  echo "case 2 PASS"
}

# --- Case 3: sub-skill scenario. Two WIPs exist concurrently. The current
# session is the /solution parent; only the /solution slug dir must receive
# the mirror. The /discover slug dir (owned by the sub-skill's own session)
# must NOT receive this session's JSONL. ---
case3() {
  local tmp sid_parent sid_sub transcript
  tmp="$(mk_tmp)"
  sid_parent="sess-solution-parent-003"
  sid_sub="sess-discover-sub-003"
  write_wip "$tmp/docs/socrates/discover/.wip/sub.wip.md" "$sid_sub"
  write_wip "$tmp/docs/socrates/solution/.wip/parent.wip.md" "$sid_parent"
  transcript="$(fake_transcript "$tmp" "$sid_parent")"

  drive_hook "$transcript" "$tmp" "$sid_parent"

  local expected_solution="$tmp/docs/socrates/solution/.wip/parent/$sid_parent.jsonl"
  local forbidden_discover="$tmp/docs/socrates/discover/.wip/sub/$sid_parent.jsonl"
  local forbidden_discover_dir="$tmp/docs/socrates/discover/.wip/sub"

  if [[ ! -f "$expected_solution" ]]; then
    echo "FAIL (case 3): /solution mirror not created at $expected_solution" >&2
    return 1
  fi
  if ! cmp -s "$transcript" "$expected_solution"; then
    echo "FAIL (case 3): /solution mirror contents differ from source" >&2
    return 1
  fi
  if [[ -f "$forbidden_discover" ]]; then
    echo "FAIL (case 3): parent session JSONL leaked into /discover sub slug at $forbidden_discover" >&2
    return 1
  fi
  # The /discover slug dir may or may not exist (hook should not create it
  # for a non-matching WIP). If it exists, it must contain no jsonl files
  # bearing the parent session id.
  if [[ -d "$forbidden_discover_dir" ]]; then
    if compgen -G "$forbidden_discover_dir"/*.jsonl >/dev/null; then
      echo "FAIL (case 3): /discover sub slug dir contains jsonl files; should be untouched by parent session" >&2
      ls -la "$forbidden_discover_dir" >&2
      return 1
    fi
  fi
  local staged
  staged="$(git -C "$tmp" diff --cached --name-only)"
  if ! grep -qx "docs/socrates/solution/.wip/parent/$sid_parent.jsonl" <<<"$staged"; then
    echo "FAIL (case 3): expected /solution staged file missing, got:" >&2
    echo "$staged" >&2
    return 1
  fi
  if grep -qx "docs/socrates/discover/.wip/sub/$sid_parent.jsonl" <<<"$staged"; then
    echo "FAIL (case 3): parent session JSONL incorrectly staged under /discover sub slug" >&2
    return 1
  fi
  echo "case 3 PASS"
}

# --- Case 4: no WIP anywhere. Hook is a no-op (exit 0, no files created). ---
case4() {
  local tmp sid transcript
  tmp="$(mk_tmp)"
  sid="sess-orphan-004"
  # Deliberately do not create any .wip/ dirs or WIP files.
  transcript="$(fake_transcript "$tmp" "$sid")"

  drive_hook "$transcript" "$tmp" "$sid"

  # Nothing should have been mirrored or staged anywhere under docs/.
  if [[ -d "$tmp/docs" ]]; then
    if find "$tmp/docs" -name '*.jsonl' -print -quit | grep -q .; then
      echo "FAIL (case 4): hook created a mirror despite no WIP present" >&2
      find "$tmp/docs" -type f >&2
      return 1
    fi
  fi
  local staged
  staged="$(git -C "$tmp" diff --cached --name-only)"
  if [[ -n "$staged" ]]; then
    echo "FAIL (case 4): hook staged something despite no WIP present:" >&2
    echo "$staged" >&2
    return 1
  fi
  echo "case 4 PASS"
}

case1
case2
case3
case4

echo "PASS"
