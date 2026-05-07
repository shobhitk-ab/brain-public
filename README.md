# claude-brain

A personal second brain for software engineers, maintained by Claude Code. Tickets, PRs, meetings, decisions, and corrections all flow into structured markdown that Claude reads at the start of every session — so it never repeats the same mistake and your annual review doc isn't a blank page at year-end.

Built for [Claude Code](https://claude.ai/code). Designed as a **shareable template**: fork it, clone it, run `/brain:setup` once, and your personal data stays local while the prompt logic stays in sync with upstream.

---

## What it does

- **Remembers across sessions.** `lessons/` (mistakes, preferences, patterns, gotchas) is read into context at every session start. Earned from real corrections, never drafted.
- **Tracks what matters.** JIRA tickets, PRs, meetings, decisions — all ingested into structured markdown you can search.
- **Keeps you current.** Every morning, a tight summary of today's priorities synthesized from everything that came in.
- **Fills your review doc as you go.** `/brain:log-review` and `/brain:compress` accumulate evidence-backed entries. `/brain:draft-review` synthesizes a polished draft.

---

## Quick start

```bash
# 1. Clone
git clone https://github.com/<you>/claude-brain ~/brain

# 2. Install commands (creates ~/.claude/commands/brain symlink)
bash ~/brain/install.sh

# 3. Open Claude Code in ~/brain (or anywhere — commands work globally)
cd ~/brain
claude

# 4. Onboard — walks you through identity, GitHub auth, Atlassian MCP, JIRA defaults
/brain:setup

# 5. First session
/brain:resume
```

That's it. `/brain:setup` writes `brain.config.yaml` (gitignored) with your identity and integration config. The rest of the repo is generic.

### Prerequisites

- [Claude Code](https://claude.ai/code) installed.
- `gh` CLI installed and authenticated: `gh auth login`.
- Optional but recommended: claude.ai Atlassian MCP authenticated (used by `/brain:ingest-jira`).

---

## Daily workflow

### Morning (30 seconds)
```
/brain:morning
```
Pulls fresh JIRA + PR data if stale, updates each project state, rewrites `wiki/now.md` with today's top 5.

### Starting any Claude session
```
/brain:resume
```
Loads everything Claude needs to operate with your context. Run this even when working outside `~/brain`.

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
Routes to `raw/inbox/`. No thinking required.

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
| `/brain:setup` | First-time onboarding (or to update settings) |
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
| Random ideas | `raw/inbox/` | `/brain:capture` or just tell Claude |
| Meeting notes | `raw/meetings/` | Dictate or paste; Claude writes |
| Daily log | `raw/daily/<date>.md` | Claude appends as you work |
| JIRA snapshots | `raw/jira/` | `/brain:ingest-jira` (daily) |
| PR snapshots | `raw/prs/` | `/brain:ingest-prs` (daily) |
| Design docs | `raw/docs/` | Paste or `/brain:capture` |
| Decisions | `wiki/decisions/` | `/brain:preserve` → decision |
| Lessons | `lessons/*.md` | `/brain:preserve` → mistake / preference |
| Review entries | `wiki/reviews/` | `/brain:log-review` or `/brain:compress` |
| People context | `wiki/people/<Name>.md` | `/brain:preserve` → person note |

---

## Sharing the brain

The repo is structured so you can fork it as a template and have everything *non-personal* track upstream while your data stays local.

**Committed (shareable):**
- `CLAUDE.md`, `README.md`, `install.sh`
- `commands/*.md` (the prompt logic)
- `wiki/projects/_template/` (the scaffold for new projects)
- Empty stub directories with `.gitkeep`

**Gitignored (personal):**
- `brain.config.yaml` (your identity + integrations)
- `raw/*` (everything you ingest)
- `wiki/projects/*` except `_template/` (your real projects)
- `wiki/people/*`, `wiki/reviews/*` (sensitive)
- `lessons/*` content (your earned corrections)

To pull upstream improvements: `git pull` brings new command logic without touching your personal data.

---

## Three discipline points that make it work

1. `/brain:preserve` when corrected. Miss this and the brain stops learning.
2. `/brain:log-review` when something ships. Miss this and your review file stays thin.
3. `/brain:morning` most days. Miss this and `now.md` goes stale.

---

## License

MIT. Fork and fill in your own brain.
