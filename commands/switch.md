---
description: Switch into a specific project — load state, gotchas, recent decisions, relevant lessons
model: opus
allowed-tools: Read, Bash, Glob, Grep
---

# /brain:switch — Load project context

**Usage:** `/brain:switch <slug>` — e.g. `/brain:switch auth-rewrite`

Loads everything needed to work productively on one project. Use when you're about to dive into focused work.

## Instructions for Claude

### Step 1: Resolve brain path and validate argument

Brain path: `$BRAIN_DIR` env var, or default `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists (`test -f`). If not, stop with: `No brain at <path> — set BRAIN_DIR or run from a brain directory.`

Build the **valid project list**: `ls $BRAIN/wiki/projects/`, then drop `_template` and any entry starting with `.` or `_`. The remaining names are the only valid `<project>` arguments.

Validate `$ARGUMENTS`:
- **Empty:** print the valid project list and ask the user which. Do not assume.
- **Exact match (case-insensitive)** against a valid project name: proceed with the canonical lowercase form.
- **No match:** print the valid project list and ask the user to pick. Do not auto-suggest "closest match" — the project list is short, fuzzy matching adds risk.

### Step 2: Read the project stack

In order:

1. `wiki/projects/<name>/_state.md` — current state
2. `wiki/projects/<name>/overview.md` — what it is (skim)
3. `wiki/projects/<name>/gotchas.md` — project landmines
4. `wiki/projects/<name>/references.md` — where things live
5. Most recent 3 files in `wiki/projects/<name>/decisions/` (by filename date)
6. Recent raw/ for this project — grep frontmatter `project: <name>` in `raw/jira/`, `raw/prs/`, `raw/meetings/`, last 7 days

### Step 3: Also load

- **All of `lessons/*.md`** — already loaded if `/brain:resume` ran, but reconfirm
- **Sessions tagged with this project:** `grep -l "projects:.*<name>" sessions/*.md | sort -r | head -3` — read the summaries

### Step 4: Output focused briefing

```
══════════════════════════════════════════════
 SWITCHED TO: <project>
══════════════════════════════════════════════

PHASE: {from _state.md}
LAST UPDATED: {from _state.md}

IN FLIGHT:
- {bullet from _state.md}

BLOCKERS:
- {bullet from _state.md}

RECENT DECISIONS:
- YYYY-MM-DD — title — link
- ...

GOTCHAS (do not re-learn):
- {top 3–5 from project gotchas.md}

RECENT ACTIVITY (last 7 days):
- N JIRA updates, M PR events, K meetings — see raw/

NEXT MOVES (from _state.md):
1. ...
2. ...

READY. What are we doing on <project>?
```

