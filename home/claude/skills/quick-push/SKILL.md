---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git remote:*), AskUserQuestion
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

### Step 2: Present Plan and Request Confirmation

Present the following information to the user using AskUserQuestion:

1. **Target repository and branch** (where commits will be pushed)
2. **Warnings** about any problematic changes found (if any)
3. **Commit plan:**
   - For each planned commit: list files to include and proposed commit message
   - If changes are already staged and appropriate for a single commit, show that plan
4. **Ask for confirmation** to proceed with the plan
   - Provide options: "Proceed", "Abort"
   - If problematic changes were found, suggest excluding them

### Step 3: Execute Plan (only if confirmed)

If the user confirms:

1. Stage files according to the plan (if not already staged appropriately)
2. Create commit(s) with the planned message(s)
   - Commit messages should describe the changes only (no co-author or other metadata)
3. Push to the current branch's remote

If the user aborts, stop without making any changes.
