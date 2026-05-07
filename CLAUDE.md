# Brain — Your personal second brain

This is a personal knowledge repo. Everything you work on flows in here; Claude maintains it; it remembers things across sessions so mistakes don't repeat and reviews don't require reconstruction.

**Owner & integrations:** see `brain.config.yaml` (gitignored). Loaded at session start by `/brain:resume`. If missing, run `/brain:setup` to (re)generate it.
**Active products:** derived from `wiki/projects/` directory listing (excluding `_template/` and dotfiles) at runtime — single source of truth, no duplicate to maintain.
**Today's date:** use the system date; convert all relative dates ("yesterday", "last week") to absolute `YYYY-MM-DD` when writing.

---

## The three layers

```
raw/       firehose — ingested or pasted data, timestamped markdown, never hand-edited
wiki/      compiled — you maintain this. Structured, backlinked, kept current from raw/
lessons/   durable rules — loaded into every session. This is what makes the brain evolve.
```

`raw/` is ugly and append-only. `wiki/` is tight and rewritten. `lessons/` is the memory that persists across everything.

## Full map

```
brain/
├── CLAUDE.md                  # this file — orchestration rules (committed, generic)
├── README.md                  # setup and usage manual
├── brain.config.yaml          # personal identity + integration config (GITIGNORED)
├── install.sh                 # symlinks commands/ into ~/.claude/commands/brain
├── raw/
│   ├── jira/                  # JIRA ticket snapshots (YYYY-MM-DD-KEY.md)
│   ├── prs/                   # PR snapshots (YYYY-MM-DD-repo-NNNN.md)
│   ├── meetings/              # meeting transcripts (YYYY-MM-DD-slug.md)
│   ├── daily/                 # daily notes (YYYY-MM-DD.md)
│   ├── docs/                  # pasted/ingested design docs, RFCs
│   └── inbox/                 # paste anything — process later
├── wiki/
│   ├── index.md               # top-level map
│   ├── now.md                 # today's priorities — REGENERATED every morning
│   ├── projects/
│   │   ├── index.md           # one-line status per project
│   │   ├── _template/         # copy this to onboard a new project
│   │   └── <your-project>/    # one dir per project
│   ├── people/                # one file per person you work with
│   ├── topics/                # cross-cutting knowledge areas
│   ├── decisions/             # ADR-style significant decisions
│   └── reviews/               # half-yearly / annual review files
├── lessons/                   # ALWAYS loaded at session start via /brain:resume
│   ├── mistakes.md            # "don't do X because Y"
│   ├── preferences.md         # how you like things done
│   ├── patterns.md            # recurring structures across work
│   └── gotchas.md             # surprising behaviors in your systems
└── sessions/                  # compressed session logs (YYYY-MM-DD-HHmm-topic.md)
```

---

## Core rules

### Writing conventions
- All dates in `YYYY-MM-DD` format. Never relative.
- Filenames: lowercase, hyphens, no spaces.
- `raw/` files: timestamped, append-only. Never edit them.
- `wiki/` files: maintained, rewritten. These are the truth.
- `lessons/` files: earned from corrections. Don't draft them — grow them.

### What Claude does in this repo
- **Reads** all of `lessons/` at every session start (`/brain:resume`)
- **Writes** `raw/` during ingest commands
- **Rewrites** `wiki/` to reflect current reality
- **Appends** to `sessions/` at end of each session
- **Never** edits `raw/` after initial write
- **Never** deletes files — mark outdated content with a `STALE:` header

### Lessons discipline
Lessons in `lessons/*.md` are the brain's actual memory. They only get written when:
1. You correct Claude on something → `/brain:preserve`
2. Claude proposes a lesson at `/brain:compress` and you accept it

Do not draft lessons from scratch. Do not write "general best practices." Every lesson must trace back to a real incident.

### Session discipline
Every substantive session ends with `/brain:compress`. This:
- Writes a compressed session log to `sessions/`
- Proposes review-worthy entries for `wiki/reviews/`
- Flags any lessons worth saving

If you skip this, the work is lost.

---

## Initial setup

For a brand-new clone of this brain template, run `/brain:setup` once. It walks you through identity, GitHub auth, Atlassian MCP auth, JIRA defaults, and writes `brain.config.yaml`.

## Adding a project

```bash
cp -r wiki/projects/_template wiki/projects/<your-project>
# edit wiki/projects/<your-project>/overview.md
# add a line to wiki/projects/index.md
```

The active project list is read at runtime from `wiki/projects/`. No CLAUDE.md edit needed.

---

## JIRA integration

`/brain:ingest-jira` is wired to the **claude.ai Atlassian MCP** (`mcp__claude_ai_Atlassian__*`). Cloud ID, account ID, and default project key live in `brain.config.yaml`.

If you don't have a JIRA MCP, skip this command. Use `/brain:capture` to paste JIRA content manually.

---

## PR integration

`/brain:ingest-prs` uses the `gh` CLI. Run `gh auth login` if not already authenticated. The default org and your GitHub handle live in `brain.config.yaml`.
