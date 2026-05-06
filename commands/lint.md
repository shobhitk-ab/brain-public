---
description: Vault health check — contradictions, stale state, promotable patterns, cross-reference gaps
model: opus
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

# /brain:lint — Weekly vault health check

Finds inconsistencies, stale content, and opportunities to evolve the brain. Non-destructive by default — proposes changes, user approves.

## Instructions for Claude

### Step 1: Scan

Run these checks in parallel where possible:

**1. Stale `_state.md` files**
For each project, compare `Last updated:` in `_state.md` vs. mtime of most recent `raw/` file tagged to that project.
- If raw has activity within 7 days but state is >7 days stale → flag.

**2. Contradictions**
- Each project's `_state.md` lists "Blockers". Grep `raw/jira/` and `raw/prs/` for keywords from those blockers. If a blocker is marked unresolved but raw shows the blocking ticket as Done, or the blocking PR as merged → flag contradiction.
- Each `_state.md` has "In flight now". If raw shows no activity on those items in >14 days → flag as possibly stale.

**3. Promotable patterns**
- Read `wiki/decisions/` and `wiki/projects/*/decisions/`. Cluster decisions by tag and topic.
- If 3+ decisions share a pattern (same tool, same approach, same problem shape) and no entry exists in `lessons/patterns.md` → propose a new pattern.

**4. Orphan files**
- Files in `raw/` with no backlinks from any wiki file, older than 30 days → candidates to prune or to link from somewhere.
- Decisions not referenced from any project `_state.md` → may need backlinks.

**5. Lesson overlap**
- Grep `lessons/mistakes.md` for entries with similar keywords → flag possible duplicates to merge.

**6. Review file health**
- Current `wiki/reviews/fy*-h*.md` — count entries per bucket.
- If Impact has <5 entries but the period is >1 month in, flag: "review file is thin — more aggressive `/brain:log-review` recommended."
- Entries missing quantification → list them.

**7. Ingestion cadence**
- `raw/jira/` last mtime vs now. `raw/prs/` last mtime vs now.
- If either >3 days stale → recommend ingestion.

**8. Project files drift**
- If any project dir is missing one of the template files (`_state.md`, `overview.md`, `references.md`, `gotchas.md`) → flag.

**9. Inbox processing (`raw/inbox/` from `/brain:capture`)**
- For each file in `raw/inbox/` with `status: unprocessed`:
  - Read the content
  - Propose a destination:
    - `idea` / `followup` tied to a project → add as bullet to that project's `_state.md` "Next moves"
    - `question` → add to project `_state.md` "Open questions" section (create section if missing)
    - `snippet` / `link` → add to project `references.md` or `wiki/topics/<topic>.md`
    - `note` with no clear project → add to `wiki/topics/<best-match>.md`, or propose new topic
  - If genuinely junk (stale, already done, no longer relevant) → propose archive to `raw/inbox/_archive/`
- Never move automatically — always propose and wait for approval.

### Step 2: Report

```
══════════════════════════════════════════════
 VAULT LINT — YYYY-MM-DD
══════════════════════════════════════════════

STALE STATE:
- project-a/_state.md: last updated 2026-04-12, but 8 raw items since
  → Suggest: /brain:morning to refresh

CONTRADICTIONS:
- project-b/_state.md says "blocked on PROJ-456", but PROJ-456 is Done (raw/jira/2026-04-22-PROJ-456.md)
  → Update _state.md or investigate

PROMOTABLE PATTERNS:
- 3 decisions use ThreadPoolExecutor for fanout (project-a 2026-03-01, project-d 2026-02-15, project-c 2026-01-20)
  → Promote to lessons/patterns.md as "Parallel fanout via ThreadPoolExecutor"?

ORPHAN FILES:
- raw/docs/<old file>.md — no backlinks, 45 days old — prune or link?

REVIEW FILE HEALTH:
- fy26-h1.md: Impact: 2, Leadership: 4, Execution: 8, Craft: 3
- Impact is thin. 3 PR-merge entries in raw/prs/ from this period are not in the review file.
  → Suggest: /brain:log-review impact for each, or re-run /brain:compress on recent sessions

INGESTION:
- JIRA last ingested 4 days ago
- PRs last ingested 2 days ago
  → Suggest: /brain:ingest-jira

PROJECT FILE DRIFT:
- None

LESSON OVERLAP:
- None

══════════════════════════════════════════════
```

### Step 3: Offer to act

After the report, ask:

```
Want to act on any of these now?
1. Refresh stale _state.md files (runs /brain:morning)
2. Promote the pattern candidates
3. Backlink or prune orphans
4. Ingest stale sources
5. Nothing — just wanted the report

(pick any combination or "skip")
```

Act only on explicit approval. Never prune or delete files without user consent, ever.

### Step 4: On "promote pattern"

For each pattern the user approves:
- Write a new entry to `lessons/patterns.md` with the format in that file's header
- Link back to the originating decisions

### Step 5: On "backlink orphans"

Propose where each orphan should be linked from. Apply Edits after user approves each one.

## Notes

- Lint is read-heavy, write-light. Default stance: report, don't mutate.
- Pattern detection is the highest-value output. This is how the brain evolves from "log of decisions" into "library of reusable moves."
- Run frequency: weekly is right. More often = noise. Less often = drift.
