# Justfile for installing skills and plugins from this repo into Claude Code.
#
# Skills are installed as symlinks under ~/.claude/skills/ so changes in the
# repo reflect immediately in Claude Code without re-running `just install`.
#
# Plugins are installed via the `claude plugin` CLI: this repo is registered
# as a local marketplace (via `.claude-plugin/marketplace.json`) and each
# plugin under `plugins/` is installed and enabled by name.
#
# Usage:
#   just install      # install both skills and plugins
#   just uninstall    # uninstall both
#   just status       # show install state of both
#
# Requires: `just`, `bash`, and the `claude` CLI on PATH.

# Default: list available recipes
default:
    @just --list

skills_dir := justfile_directory() + "/skills"
plugins_dir := justfile_directory() + "/plugins"
claude_skills_dir := env_var('HOME') + "/.claude/skills"
marketplace_name := "tools-claude"

# Install both skills (symlink) and plugins (claude plugin CLI)
install: install-skills install-plugins

# Uninstall plugins first (so they're gone before any source moves), then skills
uninstall: uninstall-plugins uninstall-skills

# Show install state of skills and plugins
status: status-skills status-plugins

# Refresh installed plugins from this repo's source (skills are already symlinks).
# Useful during dev: `claude plugin install` copies into ~/.claude/plugins/cache/,
# so edits to plugin source don't reflect until reinstall. `just sync` re-pulls.
sync: uninstall-plugins install-plugins

# --- Skills ---------------------------------------------------------------

# Install all skills in skills/ as symlinks under ~/.claude/skills/
install-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{claude_skills_dir}}"
    shopt -s nullglob
    skills=("{{skills_dir}}"/*/)
    if (( ${#skills[@]} == 0 )); then
        echo "No skills to install (skills/ has no subdirectories)."
        exit 0
    fi
    for skill in "${skills[@]}"; do
        skill="${skill%/}"
        name="$(basename "$skill")"
        target="{{claude_skills_dir}}/$name"
        if [ -L "$target" ]; then
            echo "Replacing existing symlink: $name"
            rm "$target"
        elif [ -e "$target" ]; then
            echo "ERROR: $target exists and is not a symlink — refusing to overwrite." >&2
            echo "  Move or remove it manually, then re-run 'just install'." >&2
            exit 1
        fi
        ln -s "$skill" "$target"
        echo "Installed skill: $name -> $skill"
    done

# Remove skill symlinks installed from this repo. Leaves other skills alone.
uninstall-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    skills=("{{skills_dir}}"/*/)
    if (( ${#skills[@]} == 0 )); then
        echo "No skills to uninstall (skills/ has no subdirectories)."
        exit 0
    fi
    for skill in "${skills[@]}"; do
        skill="${skill%/}"
        name="$(basename "$skill")"
        target="{{claude_skills_dir}}/$name"
        if [ -L "$target" ]; then
            link_target="$(readlink "$target")"
            if [ "$link_target" = "$skill" ]; then
                rm "$target"
                echo "Uninstalled skill: $name"
            else
                echo "Skipping skill $name — symlink points elsewhere: $link_target"
            fi
        elif [ -e "$target" ]; then
            echo "Skipping skill $name — exists but is not a symlink (manual cleanup needed)"
        else
            echo "Skipping skill $name — not installed"
        fi
    done

# Show install state of each skill in skills/
status-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "== Skills =="
    echo "  source:  {{skills_dir}}"
    echo "  target:  {{claude_skills_dir}}"
    shopt -s nullglob
    skills=("{{skills_dir}}"/*/)
    if (( ${#skills[@]} == 0 )); then
        echo "  (no skills in source)"
    else
        for skill in "${skills[@]}"; do
            skill="${skill%/}"
            name="$(basename "$skill")"
            target="{{claude_skills_dir}}/$name"
            if [ -L "$target" ]; then
                link_target="$(readlink "$target")"
                if [ "$link_target" = "$skill" ]; then
                    echo "  $name: installed -> this repo"
                else
                    echo "  $name: symlink points elsewhere ($link_target)"
                fi
            elif [ -e "$target" ]; then
                echo "  $name: NOT installed (real file/dir at target — manual cleanup needed)"
            else
                echo "  $name: not installed"
            fi
        done
    fi

# List everything currently in ~/.claude/skills/ (not just from this repo)
list:
    @ls -la "{{claude_skills_dir}}" 2>/dev/null || echo "{{claude_skills_dir}} does not exist yet"

# --- Plugins --------------------------------------------------------------

# Register this repo as a marketplace and install/enable each plugin in plugins/
install-plugins:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    plugins=("{{plugins_dir}}"/*/)
    if (( ${#plugins[@]} == 0 )); then
        echo "No plugins to install (plugins/ has no subdirectories)."
        exit 0
    fi
    echo "Registering marketplace: {{marketplace_name}} -> {{justfile_directory()}}"
    claude plugin marketplace add "{{justfile_directory()}}" || true
    for plugin in "${plugins[@]}"; do
        plugin="${plugin%/}"
        name="$(basename "$plugin")"
        echo "Installing plugin: $name@{{marketplace_name}}"
        claude plugin install "$name@{{marketplace_name}}" || true
        claude plugin enable "$name@{{marketplace_name}}" || true
    done

# Uninstall plugins from this repo and remove the marketplace registration
uninstall-plugins:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    plugins=("{{plugins_dir}}"/*/)
    if (( ${#plugins[@]} == 0 )); then
        echo "No plugins to uninstall (plugins/ has no subdirectories)."
    else
        for plugin in "${plugins[@]}"; do
            plugin="${plugin%/}"
            name="$(basename "$plugin")"
            echo "Uninstalling plugin: $name@{{marketplace_name}}"
            claude plugin uninstall "$name@{{marketplace_name}}" || true
        done
    fi
    echo "Removing marketplace: {{marketplace_name}}"
    claude plugin marketplace remove "{{marketplace_name}}" || true

# Show install state of each plugin in plugins/
status-plugins:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "== Plugins =="
    echo "  source:      {{plugins_dir}}"
    echo "  marketplace: {{marketplace_name}}"
    shopt -s nullglob
    plugins=("{{plugins_dir}}"/*/)
    if (( ${#plugins[@]} == 0 )); then
        echo "  (no plugins in source)"
        exit 0
    fi
    installed_list="$(claude plugin list 2>/dev/null || true)"
    for plugin in "${plugins[@]}"; do
        plugin="${plugin%/}"
        name="$(basename "$plugin")"
        if grep -F -- "$name@{{marketplace_name}}" <<<"$installed_list" >/dev/null 2>&1; then
            echo "  $name: installed via $name@{{marketplace_name}}"
        else
            echo "  $name: not installed"
        fi
    done
