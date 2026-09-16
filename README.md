# Dotfiles

Command on a fresh Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/jcarter/dotfiles/main/install.sh | bash -s -- personal
# or
curl -fsSL https://raw.githubusercontent.com/jcarter/dotfiles/main/install.sh | bash -s -- work
```

The installer clones to `~/Source/dotfiles`. Set `DOTFILES_DIR` to use another path:

```sh
curl -fsSL https://raw.githubusercontent.com/jcarter/dotfiles/main/install.sh |
  DOTFILES_DIR="$HOME/elsewhere/dotfiles" bash -s -- personal
```

Personal setup pauses for 1Password. Sign in, then enable **Settings > Developer > Integrate with 1Password CLI**.

## Use

Run commands from `~/Source/dotfiles`:

| Command | Result |
|---|---|
| `./install.sh personal` or `./install.sh work` | Set up this Mac from a checkout |
| `mise run sync` | Pull the checkout and apply its configuration |
| `mise run update` | Upgrade packages and tools, then apply the configuration |
| `mise run check` | Report Git, Homebrew, and mise state |
| `mise run omp-render-settings` | Rebuild the live OMP config |
| `mise run omp-sync-settings` | Save non-secret OMP changes |

Bootstrap runs during setup, sync, and update. It refreshes Fisher plugins as part of each convergence.

Edit an existing linked file under `~/.config`; the repository changes at once. Run `git status`, commit, and push. Add new managed files under `home/` and map them in `mise.toml`.

Fish, Kitty, and Yazi load their active Everforest configuration from this repository. The standalone `everforest-*` repositories are publication targets; VS Code remains an installed extension.

## Per-computer settings

The installer creates two untracked files:

- `mise.local.toml` holds `DOTFILES_ROLE` for this repository's tasks.
- `~/.config/git/config.local` holds Git name and email.

Put non-secret environment variables needed in every shell in `~/.config/mise/config.local.toml`. It is loaded globally and remains untracked.

Secrets stay in 1Password. Personal OMP uses Hindsight through fnox. Work OMP sets `memory.backend: off` without reading the Hindsight secret.

## Files

| Path | Purpose |
|---|---|
| `home/` | Files linked into `$HOME` |
| `home/.config/mise/config.toml` | Global mise tools |
| `mise.toml` | Dotfile mappings and bootstrap order |
| `.mise/tasks/` | Tasks for this repository |
| `Brewfile` and `templates/` | Packages and generated-config sources |
