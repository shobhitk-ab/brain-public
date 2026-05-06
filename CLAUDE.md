# Brain — Your personal second brain

This is a personal knowledge repo. Everything you work on flows in here; Claude maintains it; it remembers things across sessions so mistakes don't repeat and reviews don't require reconstruction.

**Owner:** you — fill in your name, role, and context here.
**Active products:** list your main projects here (e.g. project-a, project-b).
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
├── CLAUDE.md                  # this file — orchestration rules
├── README.md                  # setup and usage manual
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

## Project setup

To add a new project:

```bash
cp -r wiki/projects/_template wiki/projects/<your-project>
```

Then edit `wiki/projects/<your-project>/overview.md` with the project context. Update `wiki/projects/index.md` with a one-line status.

Also update this file (`CLAUDE.md`) to add your project name to the **Active products** line at the top — this is how Claude knows which projects to surface in morning briefings and session summaries.

---

## JIRA integration

`/brain:ingest-jira` requires a JIRA MCP tool. Options:
- If you're at LinkedIn: Captain MCP is pre-configured (see the LinkedIn variant of this brain)
- Otherwise: use any JIRA MCP integration and update `commands/ingest-jira.md` with your project key → brain-project mappings

If you don't have a JIRA MCP, skip this command. Use `/brain:capture` to paste JIRA content manually.

---

## PR integration

`/brain:ingest-prs` uses the `gh` CLI. Run `gh auth login` if not already authenticated.

Update the filter in `commands/ingest-prs.md` to include your actual repo names.
