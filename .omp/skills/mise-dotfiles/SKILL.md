---
name: mise-dotfiles
description: Manage this repository's macOS dotfiles, tools, Homebrew packages, machine roles, and bootstrap flow with mise. Use when changing tracked dotfiles, packages, per-machine configuration, or the personal/work OMP setup.
globs:
  - "mise*.toml"
  - "Brewfile"
  - "install.sh"
  - "home/**"
  - ".mise/tasks/**"
  - "lib/**"
  - "templates/**"
---

# mise dotfiles

## Repository contract

- `home/.config/mise/config.toml` declares global tools and shared environment.
- `mise.toml` declares repository-local dotfile mappings, macOS defaults, and bootstrap ordering.
- `home/` mirrors static files under the user's home directory.
- `templates/` contains renderer inputs that must not be linked directly.
- `Brewfile` owns system packages and GUI applications on both Macs.
- `~/.config/mise/config.local.toml` is untracked and contains non-secret host differences, including `DOTFILES_ROLE = "personal"` or `"work"`.
- Secrets stay in 1Password and are resolved through fnox. Never write secret values into tracked files or local mise configuration.

## Commands

| Command | Purpose |
|---|---|
| `./install.sh personal` | Install or converge a personal Mac from a checkout. |
| `./install.sh work` | Install or converge a work Mac from a checkout. |
| `mise run sync` | Require a clean checkout, fast-forward from Git, and converge the Mac without an explicit upgrade pass. |
| `mise run update` | Upgrade declared Homebrew packages and mise tools, then converge. |
| `mise run check` | Report Git, Homebrew, and mise state without applying changes or reading secrets. |
| `mise run omp-render-settings` | Generate the role-specific live OMP configuration. |
| `mise run omp-sync-settings` | Copy OMP's non-secret changes back to the tracked template and restore sentinels. |
| `mise bootstrap --dry-run --yes` | Preview the bootstrap plan. |

## Editing workflow

Edit tracked files in this repository directly; mise links them into the home directory. Commit and push those edits normally. On another Mac, `mise run sync` fast-forwards the repository and reapplies the declared state.

When adding a normal dotfile, put it under `home/` and add or extend its `[dotfiles]` mapping in `mise.toml`. Prefer `symlink-each` for directories that also contain untracked local files.

Do not link generated, secret-backed output. OMP's live `~/.omp/agent/config.yml` is rendered from `templates/omp/config.yml` after tools are installed. Its themes are static and may be linked from `home/.omp/agent/themes`.

## Platform and role boundaries

Architecture differences should be detected from Homebrew at runtime. Host-purpose differences belong in the untracked `config.local.toml`; the role selects personal versus work behavior.

## Safety

- Do not run `mise run update` when only convergence is intended; it upgrades packages and tools.
- Do not put credentials in `home/`, `templates/`, `mise*.toml`, or `Brewfile`.
- Do not add the rendered OMP config to `[dotfiles]`.
- Test changes with the repository checks before running a live bootstrap.
