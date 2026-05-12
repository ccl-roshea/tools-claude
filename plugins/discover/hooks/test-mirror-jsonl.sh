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
