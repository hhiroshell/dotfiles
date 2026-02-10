---
allowed-tools: Bash(git ls-files:*), Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git remote:*), AskUserQuestion
description: "Analyzes changes, plans commits, and pushes to remote after user confirmation"
---

## Context

- Current staged changes: !`git diff --cached`
- Current unstaged changes: !`git diff`
- Untracked files: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Remote tracking info: !`git remote -v`
- Recent commits: !`git log --oneline -10`

## Behavior specification (follow in order)

### Step 1: Analyze Changes

Review all staged and unstaged changes and identify:

1. **Problematic changes that should NOT be committed:**
   - Secret values (API keys, passwords, tokens, credentials)
   - Temporary/debug code (console.log, print statements for debugging, TODO/FIXME comments meant for removal)
   - Environment-specific configurations (.env files, local paths)
   - Large binary files or generated files
   - Incomplete or broken code

2. **Logical grouping of changes:**
   - Determine if changes should be organized into multiple commits
   - Group related changes together (e.g., feature code + tests, refactoring separate from features)

### Step 2: Present Plan

Present the commit plan to the user using the following template:

```
## Commit Plan

**Target:** {remote_name}/{branch_name} ({remote_url})

### Warnings
{warnings_if_any_or_"None"}

### Commits
{for_each_commit}
**Commit {n}:** {commit_message}
- {file_1}
- {file_2}
- ...
{end_for_each}
```

### Step 3: Request Confirmation

After presenting the plan, use AskUserQuestion to ask for confirmation:
- Provide options: "Proceed", "Abort"
- If problematic changes were found in Step 1, include an option to exclude them

### Step 4: Execute Plan (only if confirmed)

If the user confirms:

1. Stage files according to the plan (if not already staged appropriately)
2. Create commit(s) with the planned message(s)
   - Commit messages should describe the changes only (no co-author or other metadata)
3. Push to the current branch's remote

If the user aborts, stop without making any changes.
