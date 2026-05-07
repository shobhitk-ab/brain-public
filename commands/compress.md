---
description: End-of-session — save session log, propose review entries, propose lessons
model: opus
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# /brain:compress — Save session

Run before `/compact` or closing a session. Saves a searchable log, proposes review entries and lessons.

## Instructions for Claude

### Step 1: Detect brain

Use `$BRAIN_DIR` env var or default `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists. If not, stop with: `No brain at <path>.`

### Step 2: Ask what to preserve

Use AskUserQuestion (multi-select):

**Question:** "What should we preserve from this session?"

**Options:**
1. Decisions made
2. Solutions / fixes that worked
3. Key learnings
4. Files modified / created
5. Pending tasks / next steps
6. Errors & workarounds
7. Meeting notes (if this session was processing a meeting)

### Step 3: Propose review-worthy entries (the self-evolving review tracker)

Scan the session. **Only flag an entry if it has an external artifact** (PR, JIRA ticket, design doc, meeting, decision). This filter is load-bearing — skip anything without an artifact.

For each candidate, classify into one of: `Impact | Leadership | Execution | Craft`.

Propose to user with AskUserQuestion (multi-select):

- Question: `Approve review entries to append to the current review file?`
- Options: one per candidate (with bucket label) plus a final option `None — skip review entries this run`.

Show in the message body above the question:
```
[Execution]  Shipped X — PR#NNNN
[Leadership] Drove alignment with team Y — meeting 2026-05-07
[Impact]     Reduced Z by N% — dashboard link
```

If none qualify, skip this step silently.

### Step 4: Propose lessons (flagged, not auto-saved)

Scan for points where the user corrected you. Do NOT auto-save lessons.

List the candidates with their conversation context, then tell the user:

```
I noticed these corrections in the session:
1. "<paraphrased rule>" — context: <what triggered it>
2. "<paraphrased rule>" — context: <what triggered it>

Want to save any as lessons? Run /brain:preserve.
```

These also show up in the session log under "Potential lessons noticed" so they're not lost if the user skips `/brain:preserve` now.

### Step 5: Propose a topic slug

Suggest a concise topic (3-5 words, lowercase, hyphens): `<slug>-feature-x`, `<slug>-v2-review`, etc.

### Step 6: Generate session log

**Project gate.** If `projects` (detected from session content) is empty, **do not write a session log.** Output:
```
No project context detected — skipping session log.
Tip: run /brain:track first to associate work with a project, then re-run /brain:compress.
```
And continue to Step 7 (review entries can still be appended even without a session log).

If `projects` is non-empty:

- The **primary project** is the first slug in the list — the one with the most context in the session.
- Filename: `$BRAIN/wiki/projects/<primary-slug>/sessions/YYYY-MM-DD-HHMM-<slug>.md`. Create the `sessions/` subdir if missing.
- Detect the Claude Code session ID (best-effort heuristic):
  ```bash
  ENCODED=$(pwd | sed 's|/|-|g')
  SESSION_ID=$(ls -t "$HOME/.claude/projects/${ENCODED}"/*.jsonl 2>/dev/null \
    | head -1 | xargs -I {} basename {} .jsonl)
  ```
  If empty, write `claude_session_id: null`.

Content:

```markdown
---
type: session
date: YYYY-MM-DD
time: HH:MM
topic: <slug>
projects: [<detected project tags — primary first>]
keywords: [<extracted keywords>]
claude_session_id: <SESSION_ID or null>
---

# Session: YYYY-MM-DD HH:MM — <topic>

## Quick reference
**Keywords:** <list>
**Projects:** <list>
**Outcome:** <1 sentence>
**Resume:** `claude --resume <SESSION_ID>`   (omit if claude_session_id is null)

## Decisions made
- <if selected>

## Solutions & fixes
- <if selected>

## Key learnings
- <if selected>

## Files modified
- `path` — what changed

## Pending tasks
- [ ] <item>

## Errors & workarounds
- <if selected>

## Review entries appended
- <Impact|Leadership|Execution|Craft>: <entry> (added to wiki/reviews/<current>.md)

## Potential lessons noticed
- <list — not saved, just flagged>

## Resume context
<2–3 sentences that help a future session pick up exactly here>

---

## Raw session log

<full conversation>
```

### Step 7: Append approved review entries

Target file: `$BRAIN/wiki/reviews/<period>.md` — detect current period by newest file matching `fy*-h*.md` (e.g., `fy26-h1.md`). If no review file exists, **don't create it here** — suggest running `/brain:log-review` once first. Skip Step 7's append in that case and report it as a non-fatal skip.

If the file exists:
- For each approved entry, append to the matching bucket section (`## Impact` / `## Leadership` / `## Execution` / `## Craft`).
- Entry shape mirrors `/brain:log-review`'s shape (outcome — quantification — Before/After for Impact — Evidence: [link]).
- Append the artifact to the matching `## Raw evidence pool` subsection (PR / JIRA / Doc / Meeting / Decision). Skip if already listed (idempotent).
- Use Edit, not Write.

### Step 8: Update project `_state.md` if material progress was made

If the session produced concrete progress on a project (PR merged, decision, meeting with outcome), update `$BRAIN/wiki/projects/<project>/_state.md`:
- Add to "Recent decisions" / "Recent meetings" / "Recent PRs" sections with backlink to `raw/` or `wiki/projects/<project>/sessions/`
- Update "In flight now" and "Next moves" if they changed
- Update "Last updated" timestamp

Do NOT rewrite the whole file — targeted edits only.

### Step 9: Confirm

```
SAVED.

Session log:  wiki/projects/<primary>/sessions/YYYY-MM-DD-HHMM-<slug>.md
              (or "skipped — no project tagged")
Review entries appended: <count> (to wiki/reviews/<period>.md)
                        (or "skipped — review file not initialized; run /brain:log-review first")
Project state updated: <list of project files touched, or "none">
Potential lessons flagged: <count>  — run /brain:preserve to save any

Next: /compact to compress the conversation context.
```

## Notes

- Never run `/compact` yourself. Suggest it; let the user decide.
- The "external artifact required" filter for review entries is non-negotiable. Without it the review file fills with noise and stops being useful.
