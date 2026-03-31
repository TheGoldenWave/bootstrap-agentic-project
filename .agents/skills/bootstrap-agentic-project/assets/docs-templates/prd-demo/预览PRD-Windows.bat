@echo off
chcp 65001 >nul
REM 预览PRD-Windows.bat — 双击即可在浏览器预览 PRD 双视窗
REM 服务从 .artifacts\ 目录启动，PRD.md 通过 ../PRD.md 路径加载

cd /d "%~dp0.artifacts"
IF NOT EXIST "PRD_双视窗.html" (
    echo ❌ 找不到 .artifacts 目录或 PRD_双视窗.html，请确认文件结构完整。
    pause
    exit /b 1
)

SET PORT=8080
SET HTML_FILE=PRD_双视窗.html

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
