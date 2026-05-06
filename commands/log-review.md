---
description: Append an entry to the current review file (bucket - impact, leadership, execution, craft)
model: opus
allowed-tools: Read, Edit, AskUserQuestion, Bash
---

# /brain:log-review — Log a review-worthy item

User-triggered. Use when something happens that you want in the review file and `/brain:compress` hasn't captured it.

**Usage:**
- `/brain:log-review impact`
- `/brain:log-review leadership`
- `/brain:log-review execution`
- `/brain:log-review craft`
- `/brain:log-review` (asks which)

## Instructions for Claude

### Step 1: Determine bucket

If `$ARGUMENTS` is one of `impact | leadership | execution | craft`, use it.
Otherwise ask via AskUserQuestion.

### Step 2: Determine current review file

`ls $BRAIN/wiki/reviews/fy*-h*.md | sort -r | head -1` → current file.

If none exists, create one from `_template.md` with today's period (ask user for period start/end if unsure).

### Step 3: Build the entry

Ask the user (or extract from current conversation):

- **The outcome** (what was done / achieved)
- **Quantification** (numbers, %, $, time saved — prompt for this; entries without quantification are weaker)
- **Evidence** (PR link, doc link, JIRA ticket, meeting raw/ link, dashboard)
- **Before/after state** (especially for Impact — "state of the world before" is required per LinkedIn FY26 framework)

For **Impact** entries specifically — enforce the LinkedIn framework:
- Quantify wherever possible
- Tie to business value (DC efficiency, operator toil, hardware visibility, etc.)
- State before → after clearly

If the user gives a weak entry ("worked on X"), push back: "What was the outcome? What changed? Do you have a link?"

### Step 4: Append to the bucket

Edit the current review file. Append a bullet to the matching section:

```markdown
- **<headline outcome>** — <quantification>. Before: <state>. After: <state>. Evidence: [<label>](<url>).
```

For Leadership/Execution/Craft entries the structure is similar but quantification is optional.

### Step 5: Also append to Raw evidence pool

Append the artifact to the appropriate subsection of "Raw evidence pool":
- PR link → PRs
- JIRA key → JIRA tickets
- Doc URL → Docs authored
- Meeting raw/ file → Meetings driven
- Decision file → Decisions

### Step 6: Confirm

```
LOGGED to wiki/reviews/<file>.md
  Section: <bucket>
  Entry: <first 80 chars>

Current review file:
  Impact: <count>
  Leadership: <count>
  Execution: <count>
  Craft: <count>
```

## Notes

- The "external artifact required" rule holds. If the user insists on logging without an artifact, allow it but warn: "no artifact — this will be hard to cite at review time."
- Don't copy/paste the user's raw description verbatim. Tighten it into the outcome-quantification-evidence shape.
