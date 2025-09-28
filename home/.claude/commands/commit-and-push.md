---
allowed-tools: Bash(git commit:*), Bash(git push:*)
description: "Commits staged changes and pushes to the remote of the current branch"
---

## Context

- Current staged changes: !`git diff --cached`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`
- You should do things only described in the Behavior specification. For example, you do not need to try to add unstaged changes.

## Behavior specification (follow in order)

Step 1. Generate a commit message based on the changes. The commit message should include only the description of changes and shouldn't include other information like co-author
Step 2. Commit with the generated message
Step 3. Push to the current branch's remote
