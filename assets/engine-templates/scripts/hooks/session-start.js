#!/usr/bin/env node

/**
 * SessionStart Hook — Memory Injection
 *
 * Fires when a new Claude Code session starts (SessionStart event).
 * Scans docs/prd/ for all process.txt AND process.md files and injects
 * their contents into the session context so Claude can restore memory.
 *
 * For process.md files, extracts YAML frontmatter to provide structured
 * stage/status information for intelligent workflow resumption.
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
 * Recursively find files matching a target name under a directory.
 * Returns paths sorted by most recently modified first.
 */
function findFiles(dir, targetName) {
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
      results.push(...findFiles(fullPath, targetName));
    } else if (entry.name === targetName) {
      results.push(fullPath);
    }
  }
  return results;
}

/**
 * Extract YAML frontmatter from markdown content (zero dependencies).
 * Returns an object of key-value pairs, or null if no frontmatter found.
 */
function extractFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return null;

  const data = {};
  match[1].split('\n').forEach(line => {
    const colonIdx = line.indexOf(':');
    if (colonIdx === -1) return;
    const key = line.slice(0, colonIdx).trim();
    const value = line.slice(colonIdx + 1).trim();
    if (key && value) data[key] = value;
  });
  return Object.keys(data).length > 0 ? data : null;
}

function main() {
  // --- Scan process.txt files (legacy format) ---
  const processTxtFiles = findFiles(prdDir, 'process.txt');

  // --- Scan process.md files (new format with YAML frontmatter) ---
  const processMdFiles = findFiles(prdDir, 'process.md');

  if (processTxtFiles.length === 0 && processMdFiles.length === 0) {
    process.stderr.write('[SessionStart] 🆕 No process files found. Fresh session.\n');
    process.exit(0);
  }

  const sections = [];

  // --- Process .txt files (inject full content) ---
  if (processTxtFiles.length > 0) {
    processTxtFiles.sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);

    for (const file of processTxtFiles) {
      const content = fs.readFileSync(file, 'utf8').trim();
      if (!content) continue;
      const relPath = path.relative(cwd, file);
      sections.push(`=== ${relPath} ===\n${content}`);
    }
  }

  // --- Process .md files (extract YAML stage + inject summary) ---
  const stageSummaries = [];

  if (processMdFiles.length > 0) {
    processMdFiles.sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);

    for (const file of processMdFiles) {
      const content = fs.readFileSync(file, 'utf8').trim();
      if (!content) continue;

      const relPath = path.relative(cwd, file);
      const frontmatter = extractFrontmatter(content);

      if (frontmatter && frontmatter.stage) {
        // Build structured status line
        const parts = [`stage=${frontmatter.stage}`];
        if (frontmatter.source) parts.push(`source=${frontmatter.source}`);
        if (frontmatter.owner) parts.push(`owner=${frontmatter.owner}`);
        if (frontmatter.last_updated) parts.push(`updated=${frontmatter.last_updated}`);

        const featureId = frontmatter.feature_id || path.basename(path.dirname(path.dirname(file)));
        stageSummaries.push(`🧠 [项目状态] ${featureId}: ${parts.join(', ')}`);
      }

      // Also inject the full content for detailed context
      sections.push(`=== ${relPath} ===\n${content}`);
    }
  }

  if (sections.length === 0 && stageSummaries.length === 0) {
    process.exit(0);
  }

  // Build the injected context
  let additionalContext = '';

  // Stage summaries at the top for quick scanning
  if (stageSummaries.length > 0) {
    additionalContext += stageSummaries.join('\n') + '\n\n';
  }

  additionalContext +=
    '🧠 [会话恢复] 以下是上次会话的状态记录，请在开始任务前阅读并恢复上下文：\n\n' +
    sections.join('\n\n') +
    '\n\n[SessionStart] ✅ 上下文恢复完成。';

  // Inject context via stdout JSON
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext,
      },
    })
  );

  const txtCount = processTxtFiles.filter(f => {
    const c = fs.readFileSync(f, 'utf8').trim();
    return c.length > 0;
  }).length;
  const mdCount = processMdFiles.filter(f => {
    const c = fs.readFileSync(f, 'utf8').trim();
    return c.length > 0;
  }).length;

  process.stderr.write(
    `[SessionStart] 🧠 Injected ${txtCount} process.txt + ${mdCount} process.md file(s) into session context.\n`
  );
}

try {
  main();
} catch (err) {
  // Never crash the session — just log and continue
  process.stderr.write(`[SessionStart] ⚠️ Hook error (non-fatal): ${err.message}\n`);
  process.exit(0);
}
