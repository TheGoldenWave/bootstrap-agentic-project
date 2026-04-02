#!/bin/bash
# 预览PRD-macOS.command — 双击即可在浏览器预览 PRD 双视窗
# 服务器根目录设为 PRD 目录（本脚本所在目录），确保 fetch('../PRD.md') 可以正常访问

cd "$(dirname "$0")" || {
    echo "❌ 找不到 PRD 目录，请确认文件结构完整。"
    exit 1
}

PORT=8080
HTML_FILE=".artifacts/PRD_dual-pane.html"

echo "🚀 正在启动 PRD 双视窗预览服务..."

if command -v npx &>/dev/null; then
    echo "📦 使用 npx serve 启动..."
    npx serve -l $PORT >/dev/null 2>&1 &
elif command -v python3 &>/dev/null; then
    echo "🐍 使用 Python3 启动..."
    python3 -m http.server $PORT >/dev/null 2>&1 &
elif command -v python &>/dev/null; then
    echo "🐍 使用 Python 启动..."
    python -m SimpleHTTPServer $PORT >/dev/null 2>&1 &
else
    echo "❌ 未找到 Node.js 或 Python，请先安装其中之一。"
    exit 1
fi

sleep 2

echo "✅ 服务已启动，正在打开浏览器..."
open "http://localhost:${PORT}/${HTML_FILE}"

echo ""
echo "💡 按 [Ctrl+C] 停止服务器"
trap "kill %1 2>/dev/null; exit" INT
wait
