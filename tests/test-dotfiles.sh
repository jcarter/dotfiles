#!/usr/bin/env bash

set -euo pipefail

repoRoot="$(cd "$(dirname "$0")/.." && pwd)"
# mise links to physical paths, so resolve the temporary directory first.
temporaryDir="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$temporaryDir"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

# Apply a copy so the fixture can declare its own machine role.
testHome="$temporaryDir/home"
testRepo="$temporaryDir/repo"
mkdir -p "$testHome" "$testRepo"
cp -R "$repoRoot/mise.toml" "$repoRoot/home" "$repoRoot/templates" "$testRepo/"
printf '%s\n' '[env]' 'DOTFILES_ROLE = "personal"' > "$testRepo/mise.local.toml"

env \
    -u DOTFILES_DIR \
    -u DOTFILES_REPO \
    HOME="$testHome" \
    XDG_CONFIG_HOME="$temporaryDir/config-home" \
    MISE_CACHE_DIR="$temporaryDir/cache" \
    MISE_CONFIG_DIR="$temporaryDir/config" \
    MISE_DATA_DIR="$temporaryDir/data" \
    MISE_STATE_DIR="$temporaryDir/state" \
    MISE_PROJECT_ROOT="$testRepo" \
    MISE_TRUSTED_CONFIG_PATHS="$testRepo" \
    mise -C "$testRepo" bootstrap dotfiles apply --yes >/dev/null

# Include new untracked source files while honoring the repository's ignore rules.
while IFS= read -r -d '' relativePath; do
    source="$testRepo/$relativePath"
    target="$testHome/${relativePath#home/}"
    [[ -L "$target" ]] || fail "home source is not linked: $relativePath"
    [[ -e "$target" ]] || fail "home source is a dangling symlink: $target -> $(readlink "$target")"
    [[ "$(readlink "$target")" == "$source" ]] || fail "wrong symlink target: $target -> $(readlink "$target") (expected $source)"
done < <(git -C "$repoRoot" ls-files -z --cached --others --exclude-standard -- home/)

grep -Eq '^## name: Everforest Dark (Hard|Medium|Soft)$' "$repoRoot/home/.config/kitty/dark-theme.auto.conf" ||
    fail 'Kitty dark automatic theme is not an Everforest dark variant'
grep -Eq '^## name: Everforest Light (Hard|Medium|Soft)$' "$repoRoot/home/.config/kitty/light-theme.auto.conf" ||
    fail 'Kitty light automatic theme is not an Everforest light variant'
[[ ! -d "$repoRoot/home/.config/kitty/themes" ]] ||
    fail 'Copied Kitty theme collection should not be committed'

grep -Fqx 'atuin = "latest"' "$repoRoot/home/.config/mise/config.toml" ||
    fail 'Atuin is not declared as a mise tool'
if sed -n '/^\[tool_alias\]/,/^\[tools\]/p' "$repoRoot/home/.config/mise/config.toml" |
    grep -Eq '^(atuin|delta|fd) = '; then
    fail 'shared mise config must leave Intel-only Cargo aliases to the overlay'
fi
for cargoAlias in \
    'atuin = "github:atuinsh/atuin"' \
    'delta = "cargo:git-delta"' \
    'fd = "cargo:fd-find"'; do
    grep -Fqx "$cargoAlias" "$repoRoot/home/.config/mise/config.macos-x64.toml" ||
        fail "Intel mise overlay lacks $cargoAlias"
done
grep -Fqx 'auto_env = true' "$repoRoot/home/.config/mise/miserc.toml" ||
    fail 'mise platform-specific config selection is not enabled'
grep -Fqx '        atuin init fish | source' "$repoRoot/home/.config/fish/config.fish" ||
    fail 'Atuin Fish integration is not initialized'
grep -Fqx 'generate atuin atuin gen-completions --shell fish' "$repoRoot/.mise/tasks/generate-completions" ||
    fail 'Atuin Fish completions are not generated'
grep -Fqx 'name = "everforest-auto"' "$repoRoot/home/.config/atuin/config.toml" ||
    fail 'Atuin does not select the Everforest theme'
grep -Fq '@ansi_(' "$repoRoot/home/.config/atuin/themes/everforest-auto.toml" ||
    fail 'Atuin Everforest theme does not follow the terminal ANSI palette'

printf '%s\n' 'Dotfile symlink tests passed.'
