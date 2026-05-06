---
description: End-of-session — save session log, propose review entries, propose lessons
model: opus
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# /brain:compress — Save session

Run before `/compact` or closing a session. Saves a searchable log, proposes review entries and lessons.

## Instructions for Claude

### Step 1: Detect brain

Use `$BRAIN_DIR` env var or default `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists.

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

For each candidate, classify into one of: Impact, Leadership, Execution, Craft. Propose to user:

```
Review-worthy entries I noticed (for wiki/reviews/fy26-h1.md):

1. [Execution] Shipped X — PR#NNNN
2. [Leadership] Drove alignment with team Y in meeting on YYYY-MM-DD
3. [Impact] Reduced Z by N% — evidence: dashboard link

Approve which? (all / none / list numbers / edit)
```

If none qualify: skip this step silently.

### Step 4: Propose lessons (user-triggered, not auto-save)

Scan for points where the user corrected you. Do NOT auto-save. Instead:

```
I noticed these corrections in the session:
1. "Don't X, do Y" — context: ...
2. "We always Z in project-a" — context: ...

Want to save any as lessons? Run /brain:preserve to save.
```

The user runs `/brain:preserve` separately (their explicit preference).

### Step 5: Propose a topic slug

Suggest a concise topic (3-5 words, lowercase, hyphens): `project-a-feature-x`, `project-b-v2-review`, etc.

### Step 6: Generate session log

Filename: `YYYY-MM-DD-HHMM-<slug>.md` in `$BRAIN/sessions/`.

Content:

```markdown
---
type: session
date: YYYY-MM-DD
time: HH:MM
topic: <slug>
projects: [<detected project tags>]
keywords: [<extracted keywords>]
---

# Session: YYYY-MM-DD HH:MM — <topic>

## Quick reference
**Keywords:** <list>
**Projects:** <list>
**Outcome:** <1 sentence>

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

For each review entry the user approved, append to the correct section of the current review file (`$BRAIN/wiki/reviews/fy26-h1.md` — detect current period by newest file matching `fy*-h*.md`). Also append the artifact to the **Raw evidence pool** section.

### Step 8: Update project `_state.md` if material progress was made

If the session produced concrete progress on a project (PR merged, decision, meeting with outcome), update `$BRAIN/wiki/projects/<project>/_state.md`:
- Add to "Recent decisions" / "Recent meetings" / "Recent PRs" sections with backlink to raw/ or sessions/
- Update "In flight now" and "Next moves" if they changed
- Update "Last updated" timestamp

Do NOT rewrite the whole file — targeted edits only.

### Step 9: Confirm

```
SAVED.

Session log:  sessions/YYYY-MM-DD-HHMM-<slug>.md
Review entries appended: <count> (to wiki/reviews/fy26-h1.md)
Project state updated: <list of project files touched, or "none">
Potential lessons flagged: <count>  — run /brain:preserve to save any

Next: /compact to compress the conversation context.
```

## Notes

- Never run `/compact` yourself. Suggest it; let the user decide.
- The "external artifact required" filter for review entries is non-negotiable. Without it the review file fills with noise and stops being useful.
