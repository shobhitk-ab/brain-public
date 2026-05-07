---
description: Append a review-worthy entry to the current review file — framework-aware (linkedin / generic / custom)
model: opus
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# /brain:log-review — Log a review-worthy item

User-triggered. Run when something happens that you want preserved for review-time and `/brain:compress` didn't catch it. Forces an outcome-quantification-evidence shape so review time isn't a blank-page slog.

**Usage (linkedin framework):**
- `/brain:log-review impact`
- `/brain:log-review leadership`
- `/brain:log-review execution`
- `/brain:log-review craft`
- `/brain:log-review` (asks which bucket)

**Usage (generic / custom frameworks):**
- `/brain:log-review` — no bucket; one flat list of entries

## Instructions for Claude

### Step 1: Resolve brain, load config

Brain path: `$BRAIN_DIR` or `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists.

Load `$BRAIN/brain.config.yaml`. Required keys:
- `review.framework` — one of `linkedin | generic | custom`
- `review.current_period` — e.g. `fy26-h1`

If config is missing or these keys are absent, stop with: `Review framework not configured — run /brain:setup.`

### Step 2: Determine the review file

Path: `$BRAIN/wiki/reviews/<review.current_period>.md` (e.g. `wiki/reviews/fy26-h1.md`).

If the file doesn't exist:
- `mkdir -p $BRAIN/wiki/reviews/`
- Create the file with the template that matches `review.framework` (see Step 3 templates below).

If `wiki/reviews/_archive/` or older period files exist alongside, that's fine — leave them; just operate on the current period.

### Step 3: Initialize review file template (if newly created)

#### `framework: linkedin`

```markdown
# Review — <review.current_period>

_Maintained by /brain:log-review and /brain:compress. Hand-edit only to refine entries._

## Impact
<!-- Outcomes that changed business state. Always quantify. State before → after. -->

## Leadership
<!-- Where you drove direction, mentored, unblocked, influenced. -->

## Execution
<!-- Things shipped, milestones hit, fires put out. -->

## Craft
<!-- Codebase / process improvements, lessons earned, depth. -->

## Raw evidence pool
### PRs
### JIRA tickets
### Docs authored
### Meetings driven
### Decisions
```

#### `framework: generic`

```markdown
# Review — <review.current_period>

_Maintained by /brain:log-review and /brain:compress. Hand-edit only to refine entries._

## Entries
<!-- One flat list. Each entry: outcome — quantification — evidence. Categorize later if needed. -->

## Raw evidence pool
### PRs
### JIRA tickets
### Docs authored
### Meetings driven
### Decisions
```

#### `framework: custom`

For now, use the `generic` template. The user can re-shape the file directly to match their org's review structure; future runs of `/brain:log-review` will respect the existing top-level `## ` headings if they look canonical (anything other than `Entries` / `Raw evidence pool`).

### Step 4: Determine the bucket (linkedin only; skip for generic/custom)

If `review.framework == "linkedin"`:

- If `$ARGUMENTS` is one of `impact | leadership | execution | craft` → use it (case-insensitive).
- Otherwise ask via AskUserQuestion (single-select):
  - Question: `Which bucket?`
  - Options: `Impact`, `Leadership`, `Execution`, `Craft`

If `review.framework == "generic"` or `"custom"`:
- No bucket. Skip this step. The entry goes under `## Entries`.

### Step 5: Build the entry

Ask the user (or extract from session context) for these four pieces:

1. **Outcome** — what changed in the world. One short sentence. Required.
2. **Quantification** — numbers / %, $ / time saved / users affected. Optional for non-Impact buckets, **required for Impact** under `linkedin`.
3. **Before / after state** — what the world looked like before vs. after this work. Required for Impact under `linkedin`; optional otherwise but encouraged.
4. **Evidence** — PR URL, JIRA key, doc link, meeting raw/ file, decision file. **Required for all entries** — without an artifact, the entry is hard to defend at review time.

If the user offers something weak ("worked on X"), push back politely:
> *"What changed because of this? Do you have a link I can cite?"*

If they insist on logging without evidence, allow it but warn:
> *"No artifact — this will be hard to cite at review time. I'll mark it as `evidence: missing`."*

#### Bucket-specific shaping (linkedin)

- **Impact:** quantification + before/after are required. Tie to business value if possible.
- **Leadership:** evidence often = meeting raw/ file, decision doc, or Slack thread URL.
- **Execution:** evidence usually = PR(s) merged or JIRA ticket Done.
- **Craft:** evidence often = a refactor PR, a runbook authored, a lesson promoted.

### Step 6: Append the entry

Edit the review file. Format depends on framework + bucket:

**linkedin / Impact:**
```markdown
- **<outcome>** — <quantification>. Before: <state>. After: <state>. Evidence: [<label>](<url>). _logged: YYYY-MM-DD_
```

**linkedin / Leadership, Execution, Craft:**
```markdown
- **<outcome>** — <quantification or "—">. Evidence: [<label>](<url>). _logged: YYYY-MM-DD_
```

**generic / custom — under `## Entries`:**
```markdown
- YYYY-MM-DD — **<outcome>** — <quantification or "—"> — Evidence: [<label>](<url>).
```

Use Edit (targeted append within the section), not Write.

### Step 7: Append to Raw evidence pool

Add the evidence artifact to the matching subsection of `## Raw evidence pool`:

| Evidence type | Subsection |
|---|---|
| PR URL (`github.com/.../pull/N`) | `### PRs` |
| JIRA key (`<KEY>`) | `### JIRA tickets` |
| Doc URL (Confluence, Google Doc, internal wiki) | `### Docs authored` |
| Meeting raw/ file path | `### Meetings driven` |
| Decision file path | `### Decisions` |

Bullet shape: `- YYYY-MM-DD — <label> — <url-or-path>`. Skip if the same artifact is already listed (idempotent).

### Step 8: Confirm

```
LOGGED to wiki/reviews/<period>.md
  Bucket: <Impact | Leadership | Execution | Craft | Entries>
  Entry:  <first 80 chars>

Current review file totals:
  <bucket>: N
  <bucket>: N
  ...

Raw evidence pool: <total artifacts>
```

For `generic` / `custom`, just show the flat `Entries: N` total.

## Notes

- **External artifact required.** The whole point of this command is that review time becomes citation, not reconstruction. If you log entries without evidence, the file decays into self-reporting.
- **Tighten, don't paste.** Don't copy the user's raw description verbatim. Compress it into the outcome-quantification-evidence shape. The user can re-edit the file later if they want different phrasing.
- **Framework branching.** Read `review.framework` from config. Don't assume a specific framework — `generic` is the safe default for any user who hasn't picked one.
- **Idempotent on Raw evidence pool.** Don't append the same artifact twice if it's already there.
- **No session ID.** Review entries are deterministic outcomes — they don't need session traceability. The evidence URL is the canonical reference.
