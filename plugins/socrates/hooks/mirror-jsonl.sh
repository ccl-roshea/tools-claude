#!/usr/bin/env bash
# Mirrors the active Claude Code session JSONL into the matching WIP's slug
# directory so that long-running /discover and /solution sessions are
# recoverable and replayable.
#
# Reads hook JSON from stdin. Scans both docs/socrates/discover/.wip/*.wip.md
# and docs/socrates/solution/.wip/*.wip.md, parses YAML frontmatter for a
# `session_id:` field, and acts only on the WIP whose session_id matches the
# current CC session. This disambiguates the sub-skill scenario (e.g. parent
# /solution dispatches a sub /discover; two WIPs exist concurrently with
# distinct session IDs and each hook firing must route its JSONL to the
# correct slug dir).
#
# Behavior summary (PR2 §7):
#   - 0 matching WIPs: no-op (skill hasn't created its WIP yet, or cwd has
#     no active Socrates session).
#   - 1 matching WIP: mirror current session's JSONL to that WIP's slug dir.
#   - >1 matching WIPs (collision): log warning to stderr, no-op.
#
# Safe to ship enabled by default: any unexpected condition exits 0.

set -euo pipefail

input="$(cat)"

transcript_path="$(jq -r '.transcript_path // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
session_id="$(jq -r '.session_id // empty' <<<"$input")"

[[ -z "$transcript_path" || -z "$cwd" || -z "$session_id" ]] && exit 0
[[ -f "$transcript_path" ]] || exit 0

# Extract `session_id:` from a WIP file's YAML frontmatter (the leading
# `---`-fenced block). Prints the value or nothing.
wip_session_id() {
  local file="$1"
  awk '
    BEGIN { in_fm = 0; seen = 0 }
    /^---[[:space:]]*$/ {
      if (!seen) { in_fm = 1; seen = 1; next }
      else if (in_fm) { exit }
    }
    in_fm && /^session_id:[[:space:]]*/ {
      sub(/^session_id:[[:space:]]*/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$file"
}

shopt -s nullglob
candidate_wips=(
  "$cwd"/docs/socrates/discover/.wip/*.wip.md
  "$cwd"/docs/socrates/solution/.wip/*.wip.md
)

matches=()
for wip in "${candidate_wips[@]}"; do
  [[ -f "$wip" ]] || continue
  wip_sid="$(wip_session_id "$wip")"
  if [[ -n "$wip_sid" && "$wip_sid" == "$session_id" ]]; then
    matches+=("$wip")
  fi
done

if (( ${#matches[@]} == 0 )); then
  exit 0
fi
if (( ${#matches[@]} > 1 )); then
  echo "socrates/mirror-jsonl: multiple WIPs (${#matches[@]}) match session_id=$session_id; skipping mirror" >&2
  printf '  %s\n' "${matches[@]}" >&2
  exit 0
fi

matched_wip="${matches[0]}"
wip_dir="$(dirname "$matched_wip")"
slug="$(basename "$matched_wip" .wip.md)"
dest_dir="$wip_dir/$slug"
mkdir -p "$dest_dir"

tmp="$(mktemp "$dest_dir/.${session_id}.XXXXXX")"
cp "$transcript_path" "$tmp"
mv "$tmp" "$dest_dir/${session_id}.jsonl"

# Stage the mirror into the git index so a crash leaves a recoverable,
# tracked file instead of an untracked orphan. Phase 5b's git mv of the
# whole .wip/<slug>/ directory picks the staged blob up unchanged.
# Skipped when cwd is not a git repo (the on-disk mirror still exists).
mirror_path="$dest_dir/${session_id}.jsonl"
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  if ! git -C "$cwd" add -- "$mirror_path" 2>/dev/null; then
    echo "socrates/mirror-jsonl: git add of $mirror_path failed; mirror is on disk but not staged" >&2
  fi
fi
