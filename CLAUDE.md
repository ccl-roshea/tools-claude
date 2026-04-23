# tools-claude

This repository contains Claude Code skills and plugins. It is a development workspace for authoring, testing, and organizing reusable Claude Code extensions.

## Directory Conventions

- **`skills/<name>/SKILL.md`** — Standalone skills (slash commands). Each skill lives in its own directory with a `SKILL.md` entrypoint and optional supporting files.
- **`plugins/<name>/`** — Packaged plugins containing related skills, agents, hooks, and/or MCP servers.

## Skill Authoring

Every skill requires a `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: What this skill does (used by Claude to decide when to invoke it)
when_to_use: Additional trigger hints
arguments: [arg1, arg2]
allowed-tools: "Bash(git *) Read"
---
```

The body contains the prompt/instructions Claude follows when the skill is invoked.

Guidelines:
- Keep skills focused and single-purpose
- Write clear `description` and `when_to_use` fields so Claude triggers the skill correctly
- Use `allowed-tools` to pre-approve only the tools the skill needs
- Reference supporting files with relative paths from the skill directory

## Plugin Structure

Each plugin requires a `.claude-plugin/plugin.json` manifest:

```json
{
  "name": "plugin-name",
  "description": "What this plugin does",
  "version": "1.0.0",
  "author": { "name": "Author Name" }
}
```

Plugins can contain: `skills/`, `agents/`, `hooks/`, `.mcp.json`, `settings.json`.

## Git Conventions

- Use imperative mood in commit messages ("Add feature" not "Added feature")
- Conventional commits style encouraged (`feat:`, `fix:`, `docs:`, `chore:`)
