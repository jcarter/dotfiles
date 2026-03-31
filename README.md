# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io).

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

## Setup on a new machine

1. Run the bootstrap command:

   ```bash
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /tmp init --apply gh:jcarter
   ```

   `gh:jcarter` is a chezmoi shorthand for `https://github.com/jcarter/dotfiles`.
   The bootstrap binary is installed to `/tmp` and is cleaned up automatically;
   Homebrew owns the permanent chezmoi installation.

   You will be prompted for your name and email, then chezmoi will:
   - Install system dependencies (Linux only)
   - Install Homebrew
   - Install fish, mise, and ghostty (macOS) via Homebrew
   - Install erlang, elixir, node, rust, and go via mise
   - Configure git and fish
   - Set fish as your default shell (you will be prompted for your password)

## Updating

After pulling changes to the dotfiles repo:

```bash
chezmoi update       # pull remote changes and apply
```

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

Uses a Docker container as a clean Linux environment. Requires Docker.

```bash
# 1. Tear down any existing container
docker stop chezmoi-test && docker rm chezmoi-test

# 2. Spin up fresh Ubuntu with dotfiles mounted read-only
docker run -d --name chezmoi-test -v "$(pwd)":/dotfiles:ro ubuntu:latest sleep infinity

# 3. Bootstrap the container (minimal prereqs only)
docker exec chezmoi-test bash -c '
apt update && apt install -y curl sudo &&
useradd -m -s /bin/bash testuser &&
echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers &&
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
'

# 4. Set up chezmoi as testuser and apply
#    The config is written manually here because this test flow copies files
#    directly and calls 'chezmoi apply', bypassing 'chezmoi init' (which is
#    what normally triggers .chezmoi.toml.tmpl on a real new machine).
docker exec chezmoi-test su - testuser -c '
mkdir -p ~/.local/share/chezmoi ~/.config/chezmoi &&
cp -r /dotfiles/. ~/.local/share/chezmoi/ &&
cat > ~/.config/chezmoi/chezmoi.toml <<EOF
[data]
    name = "Justin"
    email = "justin@example.com"
EOF
chezmoi apply -v
'
```

To re-test after editing files locally without rebuilding the container:

```bash
docker exec chezmoi-test su - testuser -c 'cp -r /dotfiles/. ~/.local/share/chezmoi/ && chezmoi apply -v'
```
