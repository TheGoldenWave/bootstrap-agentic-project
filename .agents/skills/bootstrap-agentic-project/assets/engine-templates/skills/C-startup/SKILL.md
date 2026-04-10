---
name: C-startup
description: Bootstrap the current directory with the standard Agentic Engineering project structure. Use when starting a new project, initializing a repo with agent teams, or setting up Claude Code / Codex CLI scaffolding.
user-invocable: true
---

# /C-startup — Agentic Engineering Project Bootstrap

Initialize the current working directory with the full Agentic Engineering scaffolding: multi-agent team, hook guardrails, design tokens, PRD templates, and cross-session memory infrastructure.

## Execution

Find and execute the `init.sh` bootstrap script. Search the following paths in order:

```bash
SKILL_PATH=""
for root in \
  ".agents/skills" \
  "$HOME/.agents/skills" \
  ".claude/skills" \
  "$HOME/.claude/skills" \
  ".claude-plugin" \
  "$HOME/.claude-plugin"
do
  [ -d "$root" ] || continue
  SKILL_PATH="$(find "$root" -path "*/bootstrap-agentic-project/scripts/init.sh" -print -quit 2>/dev/null)"
  [ -n "$SKILL_PATH" ] && break
done

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
- `CLAUDE.md` — symlink to AGENTS.md (or existing file with routing appended)
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
> - `/prd [your idea]` — start a new requirement with PM Agent
> - `/progress init {feature_id}` — initialize project schedule
>
> **Next steps:**
> 1. Fill in API keys in `.claude/mcp-servers.json` (Claude Code) or `.codex/config.toml` (Codex CLI)
> 2. Preview the demo PRD: double-click `docs/prd/.demo-feature/preview-PRD-macOS.command`
