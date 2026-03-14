---
name: chezmoi
description: Use when managing dotfiles with chezmoi, setting up new machines, creating templates for cross-platform configs, adding run scripts, or structuring a chezmoi source directory.
---

# chezmoi

## Overview

chezmoi manages dotfiles across machines. Source directory (`~/.local/share/chezmoi`) holds templates and scripts; config file (`~/.config/chezmoi/chezmoi.toml`) holds machine-specific data. `chezmoi apply` renders templates and runs scripts to configure the target machine.

## Quick Reference

### Commands

| Command | Purpose |
|---------|---------|
| `chezmoi init` | Initialize source directory |
| `chezmoi init --apply $REPO` | Clone repo and apply in one step |
| `chezmoi add $FILE` | Add file to source directory |
| `chezmoi add --template $FILE` | Add as template |
| `chezmoi apply -v` | Apply changes (verbose) |
| `chezmoi diff` | Preview changes before applying |
| `chezmoi data` | Show available template variables |
| `chezmoi execute-template '{{ .chezmoi.os }}'` | Test template expressions |
| `chezmoi cat $FILE` | Render file without writing |
| `chezmoi cd` | Shell into source directory |
| `chezmoi update` | Pull remote changes and apply |
| `chezmoi doctor` | Diagnose issues |
| `chezmoi state delete-bucket --bucket=scriptState` | Reset run_once/run_onchange state |

### Source Directory Naming

| Prefix | Effect |
|--------|--------|
| `dot_` | Becomes `.` (e.g., `dot_config/` → `.config/`) |
| `run_` | Execute as script every apply |
| `run_once_` | Execute only once |
| `run_onchange_` | Execute when content changes |
| `before_` | Run before file updates |
| `after_` | Run after file updates |
| `exact_` | Remove unmanaged children |
| `private_` | Set 0600 permissions |
| `executable_` | Set executable bit |
| `create_` | Create only if missing |
| `modify_` | Modify existing file |
| `remove_` | Delete target |
| `empty_` | Allow empty files |
| `symlink_` | Create symlink |
| `encrypted_` | Encrypt in source |
| `literal_` | Stop prefix parsing |

| Suffix | Effect |
|--------|--------|
| `.tmpl` | Process as Go template |

Prefixes combine and order matters: `run_once_before_01-install.sh.tmpl`

## Templates

chezmoi uses Go `text/template` + Sprig functions.

### Key Variables

```
{{ .chezmoi.os }}          # "darwin", "linux"
{{ .chezmoi.arch }}        # "amd64", "arm64"
{{ .chezmoi.hostname }}    # machine hostname
{{ .chezmoi.username }}    # current user
{{ .email }}               # custom data from chezmoi.toml
```

### Conditionals

```
{{ if eq .chezmoi.os "darwin" -}}
# macOS config
{{ else if eq .chezmoi.os "linux" -}}
# Linux config
{{ end -}}
```

### Quoting

```
email = {{ .email | quote }}
```

### Whitespace Control

`{{-` trims leading whitespace, `-}}` trims trailing.

## Cross-Platform Structure

### Config File (`~/.config/chezmoi/chezmoi.toml`)

Machine-specific secrets/data. Never committed.

```toml
[data]
    email = "me@example.com"
```

### Data Files (`.chezmoidata/`)

Committed data shared across machines. Supports YAML, TOML, JSON.

```yaml
# .chezmoidata/packages.yaml
packages:
  darwin:
    brews:
      - mise
      - fish
    casks:
      - google-chrome
  linux:
    brews:
      - mise
      - fish
```

### Declarative Package Installation

Pair `.chezmoidata/packages.yaml` with `run_onchange_` scripts:

```bash
# run_onchange_install-packages-darwin.sh.tmpl
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash

brew bundle --file=/dev/stdin <<EOF
{{ range .packages.darwin.brews -}}
brew {{ . | quote }}
{{ end -}}
{{ range .packages.darwin.casks -}}
cask {{ . | quote }}
{{ end -}}
EOF
{{ end -}}
```

Packages reinstall automatically when the YAML changes.

### OS-Conditional Scripts

```bash
# run_once_before_01-install-deps.sh.tmpl
{{ if eq .chezmoi.os "linux" -}}
#!/bin/bash
sudo apt update && sudo apt install -y build-essential curl git
{{ end -}}
```

Empty template output = script not executed. Use this for OS gating.

### .chezmoiignore

Exclude files per OS:

```
{{ if ne .chezmoi.os "darwin" }}
Library/
{{ end }}
{{ if ne .chezmoi.os "linux" }}
.config/some-linux-only-app/
{{ end }}
```

### Shared Templates (`.chezmoitemplates/`)

Reusable fragments referenced via `{{ template "name" . }}`.

## Typical Directory Layout

```
~/.local/share/chezmoi/
  .chezmoidata/
    packages.yaml
  .chezmoitemplates/
    shared-fragment.tmpl
  .chezmoiignore
  chezmoi.toml.example          # Reference for new machine setup
  dot_config/
    fish/
      config.fish
    git/
      config.tmpl               # Templated gitconfig
  run_once_before_01-install-deps.sh.tmpl
  run_once_before_02-install-homebrew.sh.tmpl
  run_onchange_install-packages-darwin.sh.tmpl
  run_onchange_install-packages-linux.sh.tmpl
```

## New Machine Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
cp chezmoi.toml.example ~/.config/chezmoi/chezmoi.toml
# Edit chezmoi.toml with machine-specific values
chezmoi init --apply $GITHUB_USERNAME
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Template syntax in non-`.tmpl` file | `{{ }}` rendered literally. Add `.tmpl` suffix. |
| Script without shebang | Must start with `#!/bin/bash` (or similar) |
| `run_once` script changed but won't re-run | It already ran successfully. Use `run_onchange_` or reset state. |
| Empty template = deleted target | chezmoi removes target if template renders empty. Use `empty_` prefix to keep. |
| Secrets in committed files | Use `chezmoi.toml` (local only) for secrets, reference via template vars. |
| Homebrew path differs Linux vs macOS | Linux: `/home/linuxbrew/.linuxbrew/bin/brew`, macOS: `/opt/homebrew/bin/brew` (ARM) or `/usr/local/bin/brew` (Intel) |
