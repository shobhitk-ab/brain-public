---
description: Formalize current work as a tracked item — project tag + JIRA ticket (create new, link existing, or skip)
model: opus
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__createJiraIssue, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__editJiraIssue
---

# /brain:track — Formalize current work as a tracked item

Use when you've decided *"this thing I'm doing matters and needs to be on the books."* Resolves three things in one flow: project assignment → JIRA ticket (create / link / skip) → project `_state.md` update.

**Usage:**
- `/brain:track <description>` — explicit: this is what to track
- `/brain:track` — synthesize description from this session's full conversation

## Core rules

- Run at most once per session per work item. The moment of invocation is the user's call — start, middle, or end of session.
- This command **writes to JIRA** (creates issues) when the user opts in. Always confirm before creating.
- If the user picks "no ticket," fall back to capturing as a project-tagged inbox item — never lose the intent.
- If a step fails (e.g., JIRA create errors), capture as inbox item with whatever's known so the user doesn't lose context.
- **Always use `AskUserQuestion` for any choice between fixed options** — including yes/no confirmations, project pickers, ticket-action pickers, and epic-anchor pickers. Do NOT prompt the user with `y/n`, `c/l/n`, or "answer in one reply" text. Free-text prompts are only acceptable for genuinely free-form input: slug, description, ticket key, JIRA project key.
- Ask one thing at a time. Never bundle multiple questions into a single "answer in one reply" prompt.

## Instructions for Claude

### Step 1: Resolve brain path and load config

Brain path: `$BRAIN_DIR` env var, or default `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists (`test -f`). If not, stop with: `No brain at <path> — set BRAIN_DIR or run from a brain directory.`

Load `$BRAIN/brain.config.yaml` (if `/brain:resume` already loaded it earlier in the session, the values are already in working memory). Use the following keys:
- `jira.cloud_id` — for all Atlassian MCP calls
- `jira.default_project_key` — default JIRA project for new tickets/epics
- `jira.account_id` — for tickets-assigned-to-me logic if needed

If `brain.config.yaml` is missing, stop with: `brain.config.yaml not found — run /brain:setup first.`

### Step 2: Build the work description

**If `$ARGUMENTS` is non-empty:** use it as the description verbatim. Skip synthesis. Continue to Step 3.

**If `$ARGUMENTS` is empty:** scan the **entire session conversation** so far. Try to synthesize a 1–2 sentence description of the user's current work, focusing on the most recent substantive thread; ignore meta-chatter about tools, brain commands, or unrelated tangents.

**Two paths from here:**

#### Path A — synthesis succeeded

If you can produce a meaningful 1–2 sentence description from session context, present it via AskUserQuestion (single-select):

- Question: `Track this work item?`
- Options:
  - `Yes — that's right` (description shown above the question, in your message body)
  - `Edit it` (you'll then prompt for the corrected description as plain text)
  - `Cancel — nothing to track`

If user picks "Edit it," wait for their plain-text reply and use that as the description. If "Cancel," exit cleanly with `Nothing tracked.`

#### Path B — no clear work item

If the session has no substantive work thread (just chitchat, exploration, brain-config, or a fresh session), do **not** abort. Prompt the user as plain text:

```
What would you like to track? Type a description (one or two sentences).
```

Wait for the user's next message and use that as the description.

In either path, once the description is set, continue to Step 3.

### Step 3: Classify against project matchers

Load every `$BRAIN/wiki/projects/*/matcher.yml` excluding `_template/` and dotfile directories.

For each matcher, apply its patterns to the description string:
- `jira.summary_patterns` — regex match
- `github.title_patterns` — regex match (text-based, fine to apply to descriptions)
- `jira.labels` / `github.labels` — substring match (low confidence at this stage; descriptions rarely contain raw labels)

A project is a candidate if **any** signal matches.

Use AskUserQuestion to pick the project. If there's exactly one strong candidate, mark it as the recommended default. Otherwise list all valid projects:

```
What project should this be tracked under?
  a) <slug-1>  (recommended — matched: <signals>)
  b) <slug-2>
  c) <slug-3>
  d) Create new project — set up inline
  e) Don't tag — capture as untagged inbox item
```

- If a-c: `project_slug = <chosen>`. Continue to Step 4.
- If d: walk **Step 3a** below, then return to Step 4 with the new slug.
- If e: `project_slug = null`. Continue to Step 6.

### Step 3a: Create new project (inline)

Gather fields **one at a time** with separate prompts. Do not bundle.

1. **Slug** — plain-text prompt:
   ```
   Slug for this project (lowercase-hyphenated, no spaces):
   ```
   Validate against `^[a-z][a-z0-9-]*$`. Reject `_template` and any existing project name. Re-prompt on invalid input.

2. **Description** — plain-text prompt:
   ```
   One-line description (what does this work cover?):
   ```

3. **Epic anchor** — AskUserQuestion (single-select):
   - Question: `JIRA epic anchor for this project?`
   - Options:
     - `Create a new epic in JIRA now`
     - `Link an existing epic — I'll paste the key`
     - `No epic yet — start without one`

#### (Create new epic)

1. Use `jira.cloud_id` from `brain.config.yaml` (no per-run discovery needed).
2. Ask JIRA project key as plain-text prompt — default to `jira.default_project_key` from config:
   ```
   JIRA project key for this epic (default: <jira.default_project_key>):
   ```
3. Confirm via AskUserQuestion (single-select):
   - Question (with the preview shown in your message body above):
     ```
     I'll create:
       Epic in: <PROJ>
       Title:   <project description>
     Proceed?
     ```
   - Options:
     - `Yes, create it`
     - `No, cancel`
4. On confirm: call `mcp__claude_ai_Atlassian__createJiraIssue` with `issuetype: Epic`, `summary: <description>`. Capture the new epic key.

#### (l) Link existing

1. Ask for the epic key.
2. Validate via `mcp__claude_ai_Atlassian__getJiraIssue` — confirm it exists and is type `Epic`.
3. Capture the key.

#### (n) No epic

Set `epic_key = null`.

#### Apply the project scaffolding

After the epic decision (whichever path), do all of the following in one atomic batch:

1. **Copy the template:** `cp -r $BRAIN/wiki/projects/_template $BRAIN/wiki/projects/<slug>/`

2. **Replace the `<PROJECT>` placeholder across every scaffolded file** — appears in `_state.md`, `gotchas.md`, `references.md`, and `overview.md` titles. Use one sweep:
   ```bash
   # macOS sed (Darwin)
   find $BRAIN/wiki/projects/<slug> -type f \( -name '*.md' -o -name '*.yml' \) \
     -exec sed -i '' "s|<PROJECT>|<slug>|g" {} +
   # Linux sed (GNU): drop the empty arg after -i:  -i "s|...|...|g"
   ```
   Verify by grepping the new directory afterwards: `grep -r "<PROJECT>" $BRAIN/wiki/projects/<slug>/` should return nothing.

3. **Initialize `overview.md` body:** the template has a one-line `Static description of the project. Updated rarely.` directly under the title. Replace **that line only** with the user's description from earlier. Leave all the section headings (`## What it does`, `## Architecture`, etc.) and their italic placeholders intact — those are prompts for the user to fill in over time, not stale data.

4. **Initialize `_state.md` metadata** even when no ticket is being created (so the file isn't fully template):
   - Replace `**Last updated:** _YYYY-MM-DD_` → `**Last updated:** <today's date>`
   - Replace `**Phase:** _e.g. active development | stabilization | maintenance | sunsetting_` → `**Phase:** active development`
   - Replace `**Role:** _owner | contributor | oncall-only_` → `**Role:** contributor`

   Leave the italic placeholders inside `## In flight now`, `## Blockers`, etc. — those will be replaced over time by Step 7, `/brain:morning`, and `/brain:compress`.

5. **Create `wiki/projects/<slug>/matcher.yml`:**
   ```yaml
   jira:
     epics:
       - <epic_key>      # omit this entry entirely if epic_key is null
   ```

6. **Append to `wiki/projects/index.md`:**
   ```
   - <slug>: <description>
   ```

7. **No CLAUDE.md edit needed.** The `Active products` list is derived at runtime from `wiki/projects/`; no static list to maintain.

8. Set `project_slug = <slug>` and continue to Step 4.

If anything fails mid-batch, roll back what was created (delete the project dir, revert the index.md edit) and capture the work as inbox so the user doesn't lose it.

### Step 4: Resolve the ticket

Only run this step if `project_slug` is set.

Use AskUserQuestion (single-select):

- Question: `Track in JIRA?`
- Options:
  - `Create a new ticket` (recommended — list this first)
  - `Link an existing ticket — I'll paste the key`
  - `No ticket — capture as project-tagged inbox note`

#### (c) Create new ticket

1. Read `$BRAIN/wiki/projects/<slug>/matcher.yml`. Get `jira.epics` (list).
2. Determine default JIRA project: extract the prefix from the first epic key (e.g., `PROJ` from `PROJ-189`). If `epics` is empty, fall back to `jira.default_project_key` from `brain.config.yaml`; if that's also empty, prompt the user.
3. If multiple epics in the list, ask which one to attach to. Default to the first. Offer "no epic" as a choice.
4. Use `jira.cloud_id` from `brain.config.yaml` (no per-run discovery needed).
5. Confirm via AskUserQuestion (single-select). Show the preview in your message body, then ask:
   - Question: `Create this ticket?`
   - Options:
     - `Yes, create it`
     - `No, cancel`
   - Preview shown above the question:
     ```
     I'll create:
       Project:  <PROJ>
       Type:     Task   (or Bug if description starts with fix/bug/issue)
       Summary:  <description>
       Epic:     <epic key>  (or "no epic")
       Assignee: me
     ```
6. Call `mcp__claude_ai_Atlassian__createJiraIssue` with the resolved fields. Default `issuetype: Task` unless the description clearly indicates a bug (`fix`, `bug`, `broken`, `error`, `issue`) — in which case use `Bug`.
7. Capture the new ticket key.

#### (l) Link existing

1. Ask for the ticket key.
2. Validate via `mcp__claude_ai_Atlassian__getJiraIssue` — confirm it exists and is accessible.
3. If the ticket doesn't have a parent epic and the project's matcher has epics, offer via AskUserQuestion (single-select):
   - Question: `This ticket has no parent epic. Set parent to <epic key>?`
   - Options:
     - `Yes, set parent`
     - `No, leave as-is`
   On Yes: call `mcp__claude_ai_Atlassian__editJiraIssue` to set parent.
4. Capture the ticket key.

#### (n) No ticket

Set `ticket_key = null`. Continue to Step 6.

### Step 4b: Capture the Claude Code session ID

Before persisting, detect the current Claude Code session ID. Best-effort heuristic — find the newest JSONL file in the encoded-cwd dir under `~/.claude/projects/`:

```bash
ENCODED=$(pwd | sed 's|/|-|g')
SESSION_ID=$(ls -t "$HOME/.claude/projects/${ENCODED}"/*.jsonl 2>/dev/null \
  | head -1 | xargs -I {} basename {} .jsonl)
```

If `SESSION_ID` is empty (Claude Code may have stored it elsewhere, or the cwd dir doesn't exist), set `claude_session_id: null`. Don't fail.

### Step 5: Persist (with ticket)

If a ticket key exists (created or linked), write `$BRAIN/raw/jira/YYYY-MM-DD-<KEY>.md`:

```markdown
---
key: <KEY>
title: <summary>
projects: [<slug>]
status: <ticket status>
parent_epic: <epic key or null>
created_via: /brain:track
claude_session_id: <SESSION_ID or null>
ingested: YYYY-MM-DD
url: <ticket URL>
---

## Summary
<description>

## Tracked
Created or linked via /brain:track on YYYY-MM-DD HH:MM.
```

### Step 6: Persist (no ticket)

If no ticket, write `$BRAIN/raw/inbox/YYYY-MM-DD-HHMMSS-<slug>.md`:

```markdown
---
type: tracked
date: YYYY-MM-DD
time: HH:MM:SS
projects: [<slug>] or []
status: unprocessed
created_via: /brain:track
claude_session_id: <SESSION_ID or null>
---

# <title — first sentence ≤60 chars>

<description>
```

Slug rule: 2–4 words from description, lowercase, hyphenated. Fall back to `tracked-note` if too short.

### Step 7: Update project state (only if a ticket exists)

Open `$BRAIN/wiki/projects/<slug>/_state.md`. Append a bullet to the "In flight now" section:
- `<KEY> — <short description ≤80 chars> — started YYYY-MM-DD`

Update the "Last updated" line at the top of the file.

Use a targeted Edit, not a full rewrite.

### Step 8: Confirm

```
TRACKED: <KEY or inbox path>
  Project: <slug or "—">
  Epic:    <epic key or "—">
  File:    raw/jira/<file>  or  raw/inbox/<file>
  State:   wiki/projects/<slug>/_state.md updated   (if ticket)
  JIRA:    <ticket URL>   (if ticket)
```

Nothing else. The user is back to working.

## Notes

- Synthesis (Step 2 no-args path) reads the full session, but the description should focus on the most recent substantive thread. If the session covers two distinct work items, ask the user which to track.
- New-project creation is **inline** (Step 3a). It edits `CLAUDE.md`, creates the project directory, seeds `matcher.yml`, and may create a JIRA epic. The user is shown previews before each side effect.
- If JIRA create fails (auth, network, MCP error), do not abort silently — capture the description as an inbox item with `created_via: /brain:track` and `status: failed_jira_create`, and tell the user what happened so they can retry.
- Don't read `raw/jira/` to "see what's tracked already" — this command only deals with the in-session work item.
