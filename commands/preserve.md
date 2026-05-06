---
description: Save a lesson, decision, preference, or gotcha right now — user-triggered on correction
model: opus
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
---

# /brain:preserve — Save durable memory

User-triggered. The user says this when they've just corrected you or made a decision they want to keep.

## Instructions for Claude

### Step 1: Ask what kind

Use AskUserQuestion (single-select):

**Question:** "What are we saving?"

**Options:**
1. **Mistake/rule** — "don't do X because Y" — goes to `lessons/mistakes.md`
2. **Preference** — "I like things done this way" — goes to `lessons/preferences.md`
3. **Pattern** — "this is a recipe that works" — goes to `lessons/patterns.md`
4. **Gotcha (global)** — "cross-project landmine" — goes to `lessons/gotchas.md`
5. **Gotcha (project-scoped)** — "landmine in project X" — goes to `wiki/projects/<name>/gotchas.md`
6. **Decision** — "we chose X for this specific situation" — goes to `wiki/decisions/` or `wiki/projects/<name>/decisions/`
7. **Person note** — "something about a person" — goes to `wiki/people/<Name>.md`

### Step 2: Gather the content

Based on type, extract from recent conversation OR ask the user for missing bits.

Apply the **decision vs. lesson test** from CLAUDE.md:
> If the statement only makes sense in its original project, it's a decision. If you'd repeat it in a new project, it's a lesson.

If user picked "decision" but the content reads like a general rule, flag it: "This reads like a general rule — should we also save a lesson that points back to this decision?"

### Step 3: Ask scope (for lessons/decisions)

"Which projects does this apply to? (global / project-a / project-b / project-c / project-d / multiple)"

### Step 4: Write the entry

**For mistakes (`lessons/mistakes.md`):** append a new `## Rule: <title>` section following the format in the file header.

**For preferences (`lessons/preferences.md`):** append a new `## <Topic>` section.

**For patterns (`lessons/patterns.md`):** append a new `## Pattern: <name>` section.

**For gotchas (global):** append a bullet to `lessons/gotchas.md`.

**For gotchas (project):** append a bullet to `wiki/projects/<name>/gotchas.md`.

**For decisions:** create a new file `YYYY-MM-DD-<slug>.md` in the right directory with frontmatter:
```yaml
---
type: decision
date: YYYY-MM-DD
project: <name or list>
tags: [<relevant>]
status: decided
---

# <Title>

## Context
<what prompted the decision>

## Decision
<what was decided>

## Alternatives considered
- <alt 1 — why rejected>

## Consequences
<expected impact, what we're committing to>

## References
- <links>
```

Then update the project's `_state.md` "Recent decisions" section with a backlink.

**For person notes:** check if `wiki/people/<Name>.md` exists. If yes, append to "Recent interactions" and "Notes". If no, create from `wiki/people/_template.md`.

### Step 5: Confirm

```
SAVED to <file>.

<1-line summary of what was captured>

{If this was a correction during an active session:}
Future sessions will load this via /brain:resume.
```

### Step 6: Suggest cross-references

- If saving a decision that exhibits a recurring pattern across 3+ existing decisions: suggest promoting to a pattern.
- If saving a mistake that overlaps an existing one: show the existing entry, ask if this refines it or is separate.
