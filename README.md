# tools-claude

A repository for developing and organizing [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills (custom slash commands) and plugins.

## Structure

| Directory | Purpose |
|-----------|---------|
| `skills/` | Standalone, reusable skills |
| `plugins/` | Packaged plugin collections |

## Creating a Skill

1. Create a directory under `skills/` with your skill name
2. Add a `SKILL.md` file with YAML frontmatter and prompt body
3. See [`skills/example-greet/SKILL.md`](skills/example-greet/SKILL.md) for a template

## Creating a Plugin

1. Create a directory under `plugins/` with your plugin name
2. Add a `.claude-plugin/plugin.json` manifest
3. Add components: `skills/`, `agents/`, `hooks/`, `.mcp.json`

## Local Testing

```bash
# Test standalone skills
claude --add-dir ./skills

# Test a plugin
claude --plugin-dir ./plugins/my-plugin

# Reload after edits
/reload-plugins
```
