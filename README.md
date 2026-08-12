# Dotfiles

Run one command on a fresh Mac:

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

## Move from chezmoi

1. Review live changes that chezmoi has not captured:

   ```sh
   chezmoi diff
   ```

2. Clone the mise version:

   ```sh
   mkdir -p ~/Source
   git clone git@github.com:jcarter/dotfiles.git ~/Source/dotfiles
   cd ~/Source/dotfiles
   ```

3. Move machine-specific environment variables out of Fish:

   ```sh
   $EDITOR mise.local.toml
   ```

   ```toml
   [env]
   DOTFILES_ROLE = "personal" # or "work"
   # Add other non-secret variables here.
   ```

4. Preview the replacement of chezmoi-managed files:

   ```sh
   mise trust -y ./mise.toml
   mise bootstrap dotfiles apply --dry-run --force --yes
   ```

5. Apply the migration:

   ```sh
   ./install.sh personal --force-dotfiles
   # Work Mac:
   ./install.sh work --force-dotfiles
   ```

Keep the old chezmoi source until the new setup works. Do not run `chezmoi apply` after migration.

## Use

Run commands from `~/Source/dotfiles`:

| Command | Result |
|---|---|
| `mise run check` | Report Git, Homebrew, and mise state |
| `mise run sync` | Pull and apply changes |
| `mise run update` | Upgrade packages and tools, then apply |
| `mise run omp-render-settings` | Rebuild the live OMP config |
| `mise run omp-sync-settings` | Save non-secret OMP changes |

Edit an existing linked file under `~/.config`; the repository changes at once. Run `git status`, commit, and push. Add new managed files under `home/` and map them in `mise.toml`.

## Per-computer settings

The installer creates two untracked files:

- `mise.local.toml` holds `DOTFILES_ROLE` and non-secret environment variables for this computer.
- `~/.config/git/config.local` holds Git name and email.

Secrets stay in 1Password. Personal OMP uses Hindsight through fnox. Work OMP sets `memory.backend: off` without reading the Hindsight secret.

## Files

| Path | Purpose |
|---|---|
| `home/` | Files linked into `$HOME` |
| `home/.config/mise/config.toml` | Global mise tools |
| `mise.toml` | Dotfile mappings and bootstrap order |
| `.mise/tasks/` | Tasks for this repository |
| `Brewfile` and `templates/` | Packages and generated-config sources |
