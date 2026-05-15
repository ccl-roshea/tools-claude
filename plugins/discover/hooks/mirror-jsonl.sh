#!/usr/bin/env bash
# Mirrors the active Claude Code session JSONL into the discovery folder
# so that long-running /discover sessions are recoverable and replayable.
#
# Reads hook JSON from stdin. Acts only if the cwd contains exactly one
# active discovery WIP file at docs/socrates/discover/.wip/<slug>.wip.md. Otherwise
# exits 0 (no-op) so the hook is safe to ship enabled by default.

set -euo pipefail

input="$(cat)"

transcript_path="$(jq -r '.transcript_path // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
session_id="$(jq -r '.session_id // empty' <<<"$input")"

[[ -z "$transcript_path" || -z "$cwd" || -z "$session_id" ]] && exit 0
[[ -f "$transcript_path" ]] || exit 0

wip_dir="$cwd/docs/socrates/discover/.wip"
[[ -d "$wip_dir" ]] || exit 0

shopt -s nullglob
wips=("$wip_dir"/*.wip.md)
if (( ${#wips[@]} != 1 )); then
  if (( ${#wips[@]} > 1 )); then
    echo "discover/mirror-jsonl: ambiguous WIP set (${#wips[@]} files in $wip_dir); skipping mirror" >&2
  fi
  exit 0
fi

slug="$(basename "${wips[0]}" .wip.md)"
dest_dir="$wip_dir/$slug"
mkdir -p "$dest_dir"

tmp="$(mktemp "$dest_dir/.${session_id}.XXXXXX")"
cp "$transcript_path" "$tmp"
mv "$tmp" "$dest_dir/${session_id}.jsonl"

# Stage the mirror into the git index so a crash leaves a recoverable,
# tracked file instead of an untracked orphan. Phase 5b's git mv of the
# whole .wip/<slug>/ directory picks the staged blob up unchanged.
mirror_path="$dest_dir/${session_id}.jsonl"
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  if ! git -C "$cwd" add -- "$mirror_path" 2>/dev/null; then
    echo "discover/mirror-jsonl: git add of $mirror_path failed; mirror is on disk but not staged" >&2
  fi
fi
