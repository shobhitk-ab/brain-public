# claude-brain

A personal second brain for software engineers, maintained by Claude. Everything about your work flows in here; Claude files things, remembers mistakes, and keeps your review doc populated so you never face a blank page at mid-year.

Built for [Claude Code](https://claude.ai/code). Works in any repo Claude Code can see.

---

## What it does

- **Remembers across sessions.** Lessons from corrections are loaded every time, so Claude does not repeat the same mistakes.
- **Tracks what matters.** JIRA tickets, PRs, meetings, decisions — all ingested into structured markdown you can search.
- **Keeps you current.** Every morning, a tight summary of today's priorities synthesized from everything that came in.
- **Fills your review doc as you go.** `/brain:log-review` takes 10 seconds and saves days at annual review time.

---

## Quick start

```bash
# 1. Clone
git clone https://github.com/<you>/claude-brain ~/brain

# 2. Install commands into Claude Code
~/brain/install.sh

# 3. Personalize
#    - Edit CLAUDE.md: replace "project-a / project-b" with your actual project names
#    - Edit commands/ingest-jira.md: add your JIRA project key -> brain project mappings
#    - Edit commands/ingest-prs.md: add your repo names to the filter

# 4. Add your first project
cp -r ~/brain/wiki/projects/_template ~/brain/wiki/projects/<your-project>

# 5. Start using it
# Open Claude Code and run:
/brain:resume
```

---

## Daily workflow

### Morning (30 seconds)
```
/brain:morning
```
Pulls fresh JIRA + PR data if stale, updates each project state, rewrites wiki/now.md with today's top 5.

### Starting any Claude session
```
/brain:resume
```
Loads everything Claude needs to operate with your context. Run this even when working outside ~/brain.

### Switching into focused project work
```
/brain:switch <project>
```
Loads that project's state, gotchas, recent decisions.

### When Claude gets something wrong
Correct it, then:
```
/brain:preserve
```
This is the only moment the brain actually learns. Do not skip it.

### Quick idea dump
```
/brain:capture <idea>
```
Routes to raw/inbox/. No thinking required.

### When something ships or you drive something notable
```
/brain:log-review execution      # or impact | leadership | craft
```
10 seconds now saves 3 days at review time.

### End of any substantive session
```
/brain:compress
```
Writes session log, proposes review entries, flags lessons.

### Weekly
```
/brain:lint
```
Finds contradictions, stale state, processes inbox into wiki.

### At review time
```
/brain:draft-review
```
Produces a polished draft in a structured format from everything accumulated.

---

## All commands

| Command | Use when |
|---|---|
| `/brain:resume` | Start of any session |
| `/brain:morning` | First thing in the day |
| `/brain:switch <project>` | About to focus on one project |
| `/brain:capture <thing>` | Quick dump, no conversation needed |
| `/brain:preserve` | Just corrected Claude or made a decision worth keeping |
| `/brain:log-review <bucket>` | Something review-worthy just happened |
| `/brain:ingest-jira` | Daily JIRA pull |
| `/brain:ingest-prs` | Daily PR pull |
| `/brain:compress` | End of a substantive session |
| `/brain:lint` | Weekly vault health + inbox processing |
| `/brain:draft-review` | At review time |

---

## What goes where

You never have to decide. Tell Claude, Claude routes.

| What | Where | How it gets there |
|---|---|---|
| Random ideas | raw/inbox/ | /brain:capture or just tell Claude |
| Meeting notes | raw/meetings/ | Dictate or paste; Claude writes |
| Daily log | raw/daily/YYYY-MM-DD.md | Claude appends as you work |
| JIRA snapshots | raw/jira/ | /brain:ingest-jira (daily) |
| PR snapshots | raw/prs/ | /brain:ingest-prs (daily) |
| Design docs | raw/docs/ | Paste or /brain:capture |
| Decisions | wiki/decisions/ | /brain:preserve -> decision |
| Lessons | lessons/ | /brain:preserve -> mistake/preference |
| Review entries | wiki/reviews/ | /brain:log-review or /brain:compress |
| People context | wiki/people/<Name>.md | /brain:preserve -> person note |

---

## Prerequisites

- Claude Code installed
- gh CLI installed and authenticated (gh auth login)
- Optional: a JIRA MCP integration for /brain:ingest-jira

## JIRA setup

The JIRA ingest command is designed to work with any JIRA MCP tool. After cloning:
1. Open commands/ingest-jira.md
2. Update the project key -> brain project mappings at the bottom of the file
3. Swap in your JIRA MCP tool names if they differ from the reference implementation

If you do not have a JIRA MCP, skip this command and use /brain:capture to route JIRA content manually.

## PR setup

Open commands/ingest-prs.md and update the repo filter with your actual repository names.

---

## Three discipline points that make it work

1. `/brain:preserve` when corrected. Miss this and the brain stops learning.
2. `/brain:log-review` when something ships. Miss this and your review file stays thin.
3. `/brain:morning` most days. Miss this and now.md goes stale.

---

## License

MIT. Fork and fill in your own brain.
