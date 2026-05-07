---
description: Daily triage — regenerate wiki/now.md, refresh project _state.md files, surface stragglers for inline triage
model: opus
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /brain:morning — Daily triage

Run first thing. Rebuilds `wiki/now.md`, refreshes each active project's `_state.md`, and surfaces any items that came in unassigned (`needs_triage: true`) for inline cleanup.

## Instructions for Claude

### Step 1: Resolve brain, load config, detect active projects

Brain path: `$BRAIN_DIR` or `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists.

Load `$BRAIN/brain.config.yaml`. If missing, stop with: `brain.config.yaml not found — run /brain:setup first.`

**Active projects** = directories under `$BRAIN/wiki/projects/`, excluding `_template/` and any entry starting with `.` or `_`. If empty, output: `No active projects yet. Run /brain:track to create your first.` and stop.

Today's date: system date in `YYYY-MM-DD`.

### Step 2: Suggest ingestion if stale

Check when `raw/jira/` and `raw/prs/` were last populated (newest file mtime). If JIRA is >24h old or PRs is >12h old, ask via AskUserQuestion (single-select):

- Question: `Run ingest first? JIRA last ingested <age>; PRs <age>.`
- Options:
  - `Yes — run /brain:ingest-jira and /brain:ingest-prs now`
  - `Skip — use stale data, I'll note it in the brief`

If "Yes," invoke those flows in sequence and wait for completion before continuing. If "Skip," proceed with current data and remember to add a "Stale data" line to the briefing.

### Step 3: Read the inputs

- All `$BRAIN/lessons/*.md` (for prioritization context — gotchas, preferences)
- Each active project's `wiki/projects/<slug>/_state.md`
- Most recent `$BRAIN/raw/daily/YYYY-MM-DD.md` (yesterday's notes if present)
- Recent `$BRAIN/raw/jira/*.md` (mtime within 48h) — extract per-ticket: status, blockers, assignee changes, recent comments
- Recent `$BRAIN/raw/prs/*.md` (mtime within 48h) — extract per-PR: review status, requested reviewers, recent comments, mergeable state
- Today's meetings in `$BRAIN/raw/meetings/<today>-*.md` if any

While reading raw files, also tally items with `needs_triage: true` (used in Step 5).

### Step 4: Synthesize today's priorities

Apply prioritization rules — in order, capped at 5 items total:

1. **Blocking others** — PRs review-requested of you for >24h; comments waiting for your response; questions in tickets assigned to you
2. **Today-dated deadlines** — anything with `today's date` in `due` / `fix_version` / explicit deadline mentions
3. **Oncall items** — if on active rotation (check `wiki/topics/oncall.md` or yesterday's `raw/daily/`)
4. **In-flight project work** — top "Next moves" item from each active project's `_state.md`
5. **Waiting-on-others follow-ups** — anything stuck on someone else >3 days

If fewer than 5 items qualify, that's fine — don't manufacture priorities. If more than 5, note: `(N more queued — see project _state files)`.

Respect `lessons/preferences.md`: if a preference says "deep-work mornings on Tuesdays," surface different items on Tuesdays vs. other days.

### Step 5: Regenerate `wiki/now.md`

Overwrite `$BRAIN/wiki/now.md` (remove any `STALE:` HTML comment if present). Iterate over active projects from Step 1 — no hardcoded list.

```markdown
# Now — YYYY-MM-DD

_Generated HH:MM by /brain:morning. Regenerate tomorrow._

## Today (top 5)
1. [source] — action — why/context — link
2. ...

## Active across projects
- **<slug-1>:** one-line current focus → [_state.md](projects/<slug-1>/_state.md)
- **<slug-2>:** ...
_(one bullet per active project — derived at runtime from `wiki/projects/`)_

## Waiting on others
- <thing> — person — since YYYY-MM-DD
- ...

## Recently landed (last 3 days)
- YYYY-MM-DD — PR#N merged / decision / meeting outcome — link
- ...

## Oncall context
{if on active rotation: rotation name + recent incidents from topics/oncall.md + top runbooks}
{else: "Not on oncall this week."}

## Stale data notice
{Only if Step 2 was skipped — list which raw paths are stale and how stale.}
```

### Step 6: Update each project's `_state.md`

For each active project:

- **Refresh "Recent PRs / tickets":** scan `$BRAIN/raw/jira/*.md` and `$BRAIN/raw/prs/*.md` from the last 7 days where `<slug>` appears in the file's `projects:` list. Replace this section with the latest entries (max 10).
- **Refresh "Recent meetings":** scan `$BRAIN/raw/meetings/*.md` from last 7 days where `<slug>` appears in `projects:`. Replace section with latest entries.
- **Update `Last updated: YYYY-MM-DD`** to today.
- **Preserve "In flight now", "Blockers", "Next moves" as-is** unless new raw evidence clearly changes them. If it does, update via targeted Edit and mention the change in the output (Step 8).

Use targeted Edits, not whole-file rewrites — preserves the user's hand-curated parts.

### Step 7: Surface stragglers for inline triage

If any items in `raw/jira/`, `raw/prs/`, or `raw/inbox/` have `needs_triage: true`:

1. Cap the surface at **5 items per run** (FIFO by ingest date — oldest first). Mention the rest count if any: `+N more — surface tomorrow or run /brain:lint`.

2. For each surfaced item, show its 1-line summary then ask via AskUserQuestion (single-select):

   - Question (with item summary in your message body above): `Project for this item?`
   - Options:
     - `<active-project-1>` (recommended — based on matcher hints if any signal applied)
     - `<active-project-2>`
     - `<active-project-3>` (… up to 4 active projects)
     - `Create new project — handle in /brain:track later`
     - `Skip — leave needs_triage for tomorrow`

3. On a project pick:
   - Update the raw file's frontmatter via Edit: set `projects: [<slug>]` and `needs_triage: false`. Set `triaged_via: /brain:morning` and `triaged_on: <today's date>`.
   - Append the item to that project's `_state.md` "In flight now" section.

4. On "Create new project — handle in /brain:track later": leave `needs_triage: true`, set `triage_deferred: true` on the file, tell the user `Run /brain:track to create the project, then it'll auto-tag.`

5. On "Skip": leave the file as-is. It'll appear again tomorrow.

Don't do JIRA back-fill (setting parent epics, creating tickets) here — that lives in `/brain:track` and `/brain:lint`. Keep morning fast.

### Step 8: Output briefing

```
══════════════════════════════════════════════
 MORNING BRIEF — YYYY-MM-DD HH:MM
══════════════════════════════════════════════

TOP 5 TODAY:
1. ...
2. ...

ACTIVE:
- <slug-1>: <one-line current focus>
- <slug-2>: ...

WAITING ON:
- ...

TRIAGED:
- N items assigned, M deferred to /brain:track, K skipped (will surface tomorrow)
{If no triage happened, omit this section.}

UPDATED:
- wiki/now.md
- wiki/projects/<slug-1>/_state.md (refreshed Recent PRs/tickets, +<N> entries)
- wiki/projects/<slug-2>/_state.md
- ...

{Stale warnings if any.}

Open wiki/now.md to see the full view.
```

## Notes

- **`now.md` is authoritative only for today.** Re-running mid-day is fine — regenerate with whatever's fresh.
- **Never manufacture priorities.** If there are no urgent items, say `Light day. Top items are routine follow-ups.` Don't pad.
- **Respect `lessons/preferences.md`.** If a preference says "I protect Tuesday mornings for deep work," factor that into ordering.
- **Triage is opt-in per item.** The user can answer or skip any prompt. Don't make morning feel like a chore.
- **No JIRA writes from morning.** Triage only updates local raw frontmatter and project `_state.md`. JIRA back-fill (setting parent epics, creating tickets) is a `/brain:track` / `/brain:lint` concern.
- **Project list is dynamic.** Read it from `wiki/projects/` at the start of every run. Never hardcode.
