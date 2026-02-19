# Existing App Definitions Reference

Quick reference for all app definitions in `apps/`. Sorted alphabetically.

| App name | Handlers | OS support | Notable features |
|---|---|---|---|
| alt-tab | brew (cask) | macos | |
| btop | brew, apt | both | |
| chezmoi | brew, custom | both | custom: version_cmd, latest_cmd, uninstall |
| claude-code | brew (cask), custom | both | command: `claude`; custom: version_cmd, latest_cmd, uninstall |
| colordiff | brew, apt | both | |
| curl | apt | linux | macOS preinstalled |
| deck | go | cross-platform | requires: go |
| delve | go | cross-platform | command: `dlv`; requires: go |
| docker-cli | brew (cask), apt | both | command: `docker`; apt: pre_install, uninstall (repo setup) |
| fd | brew, apt | both | apt package: `fd-find` |
| font-hackgen-nerd | brew (cask) | macos | |
| fzf | brew, custom | both | custom: version_cmd, latest_cmd, uninstall |
| gh | brew, apt | both | apt: pre_install, uninstall (repo setup) |
| ghostty | brew (cask), custom | both | custom: version_cmd, latest_cmd, uninstall |
| ghq | brew, go | both | go handler scoped to linux |
| git | brew, apt | both | |
| git-credential-manager | brew (cask) | macos | **disabled** |
| gitify | brew (cask) | macos | **disabled** |
| go | brew, custom | both | custom: version_cmd, latest_cmd, uninstall; uses PKGMUX_PINNED_VERSION |
| goimports-reviser | go | cross-platform | requires: go |
| golangci-lint | brew, go | both | requires: go; go handler scoped to linux |
| golangci-lint-langserver | go | cross-platform | requires: go |
| google-chrome | brew (cask), custom | both | custom: version_cmd, latest_cmd, uninstall |
| google-drive | brew (cask) | macos | |
| google-japanese-ime | brew (cask) | macos | |
| gopls | go | cross-platform | requires: go |
| helix | brew, custom | both | command: `hx`; custom: version_cmd, latest_cmd, uninstall |
| hiddenbar | brew (cask) | macos | |
| hugo | go | cross-platform | requires: go |
| jq | brew, apt | both | |
| keepassxc | brew (cask), apt | both | |
| kind | brew, custom | both | custom: version_cmd, latest_cmd, uninstall |
| krew | custom | cross-platform | command: `kubectl-krew`; requires: kubectl; custom: version_cmd, latest_cmd |
| kubectl | brew, custom | both | custom: version_cmd, latest_cmd, uninstall; brew package: `kubernetes-cli` |
| kustomize | brew, custom | both | custom: version_cmd, latest_cmd, uninstall |
| lazygit | brew, custom | both | custom: version_cmd, latest_cmd, uninstall |
| lima | brew, custom | both | command: `limactl`; custom: version_cmd, latest_cmd, uninstall |
| mac-mouse-fix | brew (cask) | macos | |
| meetingbar | brew (cask) | macos | |
| node | brew, apt | both | apt package: `nodejs` |
| raycast | brew (cask) | macos | |
| rust | brew, custom | both | command: `rustup`; custom: version_cmd, latest_cmd, uninstall |
| setup-envtest | go | cross-platform | requires: go |
| starship | brew, custom | both | custom: version_cmd, latest_cmd, uninstall |
| staticcheck | go | cross-platform | requires: go |
| tmux | brew, apt | both | |
| uv | brew, custom | both | custom: version_cmd, latest_cmd, uninstall |
| wget | brew, apt | both | |
| yq | brew, custom | both | custom: version_cmd, latest_cmd, uninstall |

## Summary Statistics

- **Total apps:** 49
- **macOS only:** 10 (alt-tab, font-hackgen-nerd, git-credential-manager, gitify, google-drive, google-japanese-ime, hiddenbar, mac-mouse-fix, meetingbar, raycast)
- **Linux only:** 1 (curl)
- **Both (OS-specific handlers):** 29
- **Cross-platform (no OS filter):** 9 (deck, delve, goimports-reviser, golangci-lint-langserver, gopls, hugo, krew, setup-envtest, staticcheck)

### Handler usage

| Handler | Count |
|---|---|
| brew (formula) | 26 |
| brew (cask) | 17 |
| apt | 14 |
| custom | 18 |
| go | 14 |

### Notable patterns

- **has `command`** (binary name differs from app name): claude-code, delve, docker-cli, helix, krew, lima, rust
- **has `requires`**: deck, delve, goimports-reviser, golangci-lint, golangci-lint-langserver, gopls, hugo, krew, setup-envtest, staticcheck
- **has `pre_install`** (apt repo setup): docker-cli, gh
- **uses `PKGMUX_PINNED_VERSION`**: go
- **cross-platform custom** (no `os` filter on custom handler): krew
- **disabled**: git-credential-manager, gitify
