---
description: Synthesize a polished review draft from the current review file, in LEC + Impact format
model: opus
allowed-tools: Read, Write, Bash, Glob, Grep
---

# /brain:draft-review — Compose the polished review

Produces a first-draft polished review from `wiki/reviews/<current>.md`, formatted like Amil's prior review (Summary + Leadership + Execution + Craft + Impact + Development Areas + Additional Evidence).

## Instructions for Claude

### Step 1: Load inputs

- **Current review file:** `ls $BRAIN/wiki/reviews/fy*-h*.md | sort -r | head -1`
- **All decisions from this period:** grep dates in decisions/ and projects/*/decisions/
- **All sessions from this period:** `sessions/` files in date range
- **Project `_state.md` "Recent decisions" / "Recent PRs" sections** for evidence cross-check
- **`lessons/preferences.md`** — tone preferences for writing

### Step 2: Validate evidence

For each entry in Impact/Leadership/Execution/Craft:
- Confirm the evidence link is present
- If quantification is vague ("significantly improved"), flag it and suggest the user clarify before the draft is final

Produce an initial audit:

```
REVIEW AUDIT — <file>
 Impact: <N> entries, <M> missing quantification
 Leadership: <N> entries, <M> missing evidence
 Execution: <N> entries
 Craft: <N> entries

Entries needing strengthening:
1. "<entry>" — <why weak>
2. ...

Want to strengthen these before drafting, or draft anyway?
```

Wait for user response. If "strengthen", list the weak ones one by one and help clarify. If "draft anyway", proceed.

### Step 3: Write the draft

Output location: `$BRAIN/wiki/reviews/<period>-DRAFT.md` (alongside the working file, clearly marked DRAFT).

Structure matches Amil's prior review format:

```markdown
# FY26 H1 Review — DRAFT

Generated YYYY-MM-DD by /brain:draft-review from wiki/reviews/fy26-h1.md.

## Summary

<2–3 paragraph narrative — synthesize the half. Lead with scope ("focus has been on X across Y"), call out the biggest wins, name the technical breadth (languages, systems), position the person as a connector/owner/shipper per what the evidence shows. Match the tone and register of Amil's prior Summary section. Do NOT invent anything — every claim maps to an entry.>

## Leadership

<Bullet entries grouped by theme, drawn from the Leadership section of the working file. Each bullet: bold lead-in, then specifics, then evidence links. Mirror prior review's bullet style: "Bold Headline: Specifics with numbers where possible, then tight explanatory sentence.">

## Execution

<Bullets, same shape. Lead with the shipped thing, then the interesting technical substance, then the PR/evidence link.>

## Craft

<Bullets, same shape. Lead with the design/architectural move, then the defensive/quality choice, then the tradeoff.>

## Impact

<Bullets, same shape. THIS IS THE MOST IMPORTANT SECTION UNDER FY26 FRAMEWORK. Each bullet:
- Quantified outcome
- Before → after state
- Tie to business value (operator toil, DC efficiency, customer-facing metric, cost, capacity)
- Evidence link
Lead with the strongest impact first. Order by magnitude.>

## Development Areas

<Pull from the working file's "Development areas identified" section. Synthesize into 4–6 clean bullets in the voice of the prior review ("Scale from X to Y"). Each: current state → next ambition, with a concrete next step.>

## Additional Evidence

### Jira tickets
<Grouped by theme, with bracketed link markers [1] [2] matching prior review style>

### PRs
<Chronological or grouped by theme>

### Dashboards / Docs
<Links>
```

### Step 4: Style rules

- Match the tone of Amil's prior review: confident, specific, outcome-first, tight.
- Use active voice and past tense throughout ("Delivered", "Shipped", "Led", "Architected").
- Every claim traces to an entry in the working file. If something doesn't have evidence, don't write it.
- Numbers are sacred. Use exact percentages/counts from the working file. Do not round or embellish.
- Mimic the prior review's use of **bold headlines** for each bullet.
- Keep the Summary to 3 paragraphs max.

### Step 5: Output

```
DRAFT WRITTEN: wiki/reviews/<period>-DRAFT.md

Structure:
- Summary: <N> paragraphs
- Leadership: <N> bullets
- Execution: <N> bullets
- Craft: <N> bullets
- Impact: <N> bullets
- Development Areas: <N> bullets
- Evidence sections: <counts>

Strong points:
- <where evidence is tightest>

Weaker spots (consider strengthening before submitting):
- <where quantification or before/after is thin>

Next: review the draft, iterate, then paste into the review system.
```

## Notes

- Do NOT overwrite the working file (`fy26-h1.md`). The working file keeps accumulating; the draft is a snapshot.
- If the user asks for a revision, update `<period>-DRAFT.md` in place.
- At period end, after the final review is submitted, a future `/brain:close-review` flow (not yet built) will archive the working file and seed the next period.
