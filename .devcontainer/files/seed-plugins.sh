#!/bin/sh
# Seed Claude Code plugins from the host plugin registry into the container.
# Idempotent and best-effort: failures are logged but never abort container
# creation. Reads two JSON files mounted read-only at /run/host-claude/plugins/
# (paths overridable via $INSTALLED / $KNOWN for unit testing).

set -u

INSTALLED="${INSTALLED:-/run/host-claude/plugins/installed_plugins.json}"
KNOWN="${KNOWN:-/run/host-claude/plugins/known_marketplaces.json}"

if ! [ -s "$INSTALLED" ]; then
  echo "seed-plugins: no host plugin registry at $INSTALLED; skipping" >&2
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "seed-plugins: jq not available; skipping" >&2
  exit 0
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "seed-plugins: claude CLI not available; skipping" >&2
  exit 0
fi

# Marketplaces actually referenced by installed plugins.
markets=$(jq -r '.plugins // {} | keys[] | split("@")[1] // empty' "$INSTALLED" \
            | sort -u)

for m in $markets; do
  if ! [ -s "$KNOWN" ]; then
    echo "seed-plugins: no known_marketplaces.json; cannot resolve '$m'" >&2
    continue
  fi
  source_repo=$(jq -r --arg m "$m" '.[$m].source.repo // empty' "$KNOWN")
  if [ -z "$source_repo" ]; then
    echo "seed-plugins: no source for marketplace '$m'; skipping" >&2
    continue
  fi
  echo "seed-plugins: adding marketplace $m ($source_repo)" >&2
  claude plugin marketplace add "$source_repo" \
    || echo "seed-plugins: failed to add marketplace $m; continuing" >&2
done

# Install each plugin, in name@marketplace form (matches the JSON keys).
jq -r '.plugins // {} | keys[]' "$INSTALLED" | while IFS= read -r p; do
  [ -n "$p" ] || continue
  echo "seed-plugins: installing $p" >&2
  claude plugin install "$p" \
    || echo "seed-plugins: failed to install $p; continuing" >&2
done

exit 0
