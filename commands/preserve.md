---
description: Save a lesson, decision, preference, gotcha, or person note — user-triggered, earned not drafted
model: opus
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# /brain:preserve — Save durable memory

User-triggered. The user runs this when they've just corrected you, decided something worth keeping, or learned a gotcha. **Lessons are earned from real incidents, not drafted from "best practices."** This command exists so the brain learns from corrections and never repeats the same mistake.

## Instructions for Claude

### Step 1: Resolve brain path

Brain path: `$BRAIN_DIR` or `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists. If not, stop with: `No brain at <path>.`

Discover **active projects:** `ls $BRAIN/wiki/projects/` minus `_template/` and dotfiles. Hold this list — used in Step 3.

Detect the Claude Code session ID (best-effort, same heuristic as `track`/`compress`):
```bash
ENCODED=$(pwd | sed 's|/|-|g')
SESSION_ID=$(ls -t "$HOME/.claude/projects/${ENCODED}"/*.jsonl 2>/dev/null \
  | head -1 | xargs -I {} basename {} .jsonl)
```
Used to stamp the saved entry so future sessions know where the lesson came from. If empty, write `claude_session_id: null`.

### Step 2: Ask what kind

Use AskUserQuestion (single-select):

- Question: `What are we saving?`
- Options:
  - `Mistake / rule — "don't do X because Y"` → `lessons/mistakes.md`
  - `Preference — "I like things done this way"` → `lessons/preferences.md`
  - `Pattern — "this is a recipe that works"` → `lessons/patterns.md`
  - `Gotcha — surprising behavior in a system` → global or project-scoped (asked next)
  - `Decision — "we chose X for this specific situation"` → global or project-scoped (asked next)
  - `Person note — something about a person I work with` → `wiki/people/<Name>.md`
  - `Cancel`

### Step 3: Gather the content

Pull from recent conversation when possible — the user usually invoked `/brain:preserve` immediately after a correction or decision. If the model can synthesize a 1–2 sentence rule/decision/note from the last few turns, present it for confirmation; otherwise ask.

Apply the **decision-vs-lesson test**:
> If the rule only makes sense in its original project, it's a decision. If you'd repeat it on any new project, it's a lesson.

If the user picked `Decision` but the content reads like a general rule that applies anywhere, ask via AskUserQuestion (single-select):
- Question: `This reads like a general rule, not a project-specific decision. Save as:`
- Options: `Decision (project-scoped)`, `Lesson (mistake / preference / pattern)`, `Both — link them`

### Step 4: Ask scope (lessons, decisions, gotchas)

Skip this step for `Preference`, `Pattern`, `Person note` — those are inherently global/personal.

For `Mistake`, `Gotcha`, `Decision`, ask via AskUserQuestion (multi-select):

- Question: `Which projects does this apply to?`
- Options (built dynamically):
  - `Global — applies anywhere, not project-specific`
  - One option per active project from Step 1 (e.g. `<slug-1>`, `<slug-2>`, ...)

If user picks `Global` AND any project, it stays global with a `mentions:` field. If they pick only specific projects, it becomes project-scoped.

### Step 5: Write the entry

Apply per-type rules below. **Append, don't rewrite** — use Edit, not Write.

#### Mistakes (`$BRAIN/lessons/mistakes.md`)

Append a `## ` section with this structure:

```markdown
## <Short rule, imperative form — e.g. "Always await Mongo close()">

**Why:** <The incident — what happened, when (YYYY-MM-DD), where (file/PR/ticket if relevant).>
**How to apply:** <When this rule kicks in. What signal tells future-Claude this rule is relevant.>

_Source: claude_session_id: <SESSION_ID or null>_
_Scope: <global | <slug-1>, <slug-2>>_
```

#### Preferences (`$BRAIN/lessons/preferences.md`)

Append a `## ` section:

```markdown
## <Topic — short, e.g. "Code comments">

**Preference:** <The rule, plainly stated.>
**Why:** <Why this matters to the user.>
**How to apply:** <When and how to apply it.>

_Source: claude_session_id: <SESSION_ID or null>_
```

#### Patterns (`$BRAIN/lessons/patterns.md`)

Append a `## Pattern: <name>` section:

```markdown
## Pattern: <name — short, e.g. "Parallel fanout via ThreadPoolExecutor">

**Where it applies:** <The shape of problem this fits.>
**Why it works:** <What property makes it the right move.>
**Example references:** <Link to 1–2 prior decisions or PRs that exhibit this pattern.>

_Source: claude_session_id: <SESSION_ID or null>_
```

#### Gotchas — global (`$BRAIN/lessons/gotchas.md`)

Append a bullet:

```markdown
- **<System / behavior name>.** <Surprising fact in one line.> Expected: <what would feel intuitive>. Actual: <what really happens>.
  - **Why:** <one-line cause>
  - **Ref:** <PR, ticket, doc URL — or "session <SESSION_ID>">
```

#### Gotchas — project-scoped (`$BRAIN/wiki/projects/<slug>/gotchas.md`)

Same bullet shape, appended to each scoped project's file.

#### Decisions (global: `$BRAIN/wiki/decisions/YYYY-MM-DD-<slug>.md`; project: `$BRAIN/wiki/projects/<slug>/decisions/YYYY-MM-DD-<slug>.md`)

Create a new file (slug = 3–5 words from the decision title, lowercase-hyphenated):

```markdown
---
type: decision
date: YYYY-MM-DD
projects: [<list of slugs, or just "global">]
tags: [<relevant short tags>]
status: decided
claude_session_id: <SESSION_ID or null>
---

# <Title>

## Context
<What prompted the decision. One paragraph.>

## Decision
<What was decided. Plainly stated.>

## Alternatives considered
- <Alternative — why rejected>
- <Alternative — why rejected>

## Consequences
<What we're committing to. Trade-offs.>

## References
- <Link — PR, ticket, prior decision, doc URL>
```

After writing the decision file, append a backlink to each scoped project's `_state.md` "Recent decisions" section:
- `YYYY-MM-DD — <Title> — [decision file](decisions/YYYY-MM-DD-<slug>.md)`

#### Person notes (`$BRAIN/wiki/people/<Name>.md`)

Ask the user for the person's name (free-text prompt). Validate that it's a name, not a generic "the team" or "someone."

`mkdir -p $BRAIN/wiki/people/` if missing.

If `wiki/people/<Name>.md` exists, append to its "Recent interactions" section. Otherwise create with this template:

```markdown
---
type: person
name: <Name>
created: YYYY-MM-DD
---

# <Name>

## Role
<Their role / team if known.>

## How we work together
<Frequency, context — e.g. "Weekly 1:1 since 2026-01", "Code review partner on auth-svc">

## What they care about / strengths
<What you've noticed.>

## Recent interactions
- YYYY-MM-DD — <one line — context, outcome>

## Notes
<Anything else worth remembering. Be respectful — this file is yours.>
```

Always append the new bullet to "Recent interactions" with today's date and the 1-line note that prompted preserve.

### Step 6: Confirm

```
SAVED to <file>.

<1-line summary of what was captured>

Source: session <SESSION_ID or "(no session id detected)">
Scope:  <global | <slug-list>>

Future sessions will load this via /brain:resume.
```

### Step 7: Suggest cross-references

- **Pattern emerging from decisions:** if saving a decision and the project has 3+ decisions tagged similarly (overlap on `tags:` or detected via summary keywords), suggest:
  ```
  This is the 4th decision in <project> using <pattern-keyword>.
  Want to promote to lessons/patterns.md? (y/n)
  ```
  If yes, walk through the pattern flow (Step 5 → Patterns).

- **Lesson overlap:** if saving a mistake and grep finds an existing entry with overlapping keywords (3+ shared significant words):
  ```
  This overlaps with an existing rule:
    "<existing rule heading>"
    File: lessons/mistakes.md

  Refine the existing one, or save this as separate?
  ```
  Use AskUserQuestion to pick.

- **Gotcha in a project's `gotchas.md` that already has 5+ entries:** flag for the user to consider whether some are now obsolete or worth deduplicating.

## Notes

- **Earned, not drafted.** If the user invokes `/brain:preserve` without an obvious recent correction or decision in conversation context, ask explicitly: `What just happened that prompted this? I'd rather capture the real incident than draft a generic rule.`
- **Be careful with "person notes."** Keep them respectful, factual, and useful for collaboration. Don't write performance assessments or anything you wouldn't say to the person.
- **Targeted Edits, not full rewrites.** Lessons files grow over time; preserve their existing entries.
- **Project list is dynamic.** Read it from `wiki/projects/` at runtime. Never hardcode slugs.
- **Cross-session traceability.** The `claude_session_id` field is the breadcrumb back to where the lesson was earned. Useful months later when reviewing patterns.
