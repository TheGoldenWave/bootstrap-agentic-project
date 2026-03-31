#!/usr/bin/env node

/**
 * SessionStart Hook — Memory Injection
 *
 * Fires when a new Claude Code session starts (SessionStart event).
 * Scans docs/prd/ for all process.txt files and injects their contents
 * into the session context so Claude can restore memory automatically.
 *
 * Output protocol (compatible with Claude Code & ECC):
 *   - context injection → stdout JSON { hookSpecificOutput: { hookEventName, additionalContext } }
 *   - diagnostic logs   → stderr (never injected into Claude's context)
 *
 * Wired in settings.json:
 *   hooks.SessionStart
 */

const fs = require('fs');
const path = require('path');

const cwd = process.cwd();
const prdDir = path.join(cwd, 'docs', 'prd');

/**
 * Recursively find all process.txt files under a directory.
 * Returns paths sorted by most recently modified first.
 */
function findProcessFiles(dir) {
  if (!fs.existsSync(dir)) return [];

  const results = [];
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (_) {
    return results;
  }

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findProcessFiles(fullPath));
    } else if (entry.name === 'process.txt') {
      results.push(fullPath);
    }
  }
  return results;
}

function main() {
  const processFiles = findProcessFiles(prdDir);

  if (processFiles.length === 0) {
    // No context to inject — exit cleanly
    process.stderr.write('[SessionStart] 🆕 No process.txt found. Fresh session.\n');
    process.exit(0);
  }

  // Most recently modified first
  processFiles.sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);

  const sections = [];
  for (const file of processFiles) {
    const content = fs.readFileSync(file, 'utf8').trim();
    if (!content) continue;
    const relPath = path.relative(cwd, file);
    sections.push(`=== ${relPath} ===\n${content}`);
  }

  if (sections.length === 0) {
    process.exit(0);
  }

  const additionalContext =
    '🧠 [会话恢复] 以下是上次会话的状态记录，请在开始任务前阅读并恢复上下文：\n\n' +
    sections.join('\n\n') +
    '\n\n[SessionStart] ✅ 上下文恢复完成。';

  // Inject context via stdout JSON — this is the correct Claude Code protocol.
  // Claude Code reads this and prepends additionalContext to the session prompt.
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext,
      },
    })
  );

  process.stderr.write(
    `[SessionStart] 🧠 Injected ${sections.length} process.txt file(s) into session context.\n`
  );
}

try {
  main();
} catch (err) {
  // Never crash the session — just log and continue
  process.stderr.write(`[SessionStart] ⚠️ Hook error (non-fatal): ${err.message}\n`);
  process.exit(0);
}
