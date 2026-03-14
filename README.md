# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io).

## What's included

- **Git** — global `.gitconfig` with templated email
- **Homebrew** — auto-installed on macOS and Linux
- **mise** — version manager for dev tools
- **fish** — shell

## Setup on a new machine

1. Install chezmoi:

   ```bash
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
   ```

2. Initialize and apply:

   ```bash
   chezmoi init --apply https://github.com/YOUR_USERNAME/dotfiles.git
   ```

   You will be prompted for your name and email. chezmoi will generate
   `~/.config/chezmoi/chezmoi.toml` automatically, then apply your dotfiles.

   This will automatically:
   - Install system dependencies (Linux only)
   - Install Homebrew
   - Install mise and fish via Homebrew
   - Generate your `.gitconfig`

## Updating

After pulling changes to the dotfiles repo:

```bash
chezmoi apply -v
```

## Adding new dotfiles

```bash
chezmoi add ~/.some_config          # plain file
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