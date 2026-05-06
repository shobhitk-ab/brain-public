---
description: Pull GitHub PRs (mine + review-requested + recently updated) into raw/prs/ via gh CLI
model: opus
allowed-tools: Read, Write, Bash
---

# /brain:ingest-prs — Daily PR pull

Pulls GitHub PR state into `raw/prs/`. Uses the `gh` CLI — no MCP dependency.

## Instructions for Claude

### Step 1: Confirm gh auth

```bash
gh auth status 2>&1 | head -5
```

If not authed, stop and instruct user: `gh auth login`.

### Step 2: Gather PR lists

```bash
# PRs I authored, open
gh search prs --author=@me --state=open --json number,title,repository,state,updatedAt,url,isDraft --limit 50

# PRs where my review is requested
gh search prs --review-requested=@me --state=open --json number,title,repository,state,updatedAt,url --limit 50

# PRs I've commented on recently (involved)
gh search prs --involves=@me --state=open --updated=">=$(date -d '7 days ago' +%Y-%m-%d)" --json number,title,repository,state,updatedAt,url --limit 50

# PRs I authored that merged in last 14 days (for review evidence pool)
gh search prs --author=@me --state=merged --merged=">=$(date -d '14 days ago' +%Y-%m-%d)" --json number,title,repository,state,updatedAt,url,mergedAt --limit 50
```

Deduplicate by `repository + number`.

### Step 3: For each PR, fetch details and write a snapshot

For each unique PR:

```bash
gh pr view <number> --repo <owner>/<repo> --json number,title,body,state,author,reviews,comments,commits,files,url,mergeable,mergeStateStatus,labels,updatedAt,createdAt,closedAt,mergedAt
```

Filename: `raw/prs/YYYY-MM-DD-<repo>-<number>.md` where date is today. Overwrite today's snapshot for same repo+number.

```markdown
---
type: pr
repo: <repo name>
number: <N>
state: <open | merged | closed>
author: <username>
is_mine: <true | false>
review_requested_from_me: <true | false>
project: <project-a | project-b | project-c | other>
ingested: YYYY-MM-DD
url: <PR URL>
created: YYYY-MM-DD
updated: YYYY-MM-DD
merged: YYYY-MM-DD or null
---

# PR #<N> — <title>  (<repo>)

**State:** <state> · **Author:** <user> · **Mergeable:** <status>

## Summary
<body — trimmed to first 500 chars or so>

## Files changed
- `path/to/file.py` (+N -M)
- ...
  _(top 10 files; truncate if more)_

## Review state
- **Approvals:** <count by user>
- **Changes requested:** <count by user>
- **Review comments unresolved:** <count>

## Recent comments (last 7 days)
- YYYY-MM-DD HH:MM — <author> — <comment, truncated>

## Linked tickets
- <extract JIRA keys from title/body>

## Links
- PR: <url>
```

### Step 4: Auto-tag `project:` and `is_mine` / `review_requested_from_me`

`project:` by repo mapping — store the mapping in `wiki/topics/repo-to-project.md` (create it if missing, seed with common ones, ask user to confirm unknowns once and update the file).

`is_mine` = true if author matches user's GitHub handle. `review_requested_from_me` = true if the PR appeared in the `--review-requested=@me` query.

### Step 5: Summary output

```
PR INGEST — YYYY-MM-DD

- <N> PRs I authored (open)
- <N> PRs awaiting my review
- <N> PRs I'm involved in (updated last 7d)
- <N> PRs I merged (last 14d) — for review evidence pool

Wrote / updated <total> files in raw/prs/.

Notable:
- <N> new review requests since last ingest
- <N> PRs I authored now have changes requested
- <N> PRs waiting >48h for my review  ← these should be in today's priorities
```

### Step 6: Do NOT update project `_state.md` or review files here

Leave that to `/brain:morning` and `/brain:compress`. This command only populates `raw/prs/`.

## Notes

- If a PR body or comment contains a JIRA key, extract it and list under "Linked tickets". Cross-references are load-bearing.
- For PRs in repos that aren't clearly one of the four active projects, still snapshot them but set `project: other` and move on.
- Don't fetch full file diffs — too much noise. File list with additions/deletions is enough. Agents can fetch actual diffs on demand.
