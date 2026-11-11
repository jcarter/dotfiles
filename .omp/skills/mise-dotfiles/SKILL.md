---
name: mise-dotfiles
description: Maintain and review this repository's mise-based macOS dotfiles lifecycle, including install.sh, mise configuration and tasks, home mappings, package ownership, machine roles, trust boundaries, and personal/work OMP settings. Use for implementation, diagnosis, migration, or KISS and security review of bootstrap, sync, update, package, dotfile, or role changes.
globs:
  - "mise*.toml"
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
- `mise.toml` declares repository-local dotfile mappings, macOS defaults, packages, and bootstrap ordering.
- `home/` mirrors static files under the user's home directory.
- `templates/` contains merge sources that must not be linked directly. mise merges only their keys into `~/.omp/agent/config.yml`; OMP owns every other key in that file. `templates/omp/config.yml` holds the shared keys, `templates/omp/role.yml.tera` holds each role's `memory.backend`, and `templates/omp/hindsight.yml.tera` holds `hindsight.apiUrl` only while the `omp-hindsight` task supplies it. `templates/omp/sync-ignore.txt` lists the live key paths sync-back never copies, including `modelRoles` and `task.agentModelOverrides`, which each Mac sets for itself and must not be tracked.
- `.mise/tasks/install-mise` owns the official mise binary at `~/.local/bin/mise`.
- `mise.toml` `[bootstrap.packages]` owns GUI applications and fonts through mise's `brew-cask` manager with `[bootstrap.brew] adopt = true`; Homebrew is not installed or required. `[tools]` owns command-line tools, including `op` (`1password-cli`).
- `install.sh` ensures Xcode Command Line Tools, installs mise, trusts `mise.toml`, runs `mise bootstrap packages apply --yes`, prompts for 1Password, then runs `mise bootstrap --yes`.
- On existing Macs, identical installed apps are adopted in place; casks Homebrew installed on Apple Silicon stay Homebrew-owned until removed from Homebrew.
- Orca is intentionally not managed; the user installs it by hand.
- `mise.local.toml` is untracked and contains non-secret host differences, including `DOTFILES_ROLE = "personal"` or `"work"` under `[env]`. Tasks receive it from mise; `templates/omp/role.yml.tera` reads it from the file because merge sources do not see `[env]`, and fails on any other value.
- Secrets stay in 1Password and are resolved through fnox. Never write secret values into tracked files or local mise configuration.

## Commands

| Command | Purpose |
|---|---|
| `./install.sh personal` | Install or converge a personal Mac from a checkout. |
| `./install.sh work` | Install or converge a work Mac from a checkout. |
| `mise run sync` | Require a clean checkout, fast-forward from Git, and converge the Mac without an explicit upgrade pass; `mise bootstrap` installs missing packages; bootstrap refreshes Fisher plugins. |
| `mise run update` | Upgrade mise, its tools, and declared packages (`mise bootstrap packages upgrade`); bootstrap refreshes Fisher plugins. |
| `mise run check` | Report Git, package (`mise bootstrap packages status --missing`), and mise state without applying changes or reading secrets. |
| `mise run omp-hindsight` | Set the personal `hindsight.apiUrl` from fnox; a no-op for the work role. Bootstrap runs it after tools are installed. |
| `mise run omp-sync-settings` | Write the whole live OMP config, minus the paths in `templates/omp/sync-ignore.txt`, to `templates/omp/config.yml` atomically with yq; keeps the template's key order, hard-fails rather than write `hindsight.apiUrl`, and fails when the live config is missing. |
| `mise dot status --missing ~/.omp/agent/config.yml` | Exit non-zero when a declared OMP key drifted, without reading secrets. |
| `mise bootstrap --dry-run --yes` | Preview the bootstrap plan. |

## Editing workflow

Edit tracked files in this repository directly; mise links them into the home directory. Commit and push those edits normally. On another Mac, `mise run sync` fast-forwards the repository and reapplies the declared state.

When adding a normal dotfile, put it under `home/` and add or extend its `[dotfiles]` mapping in `mise.toml`. Prefer `symlink-each` for directories that also contain untracked local files.

Do not link or copy OMP's live `~/.omp/agent/config.yml`; OMP rewrites it. To persist settings changed in OMP: change them in OMP, run `mise run omp-sync-settings`, review `git diff templates/omp/config.yml`, then commit and push. Do this before `mise run sync`, which reapplies the tracked values. Every synced key, including keys OMP adds on its own, becomes merge-owned on every Mac after its next sync; to keep a setting per-Mac, add its dot-separated path to `templates/omp/sync-ignore.txt`, and the next sync-back drops it from `templates/omp/config.yml`. Add any new OMP credential or per-Mac state key to the ignore list; edit role keys in `templates/omp/role.yml.tera`. Native `mise dot add` and `mise dot capture` cannot write merge entries back. Deleting a key from a source stops managing it but leaves it in the live file. Merged maps keep keys OMP added; lists and scalars are replaced. Its themes are static and may be linked from `home/.omp/agent/themes`.

When changing installation, packages, or bootstrap behavior, trace `install.sh` through `mise.toml` and the `sync`, `update`, and `check` tasks as one workflow. Keep one obvious owner for each operation; do not duplicate convergence in hooks or parallel implementations.

## Platform and role boundaries

Architecture differences should be detected at runtime. Host-purpose differences belong in the untracked `mise.local.toml`; the role selects personal versus work behavior.

## Safety

- Trust only the repository's root `mise.toml`. Never use `mise trust -a` or trust `home/.config/mise/config.toml`.
- Do not run `mise run update` when only convergence is intended; it upgrades packages and tools.
- Do not put credentials in `home/`, `templates/`, or `mise*.toml`.
- Manage `~/.omp/agent/config.yml` only through `merge = true` entries, never a link or copy mode.
- Do not read secrets in a merge source; status and diff render every source, and the dotfiles step runs before fnox is installed. Only the `omp-hindsight` task reads the Hindsight URL, and only for the personal role.
- `mise dot diff` prints live lines around a drifted key, which can include `hindsight.apiUrl`; prefer `mise dot status --missing` in shared output.
- Do not run `sync`, `update`, or a live bootstrap solely to validate an edit.

## Validation

Run the smallest relevant checks from the repository root:

- For installer, trust, packages, or bootstrap changes: `tests/test-bootstrap.sh`.
- For dotfile mappings or link modes: `tests/test-dotfiles.sh`.
- For OMP merge source, Hindsight task, sync-back, or role changes: `tests/test-omp-settings.sh`.
- For Bash changes: `bash -n install.sh lib/*.sh .mise/tasks/* tests/*.sh`.
- For Fish changes: `fish -n home/.config/fish/config.fish home/.config/fish/conf.d/*.fish home/.config/fish/functions/*.fish`.
- For Fish theme changes: `tests/test-fish-theme.sh`.
- For every change: `git diff --check`, `env MISE_TRUSTED_CONFIG_PATHS="$PWD" mise fmt --check`, and `env MISE_TRUSTED_CONFIG_PATHS="$PWD" mise tasks validate`.

Use `MISE_TRUSTED_CONFIG_PATHS` only for validation so parsing the repository does not change machine trust. Run `mise run check` when current machine state is relevant; it is read-only but depends on the installed package and mise state.
