# Dotfiles

- [Mise](https://github.com/jdx/mise) for  tools and apps
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

Run the installer and then sign into 1Password, then enable **Settings &gt; Developer &gt; Integrate with 1Password CLI**.

## Use

Run commands from `~/Source/dotfiles`:


| Command                                        | Result                                                                                   |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `./install.sh personal` or `./install.sh work` | Set up this Mac from a checkout                                                          |
| `mise run sync`                                | Pull the checkout and apply its configuration, installing missing apps without upgrading |
| `mise run update`                              | Upgrade mise, mise tools, and apps, then apply the configuration                         |
| `mise run check`                               | Report Git, app, and mise state                                                          |
| `mise run omp-hindsight`                       | Refresh the personal OMP Hindsight URL from 1Password                                    |
| `mise run omp-sync-settings`                   | Copy live OMP settings, except the ignore list, to `templates/omp/config.yml`            |


## Per-computer settings

The installer creates two untracked files:

- `mise.local.toml` holds `DOTFILES_ROLE` for this repository's tasks and OMP settings.
- `~/.config/git/config.local` holds Git name and email.

Put non-secret environment variables needed in every shell in `~/.config/mise/config.local.toml`. It is loaded globally and remains untracked.

Secrets stay in 1Password. Personal OMP uses Hindsight through fnox. Work OMP sets `memory.backend: off` without reading the Hindsight secret.

## OMP settings

mise merges only the keys this repository declares into `~/.omp/agent/config.yml`. OMP owns every other key, and its own changes survive `mise run sync`.

- `templates/omp/config.yml` holds the keys shared by every Mac.
- `templates/omp/role.yml.tera` holds `memory.backend` for each role.
- `templates/omp/sync-ignore.txt` lists the key paths sync-back never copies: each Mac's models (`modelRoles`, `task.agentModelOverrides`), role keys, OMP's `setupVersion`, and secrets.
- `mise run omp-hindsight` sets the personal `hindsight.apiUrl`; bootstrap runs it after tools are installed, so `mise run sync` also picks up a changed URL.

To keep OMP settings changed in OMP:

- Change them in OMP.
- Run `mise run omp-sync-settings`; it writes the whole live config, minus the ignored paths, to `templates/omp/config.yml`. It refuses to write `hindsight.apiUrl` even if the ignore list stops listing it.
- Review `git diff templates/omp/config.yml`, then commit and push.

Sync back before `mise run sync`, which reapplies the tracked values. Every synced key, including one OMP added on its own, becomes tracked and is applied to every Mac on its next sync. To keep a setting per-Mac, add its key path to `templates/omp/sync-ignore.txt` (one dot-separated path per line, `#` comments allowed); the next sync-back drops it from `templates/omp/config.yml`. `mise dot status --missing ~/.omp/agent/config.yml` reports when a declared key drifted. Deleting a key from a source stops managing it but leaves it in the live file.

## Files


| Path                                      | Purpose                                                              |
| ----------------------------------------- | -------------------------------------------------------------------- |
| `home/`                                   | Files linked into `$HOME`                                            |
| `home/.config/mise/config.toml`           | Global mise tools                                                    |
| `home/.config/mise/miserc.toml`           | Enables automatic platform config selection                          |
| `home/.config/mise/config.macos-x64.toml` | Intel fallbacks                                                      |
| `mise.toml`                               | Dotfile mappings, apps (`[bootstrap.packages]`), and bootstrap order |
| `.mise/tasks/`                            | Tasks for this repository                                            |
| `templates/`                              | Merge sources for the live OMP config                                |
