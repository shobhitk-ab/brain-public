---
description: Pull JIRA tickets into raw/jira/ with matcher-aware project tagging via parent epic
model: sonnet
allowed-tools: Read, Write, Bash, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__getJiraIssue
---

# /brain:ingest-jira — Daily JIRA pull

Pulls your JIRA reality into `raw/jira/` as dated markdown snapshots, tagging each ticket with project slugs by matching its **parent epic** against `wiki/projects/*/matcher.yml`. Tickets without a parent epic — or whose epic doesn't match any project — get `needs_triage: true`.

**Setup required:**
- `brain.config.yaml` populated (run `/brain:setup` if missing). Provides `jira.cloud_id` and `jira.account_id`.
- claude.ai Atlassian MCP authenticated. If not, the JQL calls will fail — fall back to: export a JIRA filter to CSV/JSON, paste into `raw/inbox/`, then `/brain:capture` to route it.

## Instructions for Claude

### Step 1: Resolve brain path, load config

Brain path: `$BRAIN_DIR` env var or default `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists. If not, stop with: `No brain at <path> — set BRAIN_DIR or run from a brain directory.`

Load `$BRAIN/brain.config.yaml`. Required keys:
- `jira.cloud_id` — passed to every Atlassian MCP call as `cloudId`
- `jira.account_id` — used in JQLs (the MCP often requires `accountId` rather than `currentUser()`)

If `brain.config.yaml` is missing or doesn't contain these keys, stop with: `brain.config.yaml not found or incomplete — run /brain:setup.`

### Step 2: Run targeted JQLs

Execute these four JQLs via `mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql` (passing `cloudId` from config). Substitute `<accountId>` with `jira.account_id`.

1. **Assigned to me, active:**
   `assignee = <accountId> AND statusCategory != Done ORDER BY updated DESC`
2. **Reported by me, active:**
   `reporter = <accountId> AND statusCategory != Done ORDER BY updated DESC`
3. **Watching:**
   `watcher = <accountId> AND statusCategory != Done AND updated >= -7d ORDER BY updated DESC`
4. **Recently updated where I commented or am mentioned:**
   `(comment ~ <accountId> OR text ~ <accountId>) AND updated >= -3d ORDER BY updated DESC`

Deduplicate by ticket key across results.

For each ticket from search, also fetch the full record via `mcp__claude_ai_Atlassian__getJiraIssue` to get fields the search summary may not include (description, comments, parent epic). **Cache lookups within this run** — many JQLs return overlapping tickets; don't re-query.

Request fields per `getJiraIssue` call: `summary, description, status, priority, assignee, reporter, parent, labels, components, fixVersions, updated, comment`.

### Step 3: Resolve project tags via matcher

Load every `$BRAIN/wiki/projects/*/matcher.yml`, skipping `_template/` and dotfile dirs.

For each ticket:

#### Step 3a — Parent epic match (primary)

1. Read the ticket's `parent.key` (the epic key) and `parent.fields.issuetype.name` from the response.
2. Only proceed if the parent type is `Epic` (sub-tasks may have a non-Epic parent — that's not a project signal).
3. For each matcher's `jira.epics`, if the parent epic appears in the list → add that project's slug.

#### Step 3b — Label / summary fallback (when parent epic doesn't match)

If 3a yielded nothing, evaluate each matcher's `jira` block:
- `summary_patterns`: regex match on ticket summary (case-insensitive unless explicitly cased)
- `labels`: any matcher label appearing in `ticket.labels`

Add every matched project's slug. Multiple matches are fine.

#### Step 3c — Triage flag

After both passes:
- If `projects` is non-empty and any match came from 3a → `matched_via: jira_epic`
- Else if any match came from 3b → `matched_via: jira_fallback`
- Else → `projects: []`, `needs_triage: true`, `matched_via: none`

### Step 4: Write one file per ticket

Path: `$BRAIN/raw/jira/YYYY-MM-DD-<KEY>.md`. `mkdir -p` if missing.

If a file with this name exists today, **overwrite it** — ticket state may change during the day.

```markdown
---
key: <KEY>
title: <summary>
status: <status>
priority: <priority>
assignee: <displayName or null>
reporter: <displayName or null>
projects: [<list of matched slugs, or []>]
needs_triage: <true | false>
matched_via: jira_epic | jira_fallback | none
parent_epic: <parent.key or null>
labels: [<ticket labels>]
ingested: YYYY-MM-DD
updated: <ISO date>
url: https://<site_url>/browse/<KEY>
---

## Summary
<1–2 sentence summary derived from `summary` + first paragraph of `description`>

## Description (condensed)
<key points only, ≤500 chars hard cap, append " …(truncated)" if cut. Skip boilerplate sections like "Acceptance criteria placeholder", empty bullet templates, etc.>

## Recent activity
<last 2–3 comments or status changes if available, each ≤200 chars>
```

### Step 5: Report

```
JIRA INGEST — YYYY-MM-DD

Pulled from 4 queries (assigned, reported, watching, mentioned).
Wrote / updated <total> files in raw/jira/.

Tagging:
  <N> matched via parent epic
  <N> matched via fallback (labels / summary patterns)
  <N> need triage (no match)         ← will surface in /brain:morning

Notable:
  NEW today: <keys>
  STATUS CHANGES (vs yesterday's snapshot): <keys>
```

## Notes

- **Idempotent:** re-running on the same day overwrites today's snapshot per ticket. Status and comments evolve during the day; overwrite is correct.
- **JQL gotcha:** the Atlassian Cloud REST API often rejects `currentUser()` in JQL when called via OAuth. Always use the literal account ID from config.
- **Parent type filter:** `parent.fields.issuetype.name == "Epic"` is the strict gate. JIRA also lets sub-tasks have a parent that's a Story (not an epic) — those don't carry workstream signal, so don't treat them as project matches.
- **Cache lookups:** during a single run, never call `getJiraIssue` for the same key twice. Build the cache as you go.
- **Atlassian MCP failure mode:** if a JQL fails, log the error and skip that query; continue with the others. If all four fail, abort the command and tell the user to check Atlassian MCP auth.
- **`needs_triage: true` is the trigger** for `/brain:morning`'s "Needs quick call" section to surface this ticket for inline assignment.
