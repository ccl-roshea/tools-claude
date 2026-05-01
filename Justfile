# Justfile for installing skills from this repo into Claude Code.
#
# Skills are installed as symlinks so changes in the repo reflect immediately
# in Claude Code without re-running `just install`. To install:
#
#   just install
#
# To remove only the symlinks this repo created (leaves other skills alone):
#
#   just uninstall
#
# To see what's installed:
#
#   just status
#
# Requires: `just` (https://github.com/casey/just) and bash.

# Default: list available recipes
default:
    @just --list

skills_dir := justfile_directory() + "/skills"
claude_skills_dir := env_var('HOME') + "/.claude/skills"

# Install all skills in this repo as symlinks under ~/.claude/skills/
install:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{claude_skills_dir}}"
    for skill in "{{skills_dir}}"/*/; do
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
        echo "Installed: $name -> $skill"
    done

# Remove symlinks installed from this repo. Leaves other skills alone.
uninstall:
    #!/usr/bin/env bash
    set -euo pipefail
    for skill in "{{skills_dir}}"/*/; do
        skill="${skill%/}"
        name="$(basename "$skill")"
        target="{{claude_skills_dir}}/$name"
        if [ -L "$target" ]; then
            link_target="$(readlink "$target")"
            if [ "$link_target" = "$skill" ]; then
                rm "$target"
                echo "Uninstalled: $name"
            else
                echo "Skipping $name — symlink points elsewhere: $link_target"
            fi
        elif [ -e "$target" ]; then
            echo "Skipping $name — exists but is not a symlink (manual cleanup needed)"
        else
            echo "Skipping $name — not installed"
        fi
    done

# Show install state of each skill in this repo
status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Skills directory: {{skills_dir}}"
    echo "Install target:   {{claude_skills_dir}}"
    echo
    for skill in "{{skills_dir}}"/*/; do
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
            echo "  $name: NOT installed (real file/dir at target — needs manual cleanup)"
        else
            echo "  $name: not installed"
        fi
    done

# List everything currently in ~/.claude/skills/ (not just from this repo)
list:
    @ls -la "{{claude_skills_dir}}" 2>/dev/null || echo "{{claude_skills_dir}} does not exist yet"
