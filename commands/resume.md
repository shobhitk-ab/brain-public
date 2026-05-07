---
description: Load brain context at start of session — CLAUDE.md + lessons + recent sessions + optional topic search
model: opus
allowed-tools: Read, Glob, Bash
---

# /brain:resume — Load context

**Usage:**
- `/brain:resume` — CLAUDE.md + all lessons + last 3 session summaries + current `now.md`
- `/brain:resume 7` — same but last 7 sessions
- `/brain:resume <slug>` — also load that project's `_state.md` + `gotchas.md` + topic search for the slug
- `/brain:resume 5 migration` — last 5 sessions + search for "migration"

## Instructions for Claude

### Step 1: Parse arguments

Split `$ARGUMENTS` into tokens. Treat **any token that parses as an integer** as `N` (number of recent sessions); the remaining token is `topic`.

- `N` defaults to `3`. Clamp to `[1, 50]` — values below or above are silently corrected.
- `topic` is optional.

The token order is flexible: `/brain:resume 5 migration` and `/brain:resume migration 5` both work.

**Project filter:** after Step 2 builds the active project list (from `ls $BRAIN/wiki/projects/`), check if `topic` exact-matches (case-insensitive) one of those slugs. If yes, treat as a project filter and trigger Step 3.7. Otherwise treat purely as a search keyword (Step 3.8).

### Step 2: Find the brain and discover projects

Default brain path: `~/brain`. If `BRAIN_DIR` env var is set, use that.

Confirm `$BRAIN/CLAUDE.md` exists. If missing, stop and tell user the brain isn't set up here.

Confirm `$BRAIN/brain.config.yaml` exists. If missing, flag in the briefing: `brain.config.yaml not found — run /brain:setup to create it.` Continue loading anyway (commands degrade gracefully).

Build the **active project list:** `ls $BRAIN/wiki/projects/` minus `_template/` and any entry starting with `.` or `_`. Used in Step 1 (project-filter detection) and Step 4 (output briefing).

### Step 3: Read in this order

1. **`$BRAIN/CLAUDE.md`** — orchestration rules. Absorb them.
2. **`$BRAIN/brain.config.yaml`** — user identity + integration config. Hold these in working memory: `user.name`, `user.role`, `user.team`, `user.github_handle`, `jira.cloud_id`, `jira.account_id`, `jira.default_project_key`, `github.default_org`. Other commands rely on these in this session.
3. **All of `$BRAIN/lessons/*.md`** — mistakes, preferences, patterns, gotchas. These are durable memory.
4. **`$BRAIN/wiki/now.md`** — today's priorities. If the file header says STALE, flag that in output.
5. **`$BRAIN/wiki/projects/index.md`** — one-line status per project.
6. **Recent session logs:** sessions now live per-project under `wiki/projects/<slug>/sessions/`. Glob across all projects and pick the most recent N by filename:
   ```bash
   ls -1 $BRAIN/wiki/projects/*/sessions/*.md 2>/dev/null | sort -r | head -N
   ```
   For each, read only the content BEFORE `## Raw session log` (summary only — saves tokens).
7. **If topic is a project name:** also read `$BRAIN/wiki/projects/<topic>/_state.md` and `$BRAIN/wiki/projects/<topic>/gotchas.md`.
8. **If topic is provided and not already covered:** `grep -l -i "<topic>" $BRAIN/wiki/projects/*/sessions/*.md $BRAIN/wiki/projects/*/_state.md $BRAIN/wiki/decisions/*.md 2>/dev/null` — read the matching files' summaries (top 5).

### Step 4: Output a tight briefing

Use the system date for `<today>`. Iterate over the active project list discovered in Step 2 — never hardcode slugs. Pull each project's one-liner status from `wiki/projects/index.md` (not `_state.md`, which we don't read in the no-args path).

```
══════════════════════════════════════════════
 BRAIN LOADED — <today>
══════════════════════════════════════════════

NOW: <one-line state from now.md, or "now.md is STALE — run /brain:morning">

ACTIVE PROJECTS (<count>):
- <slug-1>: <one-liner from wiki/projects/index.md>
- <slug-2>: <one-liner>
- ...
(top 5 only; if more, append "…and <N> more — see wiki/projects/index.md")

LESSONS IN MEMORY:
- <N> mistakes, <N> preferences, <N> patterns, <N> gotchas loaded
(count = number of `## ` headings in each lessons file, minus the file's own H1 title; for gotchas.md count top-level bullets)

RECENT SESSIONS (<N>):
- YYYY-MM-DD — <topic> — <one-line outcome>
- ...
(if zero, render: "RECENT SESSIONS: none yet — run /brain:compress at the end of substantive sessions")

<If topic search performed:>
RELATED TO "<topic>":
- <file> — <why it matched>

<If lessons total = 0:>
TIP: lessons start empty. Run /brain:preserve after corrections to grow durable memory.

READY.
```

Cap output at ~30 lines. If too many active projects, truncate the section as noted (don't expand the cap).

### Step 5: Flag stale state

After the briefing, append warnings (one line each) for any of:

- **`now.md` is stale.** Detected by: the file's first 3 lines contain `<!-- STALE:` (HTML comment, the format `morning` removes when regenerating) **or** the file's `# Now — YYYY-MM-DD` header date is older than today **or** mtime is >24h old. Suggest `/brain:morning`.
- **Any project `_state.md` is stale relative to its raw activity.** For each active project, compare its `_state.md` mtime against the newest mtime among `raw/jira/`, `raw/prs/`, `raw/meetings/` files whose `projects:` frontmatter contains the project slug. If raw is fresh (last 7 days) but `_state.md` is >7 days old → flag and suggest `/brain:morning`.
- **Ingestion is stale.** Newest mtime in `raw/jira/` or `raw/prs/` is >2 days old → flag and suggest the matching `/brain:ingest-*`.

Skip a warning entirely if its data isn't yet meaningful (e.g., no raw files exist yet for a fresh brain).
