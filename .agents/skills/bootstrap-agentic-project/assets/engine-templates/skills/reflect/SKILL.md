---
name: reflect
description: Consolidate project knowledge by scanning feature notes and experience files, then updating the structured team knowledge index (docs/context/INDEX.md). Use after completing a feature, fixing a tricky bug, or when session-stop suggests running it.
user-invocable: true
argument-hint: "[scan|promote|status]"
---

# /reflect — Knowledge Consolidation

Scan project knowledge sources for un-indexed entries and update the team knowledge index (`docs/context/INDEX.md`).

## When to Use

- After completing a feature or significant bugfix
- When `session-stop` hook suggests it (notes.md was recently modified)
- Periodically to keep the knowledge base current
- Before onboarding a new team member to ensure INDEX is up-to-date

## Step 1: Load Current Index

Read `docs/context/INDEX.md`. Parse each category table (架构决策, Bug 模式, 设计模式, 领域知识, 环境与工具) and extract the `详情` (detail path) column values into a set of **already-indexed paths**.

If `docs/context/INDEX.md` doesn't exist, inform the user to run the bootstrap first (`/C-startup` or `bash .claude/scripts/init.sh`-equivalent).

## Step 2: Scan for Un-indexed Entries

Scan three knowledge source locations:

### 2a. Feature notes
Glob `docs/prd/**/notes.md` and `docs/prd/**/.artifacts/notes.md`. For each file:
- Read content, split by `## ` headers — each section header is a candidate entry
- Check if the file path already appears in INDEX.md — skip if indexed
- Extract a one-line summary from the first non-empty line after the header

### 2b. Experience files
Glob `docs/context/project/experience/**/*.md`. Each file is a candidate:
- Check if its path already appears in INDEX.md — skip if indexed
- Extract title from first `# ` header or filename

### 2c. Blockers from process files (optional)
Glob `docs/prd/**/process.md` and `docs/prd/**/process.txt`. Look for blocker entries:
- In process.md: scan the blocker table for rows with status ≠ "已解决"
- These are potential Bug Pattern entries once resolved

## Step 3: Classify and Present

For each un-indexed candidate, propose a category based on keyword matching:

| Keywords | Category |
|----------|----------|
| 架构, 选型, 模式, pattern, architecture, database, 数据库, API 设计 | 🏗️ 架构决策 |
| bug, 错误, crash, 异常, 边界, race condition, 并发, 失败 | 🐛 Bug 模式 |
| 组件, 封装, 抽象, hook, 工具函数, utility, 复用 | 🧩 设计模式 |
| 业务, 规则, 流程, 用户, 产品, 需求, 域 | 📚 领域知识 |
| CI, 部署, 环境, 版本, 工具, 配置, 脚本 | 🔧 环境与工具 |

Present a numbered list to the user:

```
发现 N 条未索引的知识条目：

1. [🐛 Bug 模式] 并发写入导致乐观锁冲突 — 来源: docs/prd/FEAT-002/.artifacts/notes.md
2. [🏗️ 架构决策] 选用 Redis 做分布式锁 — 来源: docs/context/project/experience/redis-lock.md
3. ...

请确认要添加到 INDEX.md 的条目编号（如: 1,2,3 或 all），或输入 skip 跳过。
```

Use `AskUserQuestion` to get confirmation.

## Step 4: Append to INDEX

For each confirmed entry, append a new table row to the corresponding category in `docs/context/INDEX.md`:

```markdown
| {today's date} | {source feature_id} | {summary ≤ 60 chars} | {relative path to detail file} |
```

Rules:
- Never delete or modify existing rows — append only
- Keep summaries ≤ 60 characters
- Use the detail file's relative path from project root
- Preserve table alignment (pad with spaces if needed)

## Step 5: Promote (Optional)

If the `promote` argument is given, or if the user confirms during Step 3:

For feature-level notes (`docs/prd/{feature}/notes.md` or `.artifacts/notes.md`) that have team-wide reuse value:
1. Extract the relevant section
2. Create a new file under `docs/context/project/experience/{descriptive-name}.md`
3. The new file should have a `# Title` and the distilled content (not a raw copy)
4. The INDEX.md entry should point to this new promoted file

## Sub-commands

- `/reflect` or `/reflect scan` — Run Steps 1-4 (scan + index update)
- `/reflect promote` — Run Steps 1-5 (scan + index + promote to experience/)
- `/reflect status` — Show stats: total indexed entries per category, last update date, coverage (indexed vs total knowledge files)

## Execution Rules

1. **Never modify INDEX.md without user confirmation** — always present the list first
2. **Preserve existing table structure** — append rows, don't restructure
3. **Be conservative with classification** — when unsure, ask the user which category fits
4. **Date format**: YYYY-MM-DD
5. **Idempotent**: running `/reflect` twice should produce no duplicates (path-based dedup)
