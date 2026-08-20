#!/usr/bin/env bash

set -euo pipefail

repoRoot="$(cd "$(dirname "$0")/.." && pwd)"
temporaryDir="$(mktemp -d)"
trap 'rm -rf "$temporaryDir"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

testHome="$temporaryDir/home"
mkdir -p "$testHome"

HOME="$testHome" \
MISE_CACHE_DIR="$temporaryDir/cache" \
MISE_CONFIG_DIR="$temporaryDir/config" \
MISE_DATA_DIR="$temporaryDir/data" \
MISE_STATE_DIR="$temporaryDir/state" \
MISE_TRUSTED_CONFIG_PATHS="$repoRoot" \
mise -C "$repoRoot" bootstrap dotfiles apply --yes >/dev/null

managedTargets=(
    "$testHome/.hushlogin"
    "$testHome/.config/fish/config.fish"
    "$testHome/.config/fish/conf.d/colored_man.fish"
    "$testHome/.config/fish/conf.d/fisher_config.fish"
    "$testHome/.config/fish/fish_plugins"
    "$testHome/.config/fish/functions/render_prompt.fish"
    "$testHome/.config/fnox/config.toml"
    "$testHome/.config/git/config"
    "$testHome/.config/gh/config.yml"
    "$testHome/.config/kitty/kitty.conf"
    "$testHome/.config/mise/config.toml"
    "$testHome/.omp/agent/themes/everforest-dark.json"
    "$testHome/.local/bin/omp-render-settings"
    "$testHome/.local/bin/omp-sync-settings"
)

for target in "${managedTargets[@]}"; do
    [[ -L "$target" ]] || fail "managed target is not a symlink: $target"
    [[ -e "$target" ]] || fail "managed target is a dangling symlink: $target -> $(readlink "$target")"
done

[[ "$(readlink "$testHome/.config/fish/config.fish")" == "$repoRoot/home/.config/fish/config.fish" ]] ||
    fail 'Fish config does not link to the repository source'

printf '%s\n' 'Dotfile symlink tests passed.'
