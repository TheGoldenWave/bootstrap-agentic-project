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
scripts/init.sh       ← Core bootstrap script (16 idempotent steps)
assets/
  root-templates/     ← AGENTS.md (injected at target root; CLAUDE.md symlinks to it)
  engine-templates/   ← Everything under .claude/ (agents, hooks, contexts, rules, commands, templates, design tokens, skills)
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
6. Copies 6 agent definitions, slash commands, PM workflow templates, hook scripts, contexts, rules, design tokens, MCP config, Codex config, 22+ skills (design + prd + progress + C-startup + reflect), and docs templates
7. Protects `mcp-servers.json` and `.codex/config.toml` in `.gitignore`

All file operations use `safe_copy` — skip if destination exists.

### Hook Scripts (Node.js, zero dependencies)

Located in `assets/engine-templates/scripts/hooks/`:

- **session-start.js** (SessionStart) — scans `docs/prd/**/process.txt` and `process.md` (with YAML frontmatter stage extraction), injects content as context via stdout JSON. V3: budget-aware injection (MAX_CONTEXT_CHARS = 8000), prioritizes newest files, over-budget files get frontmatter summary only with a truncation notice
- **check-console-log.js** (PreToolUse/Edit) — reads tool input from stdin, blocks edits containing `console.log` in `.ts/.tsx/.js/.jsx` files (exit 2)
- **session-stop.js** (Stop) — first trigger exits 2 with save-progress reminder; second trigger (`stop_hook_active: true`) exits 0 to break the loop. V3: detects both process.txt and process.md, suggests `/reflect` when notes.md files were recently modified

### Template Substitution

Only `settings.json` uses the `{{ENGINE_DIR}}` placeholder, resolved by `sed` in init.sh. All other templates are copied as-is.

## Key Conventions

- `CLAUDE.md` in bootstrapped projects is a **symlink** to `AGENTS.md` — editing either one updates both
- The 6 agent roles (pm, project-manager, dev, architect, ui, qa) exist in two formats: `.md` for Claude Code, `.toml` for Codex
- pm-agent supports dual-path workflow: business (confirmation sheet → MRD → PRD) and product-initiated (product brief → PRD)
- project-manager-agent manages process.md: scheduling, progress tracking, blocker management
- `mcp-servers.json` and `.codex/config.toml` contain API key placeholders — never commit real values
- Design tokens live in `docs/design/tokens/base.json` — hardcoded colors/spacing/fonts are prohibited in bootstrapped projects
- `process.txt` and `process.md` files under `docs/prd/` serve as cross-session memory, auto-loaded by the SessionStart hook
- `docs/context/INDEX.md` is a structured knowledge index with 5 category tables, maintained via `/reflect` skill
- PM workflow templates (confirmation sheet, MRD, product brief, process board) live in `{ENGINE_DIR}/templates/`
