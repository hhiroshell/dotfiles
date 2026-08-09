---
allowed-tools: Bash(gh browse:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(git branch:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*)
argument-hint: "[<number> | <path>] [flags]"
description: "Opens the current GitHub repository, or the PR you're working on, in the browser — same as the gb zsh alias, plus PR auto-detection when called with no arguments"
---

## Context

- Arguments passed to this skill: $ARGUMENTS
- Current branch: !`git branch --show-current`

## Behavior specification

### If arguments were given

Behave exactly like the `gb` zsh alias — pass the arguments straight through and discard output:

```
gh browse $ARGUMENTS &>/dev/null
```

A number opens that issue or PR, a file path opens that file, flags like `--branch`/`--commit`/`--settings` are forwarded as-is. Do not print explanations or ask for confirmation — just run it silently.

### If no arguments were given

Try to open the pull request for the work currently in progress, instead of just the repo's homepage:

1. Run `gh pr view --json number,url,title,state 2>/dev/null` (uses the current branch). If it returns an open PR, open it with `gh browse <number> &>/dev/null` and stop.
2. If that finds nothing (no PR for the current branch, or `gh pr view` errors), run `gh pr list --state open --json number,title,headRefName,url` and compare the PRs against the current branch name, recent commits (`git log --oneline -5`), and pending changes (`git status --porcelain`, `git diff --stat`). Only if exactly one PR is a clear, confident match for the current work, open it the same way.
3. If no PR can be confidently identified, fall back to the original behavior — `gh browse &>/dev/null` — which opens the repository's homepage. Briefly tell the user you fell back because no matching PR was found (one line, no elaboration).

Never guess between multiple equally-plausible PRs — fall back instead. Always run the final `gh browse` command silently (`&>/dev/null`); only step 3's fallback message is user-visible output.
