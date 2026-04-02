@echo off
chcp 65001 >nul
REM 预览PRD-Windows.bat — 双击即可在浏览器预览 PRD 双视窗
REM 服务器根目录设为 PRD 目录（本脚本所在目录），确保 fetch('../PRD.md') 可以正常访问

cd /d "%~dp0"
IF NOT EXIST ".artifacts\PRD_dual-pane.html" (
    echo ❌ 找不到 .artifacts\PRD_dual-pane.html，请确认文件结构完整。
    pause
    exit /b 1
)

SET PORT=8080
SET HTML_FILE=.artifacts/PRD_dual-pane.html

echo 🚀 正在启动 PRD 双视窗预览服务...

where python >nul 2>&1
IF %ERRORLEVEL%==0 (
    echo 🐍 使用 Python 启动...
    start "" python -m http.server %PORT%
    goto :open
)

where npx >nul 2>&1
IF %ERRORLEVEL%==0 (
    echo 📦 使用 npx serve 启动...
    start "" npx serve -l %PORT%
    goto :open
)

echo ❌ 未找到 Python 或 Node.js，请先安装其中之一。
pause
exit /b 1

:open
timeout /t 2 /nobreak >nul
start "" http://localhost:%PORT%/%HTML_FILE%
echo ✅ 预览已在浏览器打开。关闭此窗口将停止服务器。
pause
