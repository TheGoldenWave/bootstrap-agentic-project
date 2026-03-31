#!/bin/bash

# =================================================================
# Agentic Engineering Project Bootstrap Script
#
# Scaffolds the Next-Gen Agentic Engineering directory structure.
# Defaults to .claude/ (native Claude Code convention).
# Detects everything-claude-code (ECC) plugin installation and
# warns about hook coexistence when found.
# Always generates Codex CLI support (.codex/ + .agents/skills/).
# All operations are idempotent: existing files are never overwritten.
# =================================================================

set -euo pipefail

echo "🚀 Starting Agentic Engineering Project Bootstrap..."

# --- ECC Detection ---
# ECC (everything-claude-code) is identified by a project-level plugin manifest.
# Note: .agents/ is ECC's Codex/OpenAI compatibility directory — it is NOT
# a signal of ECC for Claude Code. The canonical ECC marker is .claude-plugin/plugin.json.
ECC_DETECTED=false
if [ -f ".claude-plugin/plugin.json" ]; then
    ECC_DETECTED=true
    echo "🔍 [ECC Detected] everything-claude-code plugin found (.claude-plugin/plugin.json)."
    echo "   Bootstrap will coexist with ECC: using .claude/ as engine directory."
    echo "   ⚠️  Note: ECC's own hooks (hooks/hooks.json) and bootstrap's hooks"
    echo "   (.claude/settings.json) will both be active. Avoid duplicating the"
    echo "   same hook logic in both places."
fi

# --- Engine Directory Detection ---
# Priority:
#   1. Explicit override via AGENTIC_ENGINE_DIR env var
#   2. Always .claude/ — the official Claude Code project directory.
#      (.agents/ is for Codex/OpenAI compatibility only, never used by Claude Code)

if [ -n "${AGENTIC_ENGINE_DIR:-}" ]; then
    ENGINE_DIR="$AGENTIC_ENGINE_DIR"
    echo "🔧 Using explicit ENGINE_DIR override: ${ENGINE_DIR}/"
else
    ENGINE_DIR=".claude"
    echo "🔍 Using native Claude Code directory: .claude/"
fi

# --- Locate this script's assets directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ASSETS_DIR="${SKILL_DIR}/assets"

if [ ! -d "$ASSETS_DIR" ]; then
    echo "❌ Error: Cannot find assets directory at ${ASSETS_DIR}" >&2
    exit 1
fi

# --- Helper: safe_copy (never overwrites existing files) ---
safe_copy() {
    local src="$1"
    local dst="$2"
    if [ -e "$dst" ]; then
        echo "  ⏭  Skipped (already exists): ${dst}"
    else
        cp "$src" "$dst"
        echo "  ✅ Created: ${dst}"
    fi
}

# --- Helper: safe_copy_dir (copies directory contents, never overwrites) ---
safe_copy_dir() {
    local src_dir="$1"
    local dst_dir="$2"
    if [ ! -d "$src_dir" ]; then return; fi
    mkdir -p "$dst_dir"
    for src_file in "$src_dir"/*; do
        [ -e "$src_file" ] || continue
        local filename
        filename="$(basename "$src_file")"
        if [ -d "$src_file" ]; then
            safe_copy_dir "$src_file" "$dst_dir/$filename"
        else
            safe_copy "$src_file" "$dst_dir/$filename"
        fi
    done
}

# =================================================================
# 1. Create directory structure
# =================================================================
echo ""
echo "📁 Creating directory structure..."

dirs=(
    "${ENGINE_DIR}/agents"
    "${ENGINE_DIR}/skills"
    "${ENGINE_DIR}/commands"
    "${ENGINE_DIR}/scripts/hooks"
    "${ENGINE_DIR}/contexts"
    "${ENGINE_DIR}/rules/common"
    ".codex/agents"
    ".agents/skills"
    "docs/context/team"
    "docs/context/project/experience"
    "docs/prd/demo-feature"
    "docs/prd/demo-feature/.artifacts"
    "docs/design/tokens"
    "docs/design/components"
    "tests/specs"
    "tests/evals"
    "src"
)

for d in "${dirs[@]}"; do
    if [ ! -d "$d" ]; then
        mkdir -p "$d"
        echo "  📂 ${d}/"
    fi
done

# =================================================================
# 2. Root config files (universal AGENTS.md / CLAUDE.md)
# =================================================================
echo ""
echo "📄 Copying root config files..."

if [ -f "./CLAUDE.md" ]; then
    echo "  ⏭  Skipped CLAUDE.md (already exists). Appending agent routing section..."
    # Only append if our marker isn't already present
    if ! grep -q "Added by Agentic Bootstrap" ./CLAUDE.md 2>/dev/null; then
        {
            echo ""
            echo ""
            echo "# --- Added by Agentic Bootstrap ---"
            cat "${ASSETS_DIR}/root-templates/AGENTS.md"
        } >> ./CLAUDE.md
        echo "  ✅ Appended Agentic routing to existing CLAUDE.md"
    else
        echo "  ⏭  Agentic routing already present in CLAUDE.md"
    fi
elif [ -f "./AGENTS.md" ]; then
    echo "  ⏭  Skipped AGENTS.md (already exists). Appending agent routing section..."
    if ! grep -q "Added by Agentic Bootstrap" ./AGENTS.md 2>/dev/null; then
        {
            echo ""
            echo ""
            echo "# --- Added by Agentic Bootstrap ---"
            cat "${ASSETS_DIR}/root-templates/AGENTS.md"
        } >> ./AGENTS.md
        echo "  ✅ Appended Agentic routing to existing AGENTS.md"
    else
        echo "  ⏭  Agentic routing already present in AGENTS.md"
    fi
else
    safe_copy "${ASSETS_DIR}/root-templates/AGENTS.md" "./AGENTS.md"
    if [ -e "./CLAUDE.md" ]; then
        echo "  ⏭  Skipped (already exists): ./CLAUDE.md"
    else
        ln -sf AGENTS.md ./CLAUDE.md
        echo "  ✅ Created: ./CLAUDE.md → AGENTS.md (symlink)"
    fi
fi

# =================================================================
# 3. settings.json — generated dynamically with correct ENGINE_DIR path
# =================================================================
echo ""
echo "🛡️  Generating settings.json with hook paths..."

SETTINGS_FILE="${ENGINE_DIR}/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    echo "  ⏭  Skipped ${SETTINGS_FILE} (already exists)."
    echo "     To add hooks manually, merge the following events into ${SETTINGS_FILE}:"
    echo "     SessionStart    → node ${ENGINE_DIR}/scripts/hooks/session-start.js"
    echo "     PreToolUse/Edit → node ${ENGINE_DIR}/scripts/hooks/check-console-log.js"
    echo "     Stop            → node ${ENGINE_DIR}/scripts/hooks/session-stop.js"
else
    # Use sed to substitute {{ENGINE_DIR}} with the actual value
    sed "s|{{ENGINE_DIR}}|${ENGINE_DIR}|g" \
        "${ASSETS_DIR}/engine-templates/settings.json" \
        > "$SETTINGS_FILE"
    echo "  ✅ Generated ${SETTINGS_FILE}"

    # ECC coexistence note: warn if ECC's hooks already cover the same events
    if [ "$ECC_DETECTED" = true ] && [ -f "hooks/hooks.json" ]; then
        echo ""
        echo "  ⚠️  [ECC Coexistence] ECC's hooks/hooks.json is also active."
        echo "     ECC already handles SessionStart (session context) and"
        echo "     PreToolUse/Bash (commit quality, security). Review both files"
        echo "     and disable duplicate logic to avoid redundant hook firings:"
        echo "       - Bootstrap: ${SETTINGS_FILE}"
        echo "       - ECC:       hooks/hooks.json"
    fi
fi

# =================================================================
# 4. Agent team (Claude Code .md format)
# =================================================================
echo ""
echo "🤖 Recruiting Claude Code Agent team..."
safe_copy_dir "${ASSETS_DIR}/engine-templates/agents" "${ENGINE_DIR}/agents"

# =================================================================
# 5. Slash commands
# =================================================================
echo ""
echo "⌨️  Installing slash commands..."
safe_copy_dir "${ASSETS_DIR}/engine-templates/commands" "${ENGINE_DIR}/commands"

# =================================================================
# 6. Hook scripts
# =================================================================
echo ""
echo "🔗 Installing hook scripts..."
safe_copy_dir "${ASSETS_DIR}/engine-templates/scripts/hooks" "${ENGINE_DIR}/scripts/hooks"

# =================================================================
# 7. Contexts (dynamic mode prompts)
# =================================================================
echo ""
echo "🎭 Copying dynamic contexts..."
safe_copy_dir "${ASSETS_DIR}/engine-templates/contexts" "${ENGINE_DIR}/contexts"

# =================================================================
# 8. Rules (always-apply guardrails)
# =================================================================
echo ""
echo "📜 Copying coding rules..."
safe_copy_dir "${ASSETS_DIR}/engine-templates/rules" "${ENGINE_DIR}/rules"

# =================================================================
# 9. Design tokens
# =================================================================
echo ""
echo "🎨 Seeding Design Token baseline..."
safe_copy_dir "${ASSETS_DIR}/engine-templates/design/tokens" "docs/design/tokens"

# =================================================================
# 10. MCP servers config (Claude Code)
# =================================================================
echo ""
echo "🔌 Setting up project MCP config (Claude Code)..."
MCP_FILE="${ENGINE_DIR}/mcp-servers.json"
if [ -f "$MCP_FILE" ]; then
    echo "  ⏭  Skipped ${MCP_FILE} (already exists)."
else
    safe_copy "${ASSETS_DIR}/engine-templates/mcp-servers.json" "$MCP_FILE"
    echo "  ⚠️  mcp-servers.json contains placeholder API keys."
    echo "     Fill in real values, then add it to .gitignore to avoid leaking secrets."
fi

# =================================================================
# 11. Codex CLI support
# =================================================================
echo ""
echo "🔷 Setting up Codex CLI support..."

CODEX_TEMPLATES="${ASSETS_DIR}/codex-templates"

# 11a. config.toml — generated dynamically (no ENGINE_DIR substitution needed for Codex)
CODEX_CONFIG=".codex/config.toml"
if [ -f "$CODEX_CONFIG" ]; then
    echo "  ⏭  Skipped ${CODEX_CONFIG} (already exists)."
    echo "     To enable multi-agent support, ensure [features] multi_agent = true is set."
else
    safe_copy "${CODEX_TEMPLATES}/config.toml" "$CODEX_CONFIG"
    echo "  ⚠️  .codex/config.toml contains commented-out MCP server placeholders."
    echo "     Uncomment and fill in API Keys, then add .codex/config.toml to .gitignore."
fi

# 11b. Codex AGENTS.md supplement
safe_copy "${CODEX_TEMPLATES}/AGENTS.md" ".codex/AGENTS.md"

# 11c. Agent TOML files
echo "  🤖 Installing Codex agent roles..."
safe_copy_dir "${CODEX_TEMPLATES}/agents" ".codex/agents"

# =================================================================
# 12. Claude Code skills (impeccable design skills)
# =================================================================
echo ""
echo "🎨 Installing design skills (impeccable)..."
if [ -d "${ASSETS_DIR}/engine-templates/skills" ]; then
    safe_copy_dir "${ASSETS_DIR}/engine-templates/skills" "${ENGINE_DIR}/skills"
fi

# =================================================================
# 13. .agents/skills/ — Codex auto-discovery skills (bootstrap self-install)
# =================================================================
echo ""
echo "📦 Installing .agents/skills/ packages (Codex auto-discovery)..."

# 12a. Find this skill's own .agents/skills/ directory and copy it
SKILL_AGENTS_DIR="${SKILL_DIR}/.agents/skills"
if [ -d "$SKILL_AGENTS_DIR" ]; then
    safe_copy_dir "$SKILL_AGENTS_DIR" ".agents/skills"
    echo "  ✅ Installed skills from skill repo's .agents/skills/"
elif [ -f "${SKILL_DIR}/SKILL.md" ]; then
    safe_copy_dir "$SKILL_DIR" ".agents/skills/bootstrap-agentic-project"
    echo "  ✅ Installed standalone bootstrap-agentic-project skill package"
fi

# =================================================================
# 14. Docs / PRD demo
# =================================================================
echo ""
echo "📚 Copying docs templates..."
safe_copy "${ASSETS_DIR}/docs-templates/INDEX.md" "docs/context/INDEX.md"
safe_copy_dir "${ASSETS_DIR}/docs-templates/prd-demo" "docs/prd/demo-feature"
# Copy hidden .artifacts directory (safe_copy_dir skips dotfiles)
mkdir -p "docs/prd/demo-feature/.artifacts"
safe_copy_dir "${ASSETS_DIR}/docs-templates/prd-demo/.artifacts" "docs/prd/demo-feature/.artifacts"
chmod +x "docs/prd/demo-feature/预览PRD-macOS.command" 2>/dev/null || true

# =================================================================
# 15. .gitignore — protect secrets
# =================================================================
GITIGNORE=".gitignore"
if [ -f "$GITIGNORE" ]; then
    GITIGNORE_CHANGED=false

    if ! grep -q "mcp-servers.json" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# Agentic Engineering: MCP configs may contain API keys" >> "$GITIGNORE"
        echo "${ENGINE_DIR}/mcp-servers.json" >> "$GITIGNORE"
        echo "  ✅ Added ${ENGINE_DIR}/mcp-servers.json to .gitignore"
        GITIGNORE_CHANGED=true
    else
        echo "  ⏭  mcp-servers.json already in .gitignore"
    fi

    if ! grep -q "\.codex/config\.toml" "$GITIGNORE" 2>/dev/null; then
        if [ "$GITIGNORE_CHANGED" = false ]; then
            echo "" >> "$GITIGNORE"
            echo "# Agentic Engineering: Codex config may contain API keys" >> "$GITIGNORE"
        fi
        echo ".codex/config.toml" >> "$GITIGNORE"
        echo "  ✅ Added .codex/config.toml to .gitignore"
    else
        echo "  ⏭  .codex/config.toml already in .gitignore"
    fi
else
    cat > "$GITIGNORE" << EOF
# Agentic Engineering: configs may contain API keys
${ENGINE_DIR}/mcp-servers.json
.codex/config.toml
EOF
    echo "  ✅ Created .gitignore"
fi

# =================================================================
# Done
# =================================================================
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✅  Agentic Engineering 底座初始化完毕！            ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "📂 Claude Code 引擎目录 : ${ENGINE_DIR}/"
echo "📂 Codex CLI 引擎目录   : .codex/"
echo "📦 Codex 技能目录       : .agents/skills/"
echo "🤖 Agent 团队           : pm-agent, architect-agent, dev-agent, ui-agent, qa-agent"
echo "🔗 Claude Hooks         : SessionStart + PreToolUse(Edit) + Stop → ${ENGINE_DIR}/scripts/hooks/"
echo "🔷 Codex 多 Agent       : [agents.*] in .codex/config.toml"
echo "🎨 Design Tokens        : docs/design/tokens/base.json"
echo ""
echo "💡 下一步："
echo "   1. 检查并填写 ${ENGINE_DIR}/mcp-servers.json 中的 API Key（Claude Code）"
echo "   2. 检查并配置 .codex/config.toml 中的 MCP 服务（Codex CLI）"
echo "   3. 这两个文件已自动加入 .gitignore，API Key 不会泄露"
echo "   4. 体验双视窗 PRD：双击 docs/prd/demo-feature/预览PRD-macOS.command（macOS）"
echo "                     或  docs/prd/demo-feature/预览PRD-Windows.bat（Windows）"
echo ""
echo "   开始第一个需求："
echo "   • Claude Code: 输入 /prd [你的初步想法]"
echo "   • Codex CLI  : 输入 /agent pm [你的初步想法]"
echo ""
echo "🚀 Enjoy your Vibe Coding!"
