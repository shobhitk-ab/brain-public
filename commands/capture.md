---
description: Quick-capture an idea, thought, or snippet into raw/inbox/ — fast, no gate
model: haiku
allowed-tools: Write, Bash
---

# /brain:capture — Fast dump into inbox

Sticky-note dropzone. Save the content **first**, then show what you inferred. The user wanted speed.

**Usage:**
- `/brain:capture <content>` — save the content with a date-stamped filename
- `/brain:capture` — wait for the user's next message and save its full body

## Core invariant

**Never lose content.** If anything below is ambiguous, default to writing the file. The user can correct misclassification after; they cannot recover lost content.

## Instructions for Claude

### Step 1: Resolve brain path and get content

Brain path: `$BRAIN_DIR` env var, or default `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists (`test -f`). If not, stop with: `No brain at <path> — set BRAIN_DIR or run from a brain directory.`

Content:
- If `$ARGUMENTS` is non-empty, that is the content — verbatim, including newlines and any special chars.
- Otherwise, emit a single line — `What are we capturing? Paste or type your full thought; I'll save your next message verbatim.` — and stop. The user's next message is the content; resume from Step 2 on that turn.

### Step 2: Classify silently (no gate)

Infer four fields without asking:

- **type** — one of `note | link | followup`. Apply rules in this order, first match wins:
  1. `link` — if the content contains a URL (http://, https://, or `www.`). URL presence beats any action-verb cues; "read this later" attached to a link is still a `link`.
  2. `followup` — if no URL, but the content reads like an action item directed at a person or future-self ("ask X", "remember to Y", "ping Z about W", "follow up on …").
  3. `note` — everything else. Default to `note` when in doubt.
- **projects** — list of project slugs from `ls $BRAIN/wiki/projects/` excluding `_template/` and any dotfiles. Tag a project only if its slug, an obvious alias, or domain-specific term from that project's `overview.md` appears in the content. **Do not auto-tag a project just because it is the only one that exists** — `[]` is a perfectly valid answer and is the correct default. Multiple matches are fine.
- **slug** — 2–4 words drawn from the content, lowercase, hyphenated, articles/prepositions dropped. If the content is too short or generic for a meaningful slug, use `quick-note`.
- **title** — the first sentence of the content, truncated to 60 chars. If there is no sentence break in the first 60 chars, take the first 60 chars verbatim.

### Step 3: Write the file

Filename: `$BRAIN/raw/inbox/YYYY-MM-DD-HHMMSS-<slug>.md`
- Date and time: **system local time, 24-hour**.
- `mkdir -p $BRAIN/raw/inbox/` if missing.

File body:

```markdown
---
type: <type>
date: YYYY-MM-DD
time: HH:MM:SS
projects: [<flow-list>]
status: unprocessed
---

# <title>

<content verbatim — do not paraphrase or reformat>
```

YAML `projects:` must use the **flow-sequence** form, no quotes, no block-list:
- `projects: []` (none)
- `projects: [main]` (one)
- `projects: [main, security]` (multiple, comma-space separated)

### Step 4: One-line confirmation with inferred classification

```
CAPTURED: raw/inbox/YYYY-MM-DD-HHMMSS-<slug>.md
  Inferred: type=<type> · projects=[<list>] · slug=<slug>
  (say so if any of that is wrong and I'll rename/retag.)
```

Nothing else. The file is already on disk before this message renders, so the user is free to walk away.

## Notes

- The inbox is the firehose. `/brain:lint` promotes inbox items to real wiki entries or archives them. This command does not promote — even when classification "obviously" matches a project.
- Do not read prior conversation context to enrich the capture. Treat the input as the entire payload.
- Target invocation time: <5 seconds end-to-end. If you find yourself asking a clarifying question, you've already failed the speed bar — write the file and confirm instead.
