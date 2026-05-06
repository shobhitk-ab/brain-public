---
description: Quick-capture an idea, thought, or snippet into raw/inbox/ without a full conversation
model: opus
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# /brain:capture — Fast dump into inbox

For when you want something saved NOW and don't want a back-and-forth. The content can be anything: an idea, a link, a paragraph from an article, a thought you don't want to lose.

**Usage:**
- `/brain:capture <content>` — save the content with a date-stamped filename
- `/brain:capture` — prompt for content (useful if the thought is long or you haven't typed it yet)

## Instructions for Claude

### Step 1: Get the content

If `$ARGUMENTS` is non-empty, use it as the content.
Otherwise, ask the user: "What are we capturing? (paste or type — hit done when finished)"

### Step 2: Suggest classification (fast, don't overdo it)

Glance at the content and guess:
- **type:** `idea | note | link | snippet | followup | question`
- **projects:** list any of project-a/project-b/project-c/project-d mentioned or implied, or `[]` if none
- **topic slug:** 2–4 words, lowercase, hyphens

Show the guess in one line:
```
I'll save this as: type=idea, projects=[project-a], slug=auto-precheck-retry
  (reply to change, or press enter/say "ok" to accept)
```

Only ask for overrides if the user corrects. Don't gate on explicit approval for each field.

### Step 3: Write the file

Filename: `$BRAIN/raw/inbox/YYYY-MM-DD-HHMM-<slug>.md`

```markdown
---
type: <type>
date: YYYY-MM-DD
time: HH:MM
projects: [<list>]
captured_via: /brain:capture
status: unprocessed
---

# <1-line title derived from content>

<content verbatim — do not paraphrase>

---

_Captured YYYY-MM-DD HH:MM. Will be processed on next /brain:lint or /brain:morning._
```

### Step 4: One-line confirmation

```
CAPTURED: raw/inbox/YYYY-MM-DD-HHMM-<slug>.md
```

Nothing more. The user wanted speed.

### Step 5: (Only if content clearly matches an active project context)

If the content obviously belongs in a project's _state.md "Next moves" or in a specific file, mention it as a single line after the confirmation:

```
CAPTURED: raw/inbox/2026-04-23-1440-auto-precheck-retry.md
(Looks project-a-relevant — /brain:lint will propose moving it to project-a/_state.md Next moves.)
```

Don't move it yourself. `/brain:lint` handles inbox processing so you see the proposals batched.

## Notes

- Never lose content. If in doubt about type/slug, save with placeholder values — speed matters more than perfect classification.
- Inbox is the firehose. `/brain:lint` is where inbox items get promoted to real wiki entries or archived.
- This command should take <5 seconds to invoke and return.
