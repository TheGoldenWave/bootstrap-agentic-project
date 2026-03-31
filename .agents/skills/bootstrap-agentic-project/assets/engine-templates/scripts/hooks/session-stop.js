#!/usr/bin/env node

/**
 * Stop Hook — Progress Checkpoint Reminder
 *
 * Fires when Claude is about to end its response (Stop event).
 * On first invocation: exit 2 to inject a reminder and keep Claude active.
 * On second invocation (stop_hook_active: true): exit 0 to allow stop.
 *
 * This gives Claude exactly one chance to save progress before the session ends.
 *
 * Wired in settings.json:
 *   hooks.Stop
 */

const fs = require('fs');
const path = require('path');

let input;
try {
  input = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
} catch (_) {
  process.exit(0);
}

// stop_hook_active = true means we already fired once this cycle.
// Let Claude stop to avoid an infinite loop.
if (input?.stop_hook_active) {
  process.exit(0);
}

const cwd = process.cwd();
const prdDir = path.join(cwd, 'docs', 'prd');

// Only prompt if the project has the prd structure set up
if (!fs.existsSync(prdDir)) {
  process.exit(0);
}

// Check if there are any process.txt files in the project
function hasProcessFiles(dir) {
  if (!fs.existsSync(dir)) return false;
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch (_) {
    return false;
  }
  for (const entry of entries) {
    if (entry.isDirectory() && hasProcessFiles(path.join(dir, entry.name))) return true;
    if (entry.name === 'process.txt') return true;
  }
  return false;
}

if (!hasProcessFiles(prdDir)) {
  process.exit(0);
}

// Inject a checkpoint reminder — Claude will see this and can respond before stopping
console.error(
  '[Checkpoint] 📌 即将结束会话。在结束前，请确认以下两项：\n' +
  '1. 已将本次会话的进度（当前阶段、下一步计划）更新到对应功能目录的 process.txt\n' +
  '2. 遇到的问题或踩坑已记录到同目录的 notes.md\n\n' +
  '如已完成，回复"已保存"即可。如尚未完成，请立即执行写入操作。'
);
process.exit(2); // Force Claude to respond before session ends
