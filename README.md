# Dotfiles

- [Mise](https://github.com/jdx/mise) for CLI tools and applications
- [Atuin](https://atuin.sh/) for shell history
- [Everforest](https://github.com/sainnhe/everforest) for color theme
- [Maple Mono](https://github.com/subframe7536/maple-font) for font

Managed files are symnlinked to `~/.config` so changes made directly to the files will be reflected in the repo. Add new managed files under `home/` and map them in `mise.toml`.

# Install

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

The installer ensures Xcode Command Line Tools, installs mise, installs the apps in `mise.toml` `[bootstrap.packages]`, then pauses for 1Password. Sign in, then enable **Settings > Developer > Integrate with 1Password CLI**. Setup then runs `mise bootstrap`. The `op` CLI comes from mise.

On an existing Mac, identical apps already installed are adopted in place; casks Homebrew installed on Apple Silicon stay Homebrew-owned until removed from Homebrew.

Orca is not managed here; install it by hand.

## Use

Run commands from `~/Source/dotfiles`:

| Command | Result |
|---|---|
| `./install.sh personal` or `./install.sh work` | Set up this Mac from a checkout |
| `mise run sync` | Pull the checkout and apply its configuration, installing missing apps without upgrading |
| `mise run update` | Upgrade mise, mise tools, and apps, then apply the configuration |
| `mise run check` | Report Git, app, and mise state |
| `mise run omp-render-settings` | Rebuild the live OMP config |
| `mise run omp-sync-settings` | Save non-secret OMP changes |


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
| `home/.config/mise/miserc.toml` | Enables automatic platform config selection |
| `home/.config/mise/config.macos-x64.toml` | Intel fallbacks |
| `mise.toml` | Dotfile mappings, apps (`[bootstrap.packages]`), and bootstrap order |
| `.mise/tasks/` | Tasks for this repository |
| `templates/` | Generated-config sources |
