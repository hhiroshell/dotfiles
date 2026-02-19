---
name: Add App Definition
description: This skill should be used when the user asks to "add an app", "create an app definition", "add a package to pkgmux", "define a new application", "write an app YAML", "set up a new tool", or mentions adding or editing software definitions in the apps/ directory. Provides the pkgmux YAML schema, handler types (brew, apt, go, custom), field conventions, style patterns, and an interactive workflow for generating correct app definition files.
---

# Add pkgmux App Definition

Generate pkgmux app definition YAML files in the `apps/` directory of this dotfiles repository.

## Workflow

### Step 1: Gather Information

Use AskUserQuestion to interactively collect:

1. **Application name** — the app identifier (used as filename and `name:` field)
2. **Installation reference URL** — official installation docs (used for `# cf.` comment and for fetching install methods)
3. **Binary name** — only if different from the app name (for the `command:` field)
4. **Dependencies** — any apps that must be installed first (for the `requires:` field)

### Step 2: Research Installation Methods

Fetch the installation reference URL using WebFetch to understand:

- Is a Homebrew formula or cask available?
- Is an apt package available? Does it need a third-party repository?
- Is it a Go-installable tool (`go install`)?
- Does it require a custom install script (GitHub releases, curl installer, etc.)?

### Step 3: Determine Handlers

Based on the research, determine which handler entries to include. Use AskUserQuestion to confirm the plan with the user:

- Present the proposed handlers (brew/apt/go/custom) and OS coverage
- Ask the user to confirm or adjust

### Step 4: Generate the YAML

Write the app definition to `apps/<name>.yaml` following all conventions below.

### Step 5: Verify

Read the generated file back and display it to the user. Ask if any adjustments are needed.

## YAML Schema

### File Location and Naming

- Place files at `apps/<name>.yaml` where `<name>` matches the `name:` field
- Use lowercase, hyphenated names matching the application's common name

### Top-Level Structure

```yaml
name: <app-name>
disabled: true               # optional: skip in install/upgrade/uninstall/doctor (still shown in list)
command: <binary-name>       # optional: only if binary differs from name
requires:                    # optional: logical app names checked before install
  - <dependency>
# cf. <installation-reference-url>
install:
  - <handler-entry>
  - <handler-entry>
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | App identifier, used as filename and for pkgmux commands |
| `command` | No | Binary name if different from `name` (e.g., `helix` → `hx`, `claude-code` → `claude`) |
| `disabled` | No | Set to `true` to skip in all operations except `list` (which shows a `(disabled)` marker) |
| `requires` | No | List of app names that must be installed first |
| `install` | Yes | List of handler entries |

Place a `# cf. <url>` comment immediately before `install:`, pointing to the official installation documentation.

## Handler Types

### brew (Homebrew)

For macOS packages. Two variants:

**Formula (CLI tool):**
```yaml
- type: brew
  package: <formula-name>
  os: macos
```

**Cask (GUI application):**
```yaml
- type: brew
  cask: <cask-name>
  os: macos
```

Use `package` for CLI tools, `cask` for GUI applications. Never combine both in one entry.

### apt

For Linux packages via apt-get:

```yaml
- type: apt
  package: <package-name>     # space-separated for multiple packages
  os: linux
  pre_install: |              # optional: run before apt-get install
    <setup-commands>
  uninstall: |                # optional: cleanup after apt-get remove
    <cleanup-commands>
```

`pre_install` typically adds GPG keys and repository sources. `uninstall` cleans up those additions.

### go

For Go-installable tools:

```yaml
- type: go
  package: <go-module-path>   # @latest appended automatically if no @version
```

No `os` field needed — works cross-platform. Optionally specify `os: linux` or `os: macos` to restrict the handler to one platform, typically when brew handles the other OS (see `ghq`, `golangci-lint`). Always include `requires: [go]` at the top level.

### custom

For tools requiring custom install scripts:

```yaml
- type: custom
  os: <macos|linux>           # optional: omit for cross-platform
  check: command -v <binary>
  pinned_version: "<version>" # optional: pin to specific version
  version_cmd: <shell-command-to-get-installed-version>
  latest_cmd: <shell-command-to-get-latest-version>
  script: |
    <install-commands>
  uninstall: |
    <uninstall-commands>
```

| Field | Required | Description |
|-------|----------|-------------|
| `check` | Yes | Command to verify installation (usually `command -v <binary>`) |
| `script` | Yes | Installation script |
| `version_cmd` | No | Extract installed version for doctor checks |
| `latest_cmd` | No | Fetch latest available version for outdated checks |
| `pinned_version` | No | Pin to specific version; makes `PKGMUX_PINNED_VERSION` available in script |
| `uninstall` | No | Cleanup commands |

## Style Conventions

1. **Field ordering:** `name` → `disabled` → `command` → `requires` → comment → `install`
2. **Handler ordering within install:** `brew` first (macOS), then `apt` or `custom` (Linux or cross-platform), then `go`
3. **Blank line** between handler entries in the install list
4. **version_cmd pattern:** `<cmd> --version 2>/dev/null | <awk/sed extraction>`
5. **latest_cmd pattern:** `curl -sS --max-time 10 "<api-url>" | jq -r '<extraction>'` — GitHub API is common: `https://api.github.com/repos/<owner>/<repo>/releases/latest`
6. **GitHub release latest_cmd:** Use `jq -r '.tag_name'` and pipe through `ltrimstr("v")` or `sed` if versions have a `v` prefix
7. **Custom install scripts for GitHub releases:** Fetch latest version, download binary/tarball, install to `/usr/local/bin`
8. **Uninstall for custom:** `sudo rm -f /usr/local/bin/<binary>` or `sudo rm -rf /usr/local/<dir>`

## Common Patterns

Consult existing app definitions in `apps/` for reference:

- **macOS-only GUI app (brew cask only):** `apps/alt-tab.yaml`, `apps/raycast.yaml`
- **Cross-platform CLI (brew + custom):** `apps/starship.yaml`, `apps/fzf.yaml`, `apps/helix.yaml`
- **Cross-platform CLI (brew + apt with third-party repo):** `apps/docker-cli.yaml`
- **Go tool:** `apps/gopls.yaml`, `apps/goimports-reviser.yaml`
- **Tool with dependencies:** `apps/krew.yaml` (requires kubectl), `apps/gopls.yaml` (requires go)

## Additional Resources

For the full catalog of all existing app definitions and their handler patterns:
- **`references/existing-apps.md`**
