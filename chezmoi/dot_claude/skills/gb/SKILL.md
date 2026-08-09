---
allowed-tools: Bash(gh browse:*)
argument-hint: "[<number> | <path>] [flags]"
description: "Opens the current GitHub repository (or an issue, PR, file, or commit) in the browser — same as the gb zsh alias"
---

## Context

- Arguments passed to this skill: $ARGUMENTS

## Behavior specification

Run exactly this command, passing through any arguments given, and discard its output:

```
gh browse $ARGUMENTS &>/dev/null
```

This mirrors the `gb` zsh alias (`chezmoi/dot_config/zsh/git.zsh`), which is defined as:

```sh
_gh-browse() {
    gh browse "$@" &>/dev/null
}
alias gb='_gh-browse'
```

With no arguments, it opens the current repository's page. A number opens that issue or PR. A file path opens that file. Flags like `--branch`, `--commit`, `--settings` are forwarded as-is. Do not print explanations or ask for confirmation — just run the command silently, matching the original alias's behavior of suppressing all output.
