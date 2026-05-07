---
description: Synthesize a polished review draft from the current review file — framework-aware (linkedin / generic / custom)
model: opus
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
---

# /brain:draft-review — Compose the polished review

Produces a first-draft polished review from the working review file (`wiki/reviews/<current_period>.md`), in the format that matches your `review.framework` config. Output is a separate `*-DRAFT.md` file — the working file is never overwritten.

## Instructions for Claude

### Step 1: Load config and validate inputs

Brain path: `$BRAIN_DIR` or `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists.

Load `$BRAIN/brain.config.yaml`. Required keys:
- `review.framework` — `linkedin | generic | custom`
- `review.current_period` — e.g. `fy26-h1`

Working file: `$BRAIN/wiki/reviews/<review.current_period>.md`. If it doesn't exist, stop with: `No review file at <path>. Run /brain:log-review to create it and add at least a few entries first.`

### Step 2: Read inputs

Pull together:
- The working review file (every section, every bullet).
- All decisions in this period: `wiki/decisions/*.md` and `wiki/projects/*/decisions/*.md` filtered by file mtime within the period.
- All session logs in this period: `wiki/projects/*/sessions/*.md` filtered by date.
- Each project's `_state.md` "Recent decisions" / "Recent PRs / tickets" / "Recent meetings" sections.
- `lessons/preferences.md` for tone and voice preferences (e.g. "I like terse, outcome-first writing").

### Step 3: Audit the working file

Per framework:

- **`linkedin`:** count entries per bucket (Impact / Leadership / Execution / Craft). For Impact, flag entries missing **quantification** or **before/after state**. For all buckets, flag entries missing **evidence link**.
- **`generic` / `custom`:** count flat entries under `## Entries`. Flag entries missing quantification or evidence.

Show the audit:

```
REVIEW AUDIT — <period>

<framework-specific counts:>
  linkedin →   Impact: N (M weak), Leadership: N (M weak), Execution: N, Craft: N
  generic  →   Entries: N (M weak)

Entries needing strengthening:
1. "<entry headline>" — <why weak: missing quantification | missing evidence | missing before/after>
2. ...

Total: <strong> strong, <weak> weak.
```

Ask via AskUserQuestion (single-select):
- Question: `Strengthen weak entries before drafting?`
- Options:
  - `Walk me through them — I'll fix or remove each`
  - `Draft anyway — I'll edit the draft directly`
  - `Cancel`

If `walk through`: for each weak entry, show context and ask the user via plain-text prompt for the missing piece (quantification / evidence / before/after). Apply edits to the working file via Edit. Continue until all flagged or the user says "skip rest."

### Step 4: Gather development areas (optional)

Development areas (growth edges) are not usually accumulated in the working file. Ask the user once:

```
What are 3–5 development areas you want to call out? These are growth edges — areas where you want to be stronger over the next period.

(e.g. "Scale design ownership beyond my immediate scope", "Increase visible technical writing")

Type them as a comma-separated list, or "skip" to leave the section out.
```

Capture them. If user types "skip," omit the Development Areas section from the draft.

### Step 5: Write the draft

Output: `$BRAIN/wiki/reviews/<review.current_period>-DRAFT.md`. **Never overwrite the working file.**

#### Template — `linkedin`

```markdown
# <review.current_period> Review — DRAFT

_Generated YYYY-MM-DD by /brain:draft-review from wiki/reviews/<period>.md._

## Summary
<2–3 paragraph narrative. Lead with scope ("Focus this half has been on X across Y"). Call out the biggest wins. Name the technical breadth (languages, systems). Position based on what evidence supports — connector / owner / shipper / driver. Confident, specific, outcome-first. Every claim must trace to an entry. No fabrication.>

## Leadership
<Bullets, grouped by theme. Each bullet: **Bold headline**, then specifics with numbers, then evidence link. Mirror the entry style of the working file.>

## Execution
<Bullets. Lead with the shipped thing, then technical substance, then the PR/ticket link.>

## Craft
<Bullets. Lead with the design/architectural move, then the defensive/quality choice, then the tradeoff.>

## Impact
<Bullets. THIS IS THE MOST IMPORTANT SECTION. Each bullet:
- Quantified outcome
- Before → after state
- Tie to business value (whatever your org measures — customer-facing metric, cost, capacity, reliability, operator toil)
- Evidence link

Lead with the strongest impact first. Order by magnitude.>

## Development Areas
<3–5 bullets from Step 4. Each: current state → next ambition, with a concrete next step.>

## Additional Evidence

### JIRA tickets
<Grouped by theme, with `[N]` link markers.>

### PRs
<Chronological or grouped by theme.>

### Decisions
<Links to decision files.>

### Dashboards / Docs
<Links.>
```

#### Template — `generic` / `custom`

```markdown
# <review.current_period> Review — DRAFT

_Generated YYYY-MM-DD by /brain:draft-review from wiki/reviews/<period>.md._

## Summary
<2–3 paragraph narrative. Lead with scope. Call out biggest outcomes. Confident, specific, outcome-first. Every claim must trace to an entry. No fabrication.>

## Outcomes
<Flat list. Order by magnitude (strongest first). Each entry:
- **Bold headline**, then specifics, quantification where present, evidence link.
- Mirror the entry style of the working file.>

## Development Areas
<If Step 4 captured any. Otherwise omit this section.>

## Additional Evidence

### JIRA tickets
### PRs
### Decisions
### Dashboards / Docs
```

For `custom`, if the working file has been hand-edited to use custom-specific top-level sections, **respect them** — use those as the draft's outline rather than the generic template. Heuristic: if the working file has any `## ` heading other than `Entries` / `Raw evidence pool`, treat them as the canonical sections.

### Step 6: Style rules (apply across all frameworks)

- **Active voice, past tense.** "Delivered", "Shipped", "Led", "Architected". Not "I was responsible for…".
- **Every claim traces to an entry in the working file.** If something doesn't have a corresponding entry with evidence, don't include it.
- **Numbers are sacred.** Use exact figures from the working file. Don't round or inflate. If a number isn't in the working file, don't make one up.
- **Bold lead-ins** for each bullet so a reader can skim.
- **Summary stays ≤3 paragraphs.** Tighter is stronger.
- **Match user's voice** if `lessons/preferences.md` has hints about tone (e.g. "I prefer terse" → shorter sentences).

### Step 7: Output

```
DRAFT WRITTEN: wiki/reviews/<period>-DRAFT.md

Structure:
  Summary:           <N> paragraphs
  <bucket / Outcomes>: <N> bullets
  ...
  Development Areas: <N> bullets   (or "omitted")
  Evidence:          <total artifacts across subsections>

Strong points:
  - <bullet from the strongest section>

Weaker spots (consider strengthening before submitting):
  - <bullet missing quantification>
  - <bullet missing before/after>

Next: review the draft, iterate, paste into your review system.
Re-run /brain:draft-review anytime to regenerate; the working file is preserved.
```

## Notes

- **Never overwrite the working file.** The working file accumulates throughout the period; the draft is a snapshot built from it.
- **Re-running is cheap.** Iterate the working file via `/brain:log-review`, then re-run `/brain:draft-review` to regenerate the draft.
- **No fabrication, ever.** If the audit shows weak entries, surface them and let the user fix them in the working file. Don't paper over weakness in the draft.
- **Framework-aware bucketing.** `linkedin` produces full bucketed structure; `generic`/`custom` produce a flat outcomes list. Don't force LinkedIn-isms onto a generic review.
- **Period archival is out of scope.** Closing out a period (archiving the working file, seeding the next period) is for a future `/brain:close-review` flow, not this one.
