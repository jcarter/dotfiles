---
name: mise-dotfiles
description: Maintain and review this repository's mise-based macOS dotfiles lifecycle, including install.sh, mise configuration and tasks, home mappings, Brewfile ownership, machine roles, trust boundaries, and personal/work OMP rendering. Use for implementation, diagnosis, migration, or KISS and security review of bootstrap, sync, update, package, dotfile, or role changes.
globs:
  - "mise*.toml"
  - "Brewfile"
  - "install.sh"
  - "README.md"
  - "home/**"
  - ".mise/tasks/**"
  - ".omp/skills/mise-dotfiles/**"
  - "lib/**"
  - "templates/**"
  - "tests/**"
---

# mise dotfiles

## Repository contract

- `home/.config/mise/config.toml` declares global tools and must remain plain data without executable repository logic.
- `mise.toml` declares repository-local dotfile mappings, macOS defaults, and bootstrap ordering.
- `home/` mirrors static files under the user's home directory.
- `templates/` contains renderer inputs that must not be linked directly.
- `Brewfile` owns system packages and GUI applications on both Macs.
- `.mise/tasks/brew-bundle` is the sole Brewfile implementation; `install.sh`, `sync`, and `update` call it explicitly.
- `mise.local.toml` is untracked and contains non-secret host differences, including `DOTFILES_ROLE = "personal"` or `"work"`.
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

When changing installation, packages, or bootstrap behavior, trace `install.sh` through `brew-bundle`, `mise.toml`, and the `sync` and `update` tasks as one workflow. Keep one obvious owner for each operation; do not duplicate convergence in hooks or parallel implementations.

## Platform and role boundaries

Architecture differences should be detected from Homebrew at runtime. Host-purpose differences belong in the untracked `mise.local.toml`; the role selects personal versus work behavior.

## Safety

- Trust only the repository's root `mise.toml`. Never use `mise trust -a` or trust `home/.config/mise/config.toml`.
- Do not run `mise run update` when only convergence is intended; it upgrades packages and tools.
- Do not put credentials in `home/`, `templates/`, `mise*.toml`, or `Brewfile`.
- Do not add the rendered OMP config to `[dotfiles]`.
- Do not run `sync`, `update`, or a live bootstrap solely to validate an edit.

## Validation

Run the smallest relevant checks from the repository root:

- For installer, trust, Brewfile, or bootstrap changes: `tests/test-bootstrap.sh`.
- For OMP renderer, sync, template, or role changes: `tests/test-omp-settings.sh`.
- For Bash changes: `bash -n install.sh lib/utils.sh .mise/tasks/*`.
- For Fish changes: `fish -n home/.config/fish/config.fish home/.config/fish/conf.d/*.fish home/.config/fish/functions/*.fish`.
- For every change: `git diff --check`, `env MISE_TRUSTED_CONFIG_PATHS="$PWD" mise fmt --check`, and `env MISE_TRUSTED_CONFIG_PATHS="$PWD" mise tasks validate`.

Use `MISE_TRUSTED_CONFIG_PATHS` only for validation so parsing the repository does not change machine trust. Run `mise run check` when current machine state is relevant; it is read-only but depends on the installed Homebrew and mise state.
