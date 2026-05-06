---
description: Load brain context at start of session — CLAUDE.md + lessons + recent sessions + optional topic search
model: opus
allowed-tools: Read, Glob, Bash
---

# /brain:resume — Load context

**Usage:**
- `/brain:resume` — CLAUDE.md + all lessons + last 3 session summaries + current `now.md`
- `/brain:resume 7` — same but last 7 sessions
- `/brain:resume project-a` — also load project-a project context + topic search for "project-a"
- `/brain:resume 5 migration` — last 5 sessions + search for "migration"

## Instructions for Claude

### Step 1: Parse arguments

Split `$ARGUMENTS` into:
- **N** (integer, default 3, max 50) — number of recent sessions
- **topic** (string, optional) — search keyword OR project name

If topic matches one of `<project-a> | <project-b> | ...`, treat as project filter too.

### Step 2: Find the brain

Default brain path: `~/brain`. If `BRAIN_DIR` env var is set, use that.

Confirm existence of `$BRAIN/CLAUDE.md`. If missing, stop and tell user the brain isn't set up here.

### Step 3: Read in this order

1. **`$BRAIN/CLAUDE.md`** — orchestration rules. Absorb them.
2. **All of `$BRAIN/lessons/*.md`** — mistakes, preferences, patterns, gotchas. These are durable memory.
3. **`$BRAIN/wiki/now.md`** — today's priorities. If the file header says STALE, flag that in output.
4. **`$BRAIN/wiki/projects/index.md`** — one-line status per project.
5. **Recent session logs:** `ls -1 $BRAIN/sessions/*.md 2>/dev/null | sort -r | head -N`. For each, read only the content BEFORE `## Raw Session Log` (summary only — saves tokens).
6. **If topic is a project name:** also read `$BRAIN/wiki/projects/<topic>/_state.md` and `$BRAIN/wiki/projects/<topic>/gotchas.md`.
7. **If topic is provided and not already covered:** `grep -l -i "<topic>" $BRAIN/sessions/*.md $BRAIN/wiki/projects/*/_state.md $BRAIN/wiki/decisions/*.md` — read the matching files' summaries (top 5).

### Step 4: Output a tight briefing

```
══════════════════════════════════════════════
 BRAIN LOADED — {YYYY-MM-DD}
══════════════════════════════════════════════

NOW: {one-line state from now.md, or "now.md is STALE — run /brain:morning"}

ACTIVE PROJECTS:
- project-a: {status from _state.md}
- project-b: {status}
- project-c: {status}
- project-d: {status}

LESSONS IN MEMORY:
- {N} mistakes, {N} preferences, {N} patterns, {N} gotchas loaded

RECENT SESSIONS ({N}):
- YYYY-MM-DD — topic — one-line outcome
- ...

{If topic search performed:}
RELATED TO "{topic}":
- file — why it matched

READY. What are we doing?
```

Keep it under 30 lines of output. The user wants to start working, not read a novel.

### Step 5: Flag stale state

If any of the following is true, mention it:
- `now.md` header says STALE or was last modified >24h ago
- Any project `_state.md` last modified >7 days ago while recent raw/ ingestion shows activity
- `raw/jira/` or `raw/prs/` hasn't been updated in >2 days

Suggest `/brain:morning` or `/brain:ingest-*` as appropriate.
