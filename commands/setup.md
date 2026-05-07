---
description: First-time onboarding — collect identity, integrations, write brain.config.yaml, wire commands
model: sonnet
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__atlassianUserInfo, mcp__claude_ai_Atlassian_Rovo__authenticate
---

# /brain:setup — First-time onboarding

Run this once after cloning the brain template. It collects identity, validates GitHub + Atlassian auth, writes `brain.config.yaml`, and ensures `~/.claude/commands/brain` is symlinked.

Re-run anytime to update settings (existing values become defaults you can accept by hitting enter).

## Core rules

- **Idempotent.** Re-running with an existing `brain.config.yaml` shows current values as defaults; the user can keep or change each.
- **Writes to disk only at the end** — collect all answers first, then commit in one batch with a confirmation preview.
- **Use `AskUserQuestion`** for any choice between options. Use plain-text prompts only for genuinely free-form input (name, email, slug, project key).
- **Don't write secrets.** `brain.config.yaml` only stores identity + integration metadata (cloud IDs, account IDs, project keys). Never tokens.

## Instructions for Claude

### Step 1: Resolve brain path

Brain path: `$BRAIN_DIR` env var or default `~/brain`. Confirm `$BRAIN/CLAUDE.md` exists. If not, stop with: `No brain at <path>. Did you clone the brain template here? Set BRAIN_DIR or run from the brain directory.`

Check if `$BRAIN/brain.config.yaml` already exists. If yes, read it — its values become defaults for the prompts below.

### Step 2: Identity

Gather **one prompt at a time** (free-text, no AskUserQuestion):

1. `Name (default: <existing>):` — any string. Required.
2. `Email (default: <existing>):` — must contain `@`. Required.
3. `Role / title (default: <existing>):` — any string. Required.
4. `Organization (default: <existing>):` — any string. Required.
5. `Team (default: <existing>):` — any string. Optional; press enter to leave blank.

### Step 3: GitHub

Check gh auth:
```bash
gh auth status 2>&1 | head -3
```

- **If not authed:** print `GitHub CLI is not authenticated. Run \`gh auth login\` in another terminal, then re-run /brain:setup.` and stop.
- **If authed:** capture the handle: `gh api user --jq .login`. Show: `Detected GitHub handle: <login> ✓`.

Then prompt (free-text):
- `Default GitHub org (used by ingest-prs filtering; default: <existing or login>):`

### Step 4: Atlassian / JIRA (optional)

Use AskUserQuestion (single-select):
- Question: `Use the claude.ai Atlassian MCP for JIRA?`
- Options:
  - `Yes — set up now` (most users)
  - `Skip — I'll use /brain:capture for JIRA content manually`

If skipped, proceed to Step 5 with no JIRA config (write `jira: null` later).

If yes:

1. Try `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources`.
   - **On success:** capture `cloudId`, `name`, `url` from the first resource that has `read:jira-work` in its scopes.
   - **On auth error:** call `mcp__claude_ai_Atlassian_Rovo__authenticate` and tell the user `Authorize in your browser, then say "done" here.` Wait for the user reply, then retry the resource discovery.
2. Try `mcp__claude_ai_Atlassian__atlassianUserInfo`. Capture `account_id` and confirm the Atlassian-side identity matches the email from Step 2 (warn if not).
3. If multiple Atlassian resources available, ask via AskUserQuestion which to use:
   - Question: `Which Atlassian site?`
   - Options: one per resource (`<name> — <url>`).
4. Default JIRA project key (free-text):
   - `Default JIRA project key for new tickets (e.g. PROJ; default: <existing or none>):`

### Step 5: Preview before writing

Show the assembled config and confirm via AskUserQuestion:

```
About to write brain.config.yaml:

  user:
    name:           <name>
    email:          <email>
    role:           <role>
    org:            <org>
    team:           <team>
    github_handle:  <gh login>
  jira:
    cloud_id:       <cloud-id>
    site_url:       <https://<site>.atlassian.net>
    account_id:     <account-id>
    default_project_key:  <PROJ>
  github:
    default_org:    <github-org>
```

- Question: `Save this config?`
- Options:
  - `Yes, save it`
  - `No, restart` (loop back to Step 2)
  - `Cancel`

### Step 6: Write to disk (atomic batch)

On confirm:

1. Write `$BRAIN/brain.config.yaml` with the assembled YAML. Skip any block the user opted out of (e.g., omit `jira:` if Step 4 was skipped).

2. Ensure `.gitignore` covers personal data. If `$BRAIN/.gitignore` doesn't already include `brain.config.yaml`, append a block. Don't duplicate existing entries.

3. Run install.sh to wire the commands into Claude Code:
   ```bash
   bash $BRAIN/install.sh
   ```
   If it fails (e.g., `~/.claude/commands/brain` exists as a non-symlink), surface the error verbatim and stop — don't try to clobber.

### Step 7: Smoke check

Verify each integration is reachable in this session:

- **GitHub:** already validated in Step 3. Print `GitHub: ✓`.
- **Atlassian MCP:** if Step 4 succeeded, run a tiny sanity query (e.g., `searchJiraIssuesUsingJql` with `assignee = <accountId> AND statusCategory != Done` limit 1). Print `Atlassian: ✓ (sample query returned <N> ticket(s))`. On error, print `Atlassian: ⚠ <error>` but don't block setup completion.
- **Brain commands:** confirm `~/.claude/commands/brain` is a symlink. Print `Commands: ✓ — 12 commands available as /brain:*`.

### Step 8: Final output

```
Setup complete.

What's wired:
  brain.config.yaml          — written
  .gitignore                 — covers personal data
  ~/.claude/commands/brain   — symlink in place

Try next:
  /brain:resume               — load full context for the first time
```

## Notes

- This command is the only place that writes `brain.config.yaml`. All other commands read it.
- The Atlassian write-scope check is implicit: if `getAccessibleAtlassianResources` returns a resource with `write:jira-work` scope, the JIRA-aware commands can read tickets. If not, the user will see auth errors when they try.
- Rerunning `/brain:setup` after the brain has accumulated content (raw/, sessions/, lessons/) is safe — only the config file and gitignore + symlink are touched.
