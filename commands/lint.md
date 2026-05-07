---
description: Weekly vault health check — stragglers, stale state, contradictions, promotable patterns, inbox processing
model: opus
allowed-tools: Read, Edit, Write, Bash, Glob, Grep, AskUserQuestion
---

# /brain:lint — Weekly vault health check

Finds inconsistencies, stale content, and opportunities to evolve the brain. Non-destructive by default — produces a report, then offers a small set of actions you can opt into.

## Instructions for Claude

### Step 1: Resolve brain, load config, discover active projects

Brain path: `$BRAIN_DIR` or `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists.

Load `$BRAIN/brain.config.yaml`. If missing, stop with: `brain.config.yaml not found — run /brain:setup first.`

**Active projects** = `ls $BRAIN/wiki/projects/` minus `_template/` and dotfile entries. If empty, output: `No active projects yet — nothing to lint. Run /brain:track first.` and stop.

**Current review period:** `review.current_period` from config (e.g. `fy26-h1`).

### Step 2: Run all checks (parallel where possible)

Each check below produces a count + a short list of specifics for the report. Most checks are pure reads.

#### 2.1 — Triage stragglers
Find every file with `needs_triage: true` across:
- `$BRAIN/raw/jira/*.md`
- `$BRAIN/raw/prs/*.md`
- `$BRAIN/raw/inbox/*.md`

For each, capture: file path, ingest date, 1-line summary, source (jira/pr/inbox), and `triage_deferred:` flag if present.

#### 2.2 — Stale `_state.md` files
For each active project, compare its `_state.md` `Last updated:` date vs. mtime of the most recent raw file tagged with that project (i.e. `<slug>` appears in any `projects:` frontmatter):
- If raw activity within the last 7 days but state is >7 days stale → flag.

#### 2.3 — Contradictions
- Each project's `_state.md` "Blockers" section. For each blocker that names a JIRA key or PR number, look up the corresponding `raw/` file. If the blocker is marked unresolved but raw shows the ticket as `Done` / PR as `merged` → flag contradiction.
- Each project's "In flight now" entries. For each that names a JIRA key or PR number, if no raw activity in >14 days → flag as possibly stale.

#### 2.4 — Promotable patterns
Read `$BRAIN/wiki/decisions/*.md` and `$BRAIN/wiki/projects/*/decisions/*.md`. Cluster by tag, problem shape, and tool/approach mentioned. If 3+ decisions share a pattern and no matching entry exists in `$BRAIN/lessons/patterns.md` → propose a candidate.

#### 2.5 — Orphan files
- Files in `$BRAIN/raw/` older than 30 days with no backlink from any `wiki/` file → candidates to link or archive.
- Decision files (`wiki/decisions/*.md` or `wiki/projects/*/decisions/*.md`) not referenced in any `_state.md` "Recent decisions" section → may need backlinks.

#### 2.6 — Lesson overlap
Grep `$BRAIN/lessons/mistakes.md` for headings with overlapping keyword sets → flag possible duplicates to merge.

#### 2.7 — Review file health
Current period file: `$BRAIN/wiki/reviews/<review.current_period>.md`.
- Count entries per bucket. Buckets depend on `review.framework`:
  - `linkedin` → Impact / Leadership / Execution / Craft
  - `generic` → outcome-style entries; just count totals
  - `custom` → user-customized buckets if present
- Count days into the period (estimate from period name).
- If Impact / outcome-equivalent has <5 entries and the period is >1 month in → flag thin.
- Entries missing quantification (no numbers, no `%`, no `$`, no time-saved figure) → list them as candidates to revise via `/brain:log-review`.

#### 2.8 — Ingestion cadence
- `raw/jira/` newest mtime; `raw/prs/` newest mtime.
- If JIRA >3 days stale or PRs >2 days stale → flag.

#### 2.9 — Project file drift
For each active project, expected files: `_state.md`, `overview.md`, `references.md`, `gotchas.md`, `matcher.yml`, `sessions/`, `decisions/`, `runbooks/`. If any missing → flag.

Also: any file still containing the literal string `<PROJECT>` (template placeholder that wasn't replaced during scaffolding) → flag.

#### 2.10 — Inbox processing
For each file in `$BRAIN/raw/inbox/` with `status: unprocessed` (regardless of `needs_triage`), produce a one-line summary and a proposed destination:
- `type: link` or `type: snippet` → `wiki/projects/<slug>/references.md` (if project tagged) or `wiki/topics/<topic>.md`
- `type: followup` tied to a project → that project's `_state.md` "Next moves"
- `type: note` with no clear project → `wiki/topics/<best-match>.md`, or propose a new topic
- Older than 30 days, no clear destination → propose `raw/inbox/_archive/`

Never auto-move. These are proposals, gated by Step 4 approval.

### Step 3: Report

```
══════════════════════════════════════════════
 VAULT LINT — YYYY-MM-DD
══════════════════════════════════════════════

TRIAGE STRAGGLERS:
  <N> JIRA tickets, <N> PRs, <N> inbox items unassigned
  <N> deferred (triage_deferred: true) — waiting on /brain:track project creation
  → Run "Triage now" below to walk through interactively

STALE STATE:
  - <slug>/_state.md: last updated YYYY-MM-DD, but <N> raw items since
    → Refresh via /brain:morning

CONTRADICTIONS:
  - <slug>/_state.md says "blocked on <KEY>", but <KEY> is Done (raw/jira/<file>)
  - <slug>/_state.md "In flight now" lists "<title>" — no activity in <N> days

PROMOTABLE PATTERNS:
  - <N> decisions share a pattern: <description>
    → Promote to lessons/patterns.md?

ORPHANS:
  - <N> raw files >30 days with no backlinks
  - <N> decisions not linked from any _state.md

REVIEW HEALTH (<period>):
  Buckets: <bucket>: N · <bucket>: N · ...
  <bucket> is thin (<N> after <M> months)
  <N> entries missing quantification

INGESTION:
  JIRA last ingested <age>; PRs last ingested <age>
  → /brain:ingest-jira / /brain:ingest-prs

PROJECT FILE DRIFT:
  - <slug> missing matcher.yml
  - <slug>/_state.md still contains "<PROJECT>" placeholder

LESSON OVERLAP:
  - "<entry-1>" and "<entry-2>" overlap on keywords <list> — merge?

INBOX (<N> unprocessed):
  - <file> → propose: <destination>
  - ...

══════════════════════════════════════════════
```

If a section has zero items, omit it.

### Step 4: Offer actions

Use AskUserQuestion (multi-select):

- Question: `What do you want to act on? (pick any)`
- Options:
  - `Triage now (interactive — walk through unassigned items)`
  - `Promote pattern candidates`
  - `Backlink or archive orphans`
  - `Process inbox proposals (one by one)`
  - `Refresh stale _state.md files via /brain:morning`
  - `Run staleness ingest (/brain:ingest-jira and /brain:ingest-prs)`
  - `Skip — report only`

Act only on items the user picks. Never prune, delete, or batch-modify without explicit per-item approval.

### Step 5: Triage sweep (if picked)

Walk through every `needs_triage: true` item in batches of 5. For each item, show its 1-line summary then ask:

- Question: `Project for this item?`
- Options:
  - `<active-project-1>` (recommended if matcher hint applied — show the hint)
  - `<active-project-2>`
  - `<active-project-3>`
  - `<active-project-4>`
  - `Create new project — handle in /brain:track later`
  - `Skip`
  - `Archive — this is no longer relevant`

Per pick:
- Project assignment: Edit the raw file's frontmatter (`projects: [<slug>]`, `needs_triage: false`, `triaged_via: /brain:lint`, `triaged_on: <today>`). Append to that project's `_state.md` "In flight now" if it's a JIRA ticket or PR; "Next moves" if it's an inbox item.
- Defer to /brain:track: set `triage_deferred: true`. Tell user: `Run /brain:track to create the project, then this'll auto-tag.`
- Skip: leave as-is.
- Archive: move file to `raw/<source>/_archive/<original-filename>`. Don't delete.

After each batch of 5, ask: `Continue with next 5? (y/n)`. Stop on `n` or when no items remain.

#### Optional: JIRA back-fill (sub-prompt during triage)

When the user assigns a project to a JIRA ticket whose `parent_epic` is null AND that project's `matcher.yml` has at least one epic listed:

- Question (after the project pick): `Set parent epic in JIRA to <epic>?`
- Options:
  - `Yes — back-fill JIRA via mcp__claude_ai_Atlassian__editJiraIssue`
  - `No — leave JIRA untouched`

This is the only place lint writes to JIRA. Skip the sub-prompt entirely if the project's matcher has no epics or the project is brand new.

### Step 6: Promote patterns (if picked)

For each candidate the user approves:
- Append a new `## Pattern: <name>` section to `$BRAIN/lessons/patterns.md`.
- Include: when it applies, why it works, and links back to the originating decision files.

### Step 7: Backlink or archive orphans (if picked)

For each orphan, propose a destination via AskUserQuestion (single-select):
- Options: `Link from <project>/_state.md`, `Link from wiki/topics/<topic>.md`, `Move to raw/<source>/_archive/`, `Skip`.

Apply Edits or move per the user's pick. No deletes.

### Step 8: Inbox processing (if picked)

Walk through each unprocessed inbox file. For each, show the proposed destination then ask:
- Options: `Apply proposed destination`, `Pick a different destination`, `Archive`, `Skip`.

Apply Edits per the user's pick. Mark the file's frontmatter `status: processed` after a successful move.

### Step 9: Final summary

```
LINT COMPLETE.

Actions taken:
  - <N> items triaged (assigned to projects)
  - <N> items deferred to /brain:track
  - <N> items archived
  - <N> patterns promoted to lessons/patterns.md
  - <N> orphans backlinked / archived
  - <N> inbox items processed
  - <action> ran: /brain:morning / /brain:ingest-*

Still open (next time or later this week):
  - <N> stragglers remaining (run /brain:lint again or /brain:morning surfaces 5/day)
  - <N> review-thin candidates — log via /brain:log-review
```

## Notes

- **Lint is read-heavy, write-light by default.** Step 3's report is the main artifact. Actions are opt-in.
- **Pattern promotion is the highest-leverage output.** This is how the brain evolves from "decision log" into "library of reusable moves."
- **Triage sweep is the catch-all** for items that bypassed `/brain:track` and weren't surfaced (or were skipped) in `/brain:morning`. Run weekly.
- **JIRA back-fill is opt-in per item.** Lint will never silently update JIRA — always ask.
- **Frequency:** weekly is right. Daily = noise. Monthly = drift.
- **Project list is dynamic.** Read it from `wiki/projects/` at the start of every run. Never hardcode slugs.
