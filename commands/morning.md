---
description: Regenerate wiki/now.md, update active project _state.md files, surface today's priorities
model: opus
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /brain:morning — Daily triage

Run this first thing. Rebuilds `wiki/now.md` from fresh data so you open it and know exactly what to do.

## Instructions for Claude

### Step 1: Detect brain and date

Brain path: `$BRAIN_DIR` or `~/brain`. Today's date: system date (`YYYY-MM-DD`).

### Step 2: Suggest ingestion if stale

Check when `raw/jira/` and `raw/prs/` were last populated (newest file mtime). If either is >24h old:

```
Heads up: JIRA raw last ingested {age}. PRs last ingested {age}.
Want me to run /brain:ingest-jira and /brain:ingest-prs first? (yes/no/skip)
```

If yes, invoke those flows first (the user can also run them manually). If no/skip, proceed with stale data and note it in the output.

### Step 3: Read the inputs

- All of `$BRAIN/lessons/*.md` (for context on preferences/gotchas that affect prioritization)
- Each active project's `wiki/projects/<name>/_state.md`
- Most recent `raw/daily/YYYY-MM-DD.md` (yesterday's notes if present)
- Recent `raw/jira/*.md` files (mtime within 48h) — extract: tickets blocked on you, tickets waiting on others, newly assigned
- Recent `raw/prs/*.md` files — extract: PRs open, reviews requested of you, comments on your PRs
- Calendar/meetings in `raw/meetings/` for today's date (if the user pastes a calendar export, pick it up)

### Step 4: Synthesize today's priorities

Apply prioritization rules — in order:

1. **Blocking others** — PRs review-requested of you for >1 day, questions waiting on you in tickets
2. **Today-dated deadlines** — anything with a date in metadata matching today
3. **Oncall items** — if user is on active rotation (check `wiki/topics/oncall.md` or `raw/daily/` for a note)
4. **In-flight project work** — top item from each active project's "Next moves"
5. **Waiting-on-others follow-ups** — anything stuck >3 days

Cap at 5 items. If more than 5 qualify, note that explicitly ("3 more items queued — see project _state files").

### Step 5: Regenerate `wiki/now.md`

Overwrite `$BRAIN/wiki/now.md` with this structure (remove STALE header if present):

```markdown
# Now — YYYY-MM-DD

_Generated HH:MM by /brain:morning. Regenerate tomorrow._

## Today (top 5)
1. [source] — action — why/context — link
2. ...

## Active across projects
- **project-a:** one-line current focus → [_state.md](projects/project-a/_state.md)
- **project-b:** ...
- **project-c:** ...
- **project-d:** ...

## Waiting on others
- <thing> — person — since YYYY-MM-DD
- ...

## Recently landed (last 3 days)
- YYYY-MM-DD — PR#X merged / decision / meeting outcome
- ...

## Oncall context
{if on active rotation: rotation name, top recent incidents from topics/oncall.md, top runbooks}
{else: "Not on oncall this week."}

## Stale data notice
{if ingestion was skipped and data is stale, list here. Otherwise omit section.}
```

### Step 6: Update project `_state.md` files

For each of project-a, project-b, project-c, project-d:

- Refresh "Recent PRs / tickets" section from raw/ for that project (last 7 days)
- Refresh "Recent meetings" section from raw/meetings/ with `projects:` matching
- Update "Last updated: YYYY-MM-DD"
- Leave "In flight now", "Blockers", "Next moves" as-is unless new raw evidence clearly changes them — if it does, update and note the change in output

Use targeted Edits, not whole-file rewrites, to avoid churn.

### Step 7: Output

```
══════════════════════════════════════════════
 MORNING BRIEF — YYYY-MM-DD HH:MM
══════════════════════════════════════════════

TOP 5 TODAY:
1. ...
2. ...

ACTIVE:
- project-a: ...
- project-b: ...
- project-c: ...
- project-d: ...

WAITING ON:
- ...

UPDATED:
- wiki/now.md
- wiki/projects/project-a/_state.md (added N items)
- wiki/projects/project-b/_state.md
- ...

{Stale warnings if any.}

Open wiki/now.md to see the full view.
```

## Notes

- `now.md` is authoritative only for today. If the user runs this again mid-day, regenerate with whatever's new.
- Don't invent priorities. If there's nothing urgent, say so: "Light day. Top items are routine follow-ups."
- Respect lessons/preferences.md — if a preference says "I protect Tuesday mornings for deep work," factor that in.
