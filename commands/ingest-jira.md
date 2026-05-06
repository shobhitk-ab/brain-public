---
description: Pull JIRA tickets (mine + assigned + watched + recently updated) into raw/jira/
model: opus
allowed-tools: Read, Write, Bash, AskUserQuestion
---

# /brain:ingest-jira — Daily JIRA pull

Pulls your JIRA reality into `raw/jira/` as dated markdown snapshots.

> **Setup required:** This command needs a JIRA MCP tool. The reference implementation uses
> [Captain MCP](https://github.com/anthropics/anthropic-tools) with `mcp__captain__search_jira_issues`
> and `mcp__captain__get_jira_issue`. Swap in whichever JIRA MCP integration you have — the schema
> below is what you're writing, not the tool call itself.
>
> If you don't have a JIRA MCP, you can run this manually: export a JIRA filter to CSV/JSON and paste
> into `raw/inbox/`, then `/brain:capture` to route it.

## Instructions for Claude

### Step 1: Confirm JIRA auth

Use your JIRA MCP tool to confirm you can reach JIRA and identify the current user.

### Step 2: Run targeted JQLs

Execute these four JQLs via your JIRA MCP. Tune the lookback as needed.

1. **Assigned to me, active:**
   `assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC`
2. **Reported by me, active:**
   `reporter = currentUser() AND statusCategory != Done ORDER BY updated DESC`
3. **Watching:**
   `watcher = currentUser() AND statusCategory != Done AND updated >= -7d ORDER BY updated DESC`
4. **Recently updated where I commented or am mentioned:**
   `(comment ~ currentUser() OR text ~ currentUser()) AND updated >= -3d ORDER BY updated DESC`

Deduplicate by ticket key across results.

### Step 3: Write one file per ticket

Path: `raw/jira/YYYY-MM-DD-<KEY>.md`

If a file for today's date already exists for a key, skip it (idempotent run).

```markdown
---
key: <KEY>
title: <title>
status: <status>
priority: <priority>
assignee: <assignee>
reporter: <reporter>
updated: <ISO date>
project: <detect from key prefix — configure your project mappings below>
---

## Summary
<1-2 sentence summary>

## Description (condensed)
<key points only — skip boilerplate>

## Recent activity
<last 2-3 comments or status changes if available>
```

**Project detection:** Map your JIRA project key prefixes to your brain projects. Example:
```
MYPROJ-* → project-a
OTHERPROJ-* → project-b
```
Update `commands/ingest-jira.md` with your actual project key mappings.

### Step 4: Report

```
Ingested N tickets → raw/jira/
  NEW: <keys>
  SKIPPED (already today): <keys>
```
