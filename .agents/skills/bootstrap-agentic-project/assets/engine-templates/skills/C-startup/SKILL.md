---
name: C-startup
description: Bootstrap the current directory with the standard Agentic Engineering project structure. Use when starting a new project, initializing a repo with agent teams, or setting up Claude Code / Codex CLI scaffolding.
user-invocable: true
---

# /C-startup — Agentic Engineering Project Bootstrap

Initialize the current working directory with the full Agentic Engineering scaffolding: multi-agent team, hook guardrails, design tokens, PRD templates, and cross-session memory infrastructure.

## Execution

Find and execute the `init.sh` bootstrap script. Search upward from the current working directory first, then fall back to user-level skill directories:

```bash
SKILL_PATH=""
SEARCH_DIR="$PWD"

while [ "$SEARCH_DIR" != "/" ] && [ -z "$SKILL_PATH" ]; do
  for root in \
    "$SEARCH_DIR/.agents/skills" \
    "$SEARCH_DIR/.claude/skills" \
    "$SEARCH_DIR/.claude-plugin"
  do
    [ -d "$root" ] || continue
    SKILL_PATH="$(find "$root" -path "*/bootstrap-agentic-project/scripts/init.sh" -print -quit 2>/dev/null)"
    [ -n "$SKILL_PATH" ] && break
  done

  SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [ -z "$SKILL_PATH" ]; then
  for root in \
    "$HOME/.agents/skills" \
    "$HOME/.claude/skills" \
    "$HOME/.claude-plugin"
  do
    [ -d "$root" ] || continue
    SKILL_PATH="$(find "$root" -path "*/bootstrap-agentic-project/scripts/init.sh" -print -quit 2>/dev/null)"
    [ -n "$SKILL_PATH" ] && break
  done
fi

if [ -n "$SKILL_PATH" ]; then
  bash "$SKILL_PATH"
else
  echo "Error: Could not find bootstrap-agentic-project/scripts/init.sh"
  echo "Please ensure the bootstrap-agentic-project skill is installed."
fi
```

## Post-Bootstrap Verification

After the script completes, verify these core files exist:

- `AGENTS.md` — global agent routing
- `CLAUDE.md` — symlink to AGENTS.md (or existing file with an AGENTS bridge note appended)
- `.claude/settings.json` — hook configuration
- `.claude/agents/` — 5+ agent role definitions
- `.codex/config.toml` — Codex CLI configuration
- `docs/context/INDEX.md` — knowledge base index
- `docs/design/tokens/base.json` — design token baseline

## Final Report

After successful initialization, tell the user:

> Agentic Engineering scaffolding is ready!
>
> **Quick start:**
> - Claude Code: `/prd [your idea]`
> - Codex: ask to use the `pm` custom subagent for requirement discovery
>
> **Next steps:**
> 1. Fill in API keys in `.claude/mcp-servers.json` (Claude Code) or `.codex/config.toml` (Codex CLI)
> 2. Preview the demo PRD: double-click `docs/prd/.demo-feature/preview-PRD-macOS.command`
