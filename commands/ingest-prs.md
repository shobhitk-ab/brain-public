---
description: Pull GitHub PRs into raw/prs/ with matcher-aware project tagging (JIRA-chain primary, GitHub fallback)
model: sonnet
allowed-tools: Read, Write, Bash, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__getJiraIssue
---

# /brain:ingest-prs — Daily PR pull

Pulls GitHub PR state into `raw/prs/` and tags each PR with project slugs by walking the JIRA-key chain (PR → linked ticket → parent epic → matcher). PRs that don't link a ticket fall back to GitHub-only matchers (title / labels / paths / repo). PRs that match nothing get `needs_triage: true`.

**Setup required:**
- `gh auth login` — GitHub CLI
- Atlassian MCP authenticated (optional but strongly recommended — without it, JIRA-chain resolution is skipped and only GitHub fallback runs)

## Instructions for Claude

### Step 1: Resolve brain path, load config, confirm gh auth

Brain path: `$BRAIN_DIR` env var or default `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists. If not, stop with: `No brain at <path> — set BRAIN_DIR or run from a brain directory.`

Load `$BRAIN/brain.config.yaml`. From it, read:
- `user.github_handle` → `GH_USER` (used in Step 5 for `is_mine`)
- `github.default_org` (informational; not strictly required)

If `brain.config.yaml` is missing, stop with: `brain.config.yaml not found — run /brain:setup first.`

Confirm gh auth (no need to query the handle anymore):
```bash
gh auth status 2>&1 | head -3       # if not authed: stop with "gh auth login required"
```

### Step 2: Gather PR lists

Use a portable date helper that works on both macOS (BSD) and Linux (GNU):
```bash
DATE_7D=$(date -v-7d +%Y-%m-%d 2>/dev/null  || date -d '7 days ago'  +%Y-%m-%d)
DATE_14D=$(date -v-14d +%Y-%m-%d 2>/dev/null || date -d '14 days ago' +%Y-%m-%d)
```

Run four queries with a unified field set:
```bash
FIELDS="number,title,body,repository,labels,state,createdAt,updatedAt,url,isDraft,author"

# 1. PRs I authored, open
gh search prs --author=@me --state=open --json $FIELDS --limit 50

# 2. PRs where my review is requested
gh search prs --review-requested=@me --state=open --json $FIELDS --limit 50

# 3. PRs I'm involved in (commented), recently updated
gh search prs --involves=@me --state=open --updated=">=$DATE_7D" --json $FIELDS --limit 50

# 4. PRs I authored that merged in last 14 days (review evidence pool)
gh search prs --author=@me --state=merged --merged=">=$DATE_14D" --json "$FIELDS,mergedAt" --limit 50
```

Deduplicate by `repository.nameWithOwner` + `number`. For each unique PR, remember which queries returned it — used in Step 5 for `is_mine` and `review_requested_from_me`.

### Step 3: Fetch full details for each unique PR

For each PR, fetch the full record (body, files, reviews, comments). Use `repository.nameWithOwner` from Step 2 as the `--repo` argument:

```bash
gh pr view <number> --repo "<nameWithOwner>" \
  --json number,title,body,state,author,reviews,comments,commits,files,url,mergeable,mergeStateStatus,labels,updatedAt,createdAt,closedAt,mergedAt
```

### Step 4: Resolve project tags via matcher

Load every `$BRAIN/wiki/projects/*/matcher.yml`, skipping `_template/` and dotfile dirs.

For each PR, walk the chain in order. Stop at the first pass that produces matches.

#### Step 4a — JIRA-chain (primary)

1. Extract JIRA keys from the PR title + body. Regex: `[A-Z][A-Z0-9]+-\d+`. Deduplicate.
2. For each unique key:
   - Resolve via `mcp__claude_ai_Atlassian__getJiraIssue` (request fields: `summary,parent`).
   - **Cache lookups within this run** — many PRs reference the same tickets; many tickets share parents. Don't re-query.
   - Extract `parent.key` (the epic). If null, this key contributes no chain match.
3. For each matcher's `jira.epics`, if any extracted parent epic appears in the list → add that project's slug to the PR's `projects` set.

If the Atlassian MCP isn't available (unauthenticated, MCP error), skip Step 4a entirely and proceed to 4b.

#### Step 4b — GitHub fallback (secondary, only if 4a yielded nothing)

For each matcher's `github` block, evaluate (any match qualifies):
- `repos`: exact match on `repository.nameWithOwner` (e.g. `myorg/myrepo`)
- `title_patterns`: regex match on PR title (case-insensitive unless explicitly cased in pattern)
- `labels`: any of the matcher's labels appearing in `labels[].name`
- `paths`: any matcher path (glob) matching any of `files[].path` from Step 3

Add every matched project's slug to the `projects` set. Multiple matches are fine.

#### Step 4c — Triage flag

After both passes, decide `needs_triage` and `matched_via`:
- If `projects` set is non-empty and any match came from 4a → `matched_via: jira_chain`
- Else if any match came from 4b → `matched_via: github_fallback`
- Else → `projects: []`, `needs_triage: true`, `matched_via: none`

### Step 5: Write the snapshot

Filename: `$BRAIN/raw/prs/YYYY-MM-DD-<owner>-<repo>-<number>.md`. Replace `/` in `nameWithOwner` with `-` (e.g. `myorg/myrepo` PR #42 → `2026-05-07-myorg-myrepo-42.md`). `mkdir -p $BRAIN/raw/prs/` if missing.

If a file with this name already exists today, **overwrite** it — PR state changes during the day, so today's snapshot is always the freshest. (Don't try to merge.)

```markdown
---
type: pr
repo: <nameWithOwner>
number: <N>
state: <open | merged | closed>
author: <login>
is_mine: <true if author == GH_USER, else false>
review_requested_from_me: <true if PR appeared in --review-requested=@me query, else false>
projects: [<list of matched slugs, or []>]
needs_triage: <true | false>
matched_via: jira_chain | github_fallback | none
linked_jira_keys: [<keys extracted from title/body>]
ingested: YYYY-MM-DD
url: <PR URL>
created: YYYY-MM-DD
updated: YYYY-MM-DD
merged: YYYY-MM-DD or null
---

# PR #<N> — <title>  (<nameWithOwner>)

**State:** <state> · **Author:** <author> · **Mergeable:** <mergeStateStatus>

## Summary
<body, first 500 chars hard cap; append " …(truncated)" if cut>

## Files changed (top 10)
- `path/to/file.py` (+N -M)
- ...
_(top 10 by `additions+deletions` desc; suffix "…N more files" if more)_

## Review state
- **Approvals:** <count, list users>
- **Changes requested:** <count, list users>
- **Review threads unresolved:** <count if available>

## Recent comments (last 7 days, top 10)
- YYYY-MM-DD HH:MM — <author> — <body, first 200 chars hard cap, "…" if truncated>
_(filter by `comments[].createdAt >= now-7d`, sort ascending, cap at 10)_

## Linked JIRA tickets
- <KEY> — <ticket summary, ≤80 chars> — parent epic: <epic key or "—"> — project: <matched slug or "—">
_(one bullet per key in `linked_jira_keys`. If 4a was skipped, omit the "project:" suffix.)_

## Links
- PR: <url>
```

### Step 6: Summary output

```
PR INGEST — YYYY-MM-DD

  <N> PRs I authored (open)
  <N> PRs awaiting my review
  <N> PRs I'm involved in (updated last 7d)
  <N> PRs I merged (last 14d) — for review evidence pool

Wrote / updated <total> files in raw/prs/.

Tagging:
  <N> matched via JIRA chain (PR → ticket → epic → project)
  <N> matched via GitHub fallback (title / labels / paths / repo)
  <N> need triage (no match)         ← will surface in /brain:morning

Notable:
  <N> PRs awaiting my review >48h    ← belong in today's priorities
  <N> PRs I authored now have changes requested
  <N> new review requests since last ingest
```

### Step 7: Do NOT update project `_state.md` or review files here

Leave that to `/brain:morning` and `/brain:compress`. This command only populates `raw/prs/`.

## Notes

- **Idempotent:** re-running on the same day overwrites today's snapshot per PR. State changes during the day; overwrite is correct. Don't skip-if-exists — you'd miss new comments.
- **Atlassian MCP failure mode:** if the JIRA-chain step errors, log the failure for that PR (`matched_via: github_fallback` if Step 4b matched, else `none`) and proceed. One failure shouldn't block the whole run.
- **JIRA-key extraction is greedy:** the regex matches anything that looks like an issue key. Some PR bodies cite tickets in unrelated tools (e.g., Linear keys, Slack channel IDs that look JIRA-shaped). The MCP `getJiraIssue` call will simply error on those — treat the error as "key not found in JIRA" and skip.
- **Don't fetch full file diffs** — the file list with line counts is enough. Agents can fetch diffs on demand.
- **`needs_triage: true` is the trigger** for `/brain:morning`'s "Needs quick call" section to surface this PR for inline assignment.
