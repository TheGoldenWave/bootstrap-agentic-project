---
name: bootstrap-agentic-project
description: Use when bootstrapping a repository with shared docs-as-code scaffolding, Claude Code hooks, and Codex project configuration for multi-agent workflows.
---

# Bootstrap Agentic Project Skill

**Description**:
This skill initializes a Next-Gen Agentic Engineering project structure. It creates the necessary directory scaffolding, injects core guardrail files (AGENTS.md, INDEX.md), and sets up the foundational hooks and dynamic contexts inspired by the `everything-claude-code` project.

---

## 🛠️ Execution Instructions (For Agent)

When the user invokes this skill, you MUST execute the initialization script provided in this package.

### Step 1: Execute the Bootstrap Script
Find and execute the `init.sh` script associated with this skill. Since this skill might be installed globally or locally for either Claude Code or Codex, use a search path that covers both engines:

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
fi
```

### Step 2: Verification
Verify that the following core components have been successfully created in the user's current working directory:
- `AGENTS.md`
- `CLAUDE.md` or an existing project instruction file already updated with the routing section
- `.claude/settings.json`
- `.codex/config.toml`
- `.claude/contexts/dev.md`
- `docs/context/INDEX.md`

### Step 3: Optional Cleanup
Do not auto-delete the skill package. If the project temporarily vendored a local copy of the skill only for bootstrap, let the user decide whether to remove it after initialization.

### Step 4: Final Output
Report to the user:
> "✅ Agentic Engineering 标准底座已初始化完毕！
> 包含 Claude Code Hooks、动态 Contexts、Codex 多 Agent 配置和底层 Rules 已就绪。
> 您可以输入 `/prd [您的初步需求]` 来激活 pm-agent 开始您的第一个需求了！"
