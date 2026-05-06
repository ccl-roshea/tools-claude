# shellcheck shell=bash
export FNM_DIR="$HOME/.fnm"
export PATH="$FNM_DIR:$PATH"
eval "$(fnm env --use-on-cd)" 2>/dev/null || true
