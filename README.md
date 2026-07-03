# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io) as a macOS-only dotfiles repo.

## What's installed

### Terminal & shell

| App | How |
|-----|-----|
| [Ghostty](https://ghostty.org) | Homebrew cask (macOS) |
| [fish](https://fishshell.com) | Homebrew |
| [Maple Mono NF](https://github.com/subframe7536/maple-font) | Homebrew cask (macOS) |

Fish plugins via [Fisher](https://github.com/jorgebucaran/fisher):

| Plugin | Purpose |
|--------|---------|
| [Tide v6](https://github.com/IlanCosman/tide) | Prompt |
| [autopair.fish](https://github.com/jorgebucaran/autopair.fish) | Auto-close brackets and quotes |
| [pond](https://github.com/marcransome/pond) | Named environment management |
| [fzf.fish](https://github.com/PatrickF1/fzf.fish) | Fuzzy-find history, files, processes |

### Dev tools

Managed by [mise](https://mise.jdx.dev) (installed via Homebrew):

| Tool | Version |
|------|---------|
| Erlang | latest |
| Elixir | latest |
| Node | latest |
| Rust | latest |
| Go | latest |
| [Herdr](https://github.com/ogulcancelik/herdr) | latest |
| [Oh My Pi](https://github.com/can1357/oh-my-pi) | latest |

### Productivity

| App | How |
|-----|-----|
| [Obsidian](https://obsidian.md) | Homebrew cask (macOS) |

### Config managed

| Tool | What's configured |
|------|------------------|
| Git | Global identity (name + email via chezmoi template), sensible defaults |
| [gh](https://cli.github.com) | SSH protocol enforced (prevents `gh` from silently rewriting remotes to HTTPS) |
| chezmoi | Installed via Homebrew so it self-updates with `brew upgrade` |

---

## Everforest theme

All apps share a coordinated [Everforest](https://github.com/sainnhe/everforest) palette that **automatically switches between dark and light** when macOS appearance changes — no manual toggle needed.

| App | Dark variant | Light variant |
|-----|-------------|---------------|
| Ghostty | Everforest Dark Hard | Everforest Light Medium |
| Fish syntax | everforest-medium dark | everforest-medium light |
| Tide prompt | Full Everforest Dark Medium palette | Full Everforest Light Medium palette |
| Oh My Pi | everforest-dark | everforest-light |

## Setup on a new Mac

1. Run the bootstrap command:

   ```bash
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /tmp init --apply gh:jcarter
   ```

   `gh:jcarter` is a chezmoi shorthand for `https://github.com/jcarter/dotfiles`.
   The bootstrap binary is installed to `/tmp` and is cleaned up automatically;
   Homebrew owns the permanent chezmoi installation.

   You will be prompted for your name and email, then chezmoi will:
   - Install Homebrew
   - Install fish, mise, and ghostty via Homebrew
   - Install erlang, elixir, node, rust, and go via mise
   - Configure git and fish
   - Set fish as your default shell (you will be prompted for your password)

## Updating

After pulling changes to the dotfiles repo:

```bash
chezmoi update       # pull remote changes and apply
```

### Updating Oh My Pi settings

`~/.omp/agent/config.yml` is managed as a whole file. After changing settings through OMP, back up the live file into chezmoi before the next apply:

```bash
chezmoi diff ~/.omp/agent/config.yml
chezmoi add ~/.omp/agent/config.yml
```

Use `chezmoi diff` first to review what OMP changed. If the live changes are not wanted, run `chezmoi apply ~/.omp/agent/config.yml` instead to restore the backed-up version.

To upgrade chezmoi itself:

```bash
brew upgrade chezmoi # or: chezmoi upgrade
```

## Adding new dotfiles

```bash
chezmoi add ~/.some_config             # plain file
chezmoi add --template ~/.some_config  # file with template variables
```

## Testing

Run these checks locally on macOS before applying broad changes:

```bash
# Diagnose chezmoi configuration and environment issues.
chezmoi doctor

# Confirm template data is available for the current Mac.
chezmoi data

# Preview changes that would be applied to this Mac.
chezmoi diff

# Render sensitive or templated files without writing them.
chezmoi cat ~/.gitconfig
chezmoi cat ~/.omp/agent/config.yml
```

For a full setup smoke test on the current Mac, review `chezmoi diff` first, then run `chezmoi apply -v`.
