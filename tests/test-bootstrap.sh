#!/usr/bin/env bash

set -euo pipefail

repoRoot="$(cd "$(dirname "$0")/.." && pwd)"
temporaryDir="$(mktemp -d)"
trap 'rm -rf "$temporaryDir"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

mkdir -p "$temporaryDir/bin" "$temporaryDir/home"

cat > "$temporaryDir/bin/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == shellenv ]]; then
    printf '%s\n' 'export HOMEBREW_PREFIX=/test/homebrew'
    exit 0
fi
printf 'brew %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF

cat > "$temporaryDir/bin/mise" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'mise %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF

chmod 700 "$temporaryDir/bin/brew" "$temporaryDir/bin/mise"
export BOOTSTRAP_TEST_LOG="$temporaryDir/actions.log"
testPath="$temporaryDir/bin:/usr/bin:/bin:/usr/sbin:/sbin"

grep -Fq 'Checkout location (default: ~/Source/dotfiles).' <("$repoRoot/install.sh" --help) || fail 'help does not show the Source checkout default'

HOME="$temporaryDir/home" \
PATH="$testPath" \
DOTFILES_SKIP_1PASSWORD_PROMPT=1 \
GIT_USER_NAME='Test User' \
GIT_USER_EMAIL='test@example.com' \
"$repoRoot/install.sh" personal >/dev/null

localConfig="$temporaryDir/home/.config/mise/config.local.toml"
gitConfig="$temporaryDir/home/.config/git/config.local"
grep -Fqx 'DOTFILES_ROLE = "personal"' "$localConfig" || fail 'personal role was not written'
[[ "$(git config --file "$gitConfig" user.name)" == 'Test User' ]] || fail 'Git name was not written'
[[ "$(git config --file "$gitConfig" user.email)" == 'test@example.com' ]] || fail 'Git email was not written'
[[ "$(readlink "$temporaryDir/home/.config/mise/config.toml")" == "$repoRoot/home/.config/mise/config.toml" ]] || fail 'global mise config was not linked'
grep -Fqx 'brew install git mise' "$BOOTSTRAP_TEST_LOG" || fail 'bootstrap dependencies were not requested'
grep -Fqx "brew bundle install --file=$repoRoot/Brewfile --no-upgrade" "$BOOTSTRAP_TEST_LOG" || fail 'Brewfile was not converged'
grep -Fqx 'mise trust -y -a' "$BOOTSTRAP_TEST_LOG" || fail 'mise trust was not requested'
grep -Fqx 'mise bootstrap --yes' "$BOOTSTRAP_TEST_LOG" || fail 'mise bootstrap was not requested'

# The same role is idempotent. A conflicting role must never rewrite the file.
HOME="$temporaryDir/home" PATH="$testPath" DOTFILES_SKIP_1PASSWORD_PROMPT=1 "$repoRoot/install.sh" personal >/dev/null
if HOME="$temporaryDir/home" PATH="$testPath" DOTFILES_SKIP_1PASSWORD_PROMPT=1 "$repoRoot/install.sh" work >/dev/null 2>&1; then
    fail 'conflicting role was accepted'
fi
grep -Fqx 'DOTFILES_ROLE = "personal"' "$localConfig" || fail 'conflicting role changed the local config'

# Replacing an unrelated global config requires the explicit migration flag.
unlink "$temporaryDir/home/.config/mise/config.toml"
printf '%s\n' '[tools]' > "$temporaryDir/home/.config/mise/config.toml"
if HOME="$temporaryDir/home" PATH="$testPath" DOTFILES_SKIP_1PASSWORD_PROMPT=1 "$repoRoot/install.sh" personal >/dev/null 2>&1; then
    fail 'existing global config was replaced without force'
fi
HOME="$temporaryDir/home" PATH="$testPath" DOTFILES_SKIP_1PASSWORD_PROMPT=1 "$repoRoot/install.sh" personal --force-dotfiles >/dev/null
[[ "$(readlink "$temporaryDir/home/.config/mise/config.toml")" == "$repoRoot/home/.config/mise/config.toml" ]] || fail 'forced global config replacement failed'
grep -Fqx 'mise bootstrap --yes --force-dotfiles' "$BOOTSTRAP_TEST_LOG" || fail 'force flag was not forwarded'

# A streamed installer creates the default ~/Source parent before cloning.
mkdir -p "$temporaryDir/clone-bin" "$temporaryDir/streamed"
ln -s "$temporaryDir/bin/brew" "$temporaryDir/clone-bin/brew"
ln -s "$temporaryDir/bin/mise" "$temporaryDir/clone-bin/mise"
cp "$repoRoot/install.sh" "$temporaryDir/streamed/install.sh"

cat > "$temporaryDir/clone-bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == clone ]]; then
    target=''
    for argument in "$@"; do
        target="$argument"
    done
    [[ -d "$(dirname "$target")" ]] || exit 9
    mkdir -p "$target/.git" "$target/home/.config/mise"
    cp "$BOOTSTRAP_TEST_REPO/mise.toml" "$target/mise.toml"
    cp "$BOOTSTRAP_TEST_REPO/home/.config/mise/config.toml" "$target/home/.config/mise/config.toml"
    : > "$target/Brewfile"
    printf 'git %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
    exit 0
fi
exec /usr/bin/git "$@"
EOF

chmod 700 "$temporaryDir/clone-bin/git" "$temporaryDir/streamed/install.sh"
cloneHome="$temporaryDir/clone-home"
clonePath="$temporaryDir/clone-bin:/usr/bin:/bin:/usr/sbin:/sbin"
HOME="$cloneHome" \
PATH="$clonePath" \
BOOTSTRAP_TEST_REPO="$repoRoot" \
DOTFILES_SKIP_1PASSWORD_PROMPT=1 \
GIT_USER_NAME='Test User' \
GIT_USER_EMAIL='test@example.com' \
"$temporaryDir/streamed/install.sh" personal >/dev/null

defaultCheckout="$cloneHome/Source/dotfiles"
[[ -d "$defaultCheckout/.git" ]] || fail 'default Source checkout was not cloned'
grep -Fqx "git clone --depth 1 https://github.com/jcarter/dotfiles.git $defaultCheckout" "$BOOTSTRAP_TEST_LOG" || fail 'clone did not use the Source checkout default'
[[ "$(readlink "$cloneHome/.config/mise/config.toml")" == "$defaultCheckout/home/.config/mise/config.toml" ]] || fail 'streamed install did not use the cloned config'

printf '%s\n' 'Bootstrap contract tests passed.'
