#!/usr/bin/env bash

# Shared helpers for mise tasks. This file is sourced, not executed.
DOTFILES_REPO_ROOT="${MISE_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly DOTFILES_REPO_ROOT

dotfiles_prepare_mise() {
    # Link configs before a new mise process installs or upgrades tools.
    mise bootstrap dotfiles apply --yes \
        "$HOME/.config/mise/config.toml" \
        "$HOME/.config/mise/miserc.toml" \
        "$HOME/.config/mise/config.macos-x64.toml"
}
