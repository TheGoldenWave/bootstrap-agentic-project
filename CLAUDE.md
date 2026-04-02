# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is a **Claude Code / Codex CLI skill package** — not an application. It bootstraps any target repository into a standardized "Agentic Engineering" workspace with multi-agent teams, hook guardrails, design infrastructure, and cross-session memory. There is no application code, no tests, no package.json, and no build system.

## The One Command

```bash
bash scripts/init.sh
```

Run from a **target repository's root** (not from this repo). The script is fully idempotent — existing files are never overwritten. Override the engine directory with `AGENTIC_ENGINE_DIR=<path> bash scripts/init.sh`.

## Architecture

```
SKILL.md              ← Skill entry point (triggers init.sh via search path)
scripts/init.sh       ← Core bootstrap script (15 idempotent steps)
assets/
  root-templates/     ← AGENTS.md (injected at target root; CLAUDE.md symlinks to it)
  engine-templates/   ← Everything under .claude/ (agents, hooks, contexts, rules, commands, design tokens, skills)
  codex-templates/    ← Everything under .codex/ (config.toml, agent .toml files)
  docs-templates/     ← docs/ scaffolding (INDEX.md, PRD demo with dual-pane viewer)
references/           ← Conceptual guide (agentic-engineering-guide.md)
.agents/skills/       ← Self-copy for Codex auto-discovery
```

### How init.sh Works

1. Detects ECC plugin (`.claude-plugin/plugin.json`) and warns about hook coexistence
2. Sets `ENGINE_DIR` (default `.claude/`, overridable via env)
3. Creates full directory tree (`ENGINE_DIR/`, `.codex/`, `docs/`, `tests/`, `src/`)
4. Copies `AGENTS.md` to root; creates `CLAUDE.md` as symlink (or appends routing to existing files)
5. Generates `settings.json` by substituting `{{ENGINE_DIR}}` placeholder in template
6. Copies 5 agent definitions, slash commands, hook scripts, contexts, rules, design tokens, MCP config, Codex config, 21 design skills, and docs templates
7. Protects `mcp-servers.json` and `.codex/config.toml` in `.gitignore`

All file operations use `safe_copy` — skip if destination exists.

### Hook Scripts (Node.js, zero dependencies)

Located in `assets/engine-templates/scripts/hooks/`:

- **session-start.js** (SessionStart) — scans `docs/prd/**/process.txt`, injects content as context via stdout JSON
- **check-console-log.js** (PreToolUse/Edit) — reads tool input from stdin, blocks edits containing `console.log` in `.ts/.tsx/.js/.jsx` files (exit 2)
- **session-stop.js** (Stop) — first trigger exits 2 with save-progress reminder; second trigger (`stop_hook_active: true`) exits 0 to break the loop

### Template Substitution

Only `settings.json` uses the `{{ENGINE_DIR}}` placeholder, resolved by `sed` in init.sh. All other templates are copied as-is.

## Key Conventions

- `CLAUDE.md` in bootstrapped projects is a **symlink** to `AGENTS.md` — editing either one updates both
- The 5 agent roles (pm, dev, architect, ui, qa) exist in two formats: `.md` for Claude Code, `.toml` for Codex
- `mcp-servers.json` and `.codex/config.toml` contain API key placeholders — never commit real values
- Design tokens live in `docs/design/tokens/base.json` — hardcoded colors/spacing/fonts are prohibited in bootstrapped projects
- `process.txt` files under `docs/prd/` serve as cross-session memory, auto-loaded by the SessionStart hook
