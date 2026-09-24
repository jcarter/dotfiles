#!/usr/bin/env bash

set -euo pipefail

sourceRepoRoot="$(cd "$(dirname "$0")/.." && pwd)"
temporaryDir="$(mktemp -d)"
trap 'rm -rf "$temporaryDir"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

repoRoot="$temporaryDir/repo"
mkdir -p "$temporaryDir/bin" "$temporaryDir/home" "$repoRoot/home/.config/mise" "$repoRoot/.mise/tasks" "$repoRoot/lib"
cp "$sourceRepoRoot/install.sh" "$repoRoot/install.sh"
cp "$sourceRepoRoot/mise.toml" "$repoRoot/mise.toml"
cp "$sourceRepoRoot/Brewfile" "$repoRoot/Brewfile"
cp "$sourceRepoRoot"/home/.config/mise/{miserc,config,config.macos-x64}.toml "$repoRoot/home/.config/mise/"
cp "$sourceRepoRoot/.mise/tasks/brew-bundle" "$repoRoot/.mise/tasks/brew-bundle"
cp "$sourceRepoRoot/.mise/tasks/install-mise" "$repoRoot/.mise/tasks/install-mise"
cp "$sourceRepoRoot/lib/utils.sh" "$repoRoot/lib/utils.sh"

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
if [[ "${1:-}" == bootstrap ]]; then
    for configName in miserc.toml config.toml config.macos-x64.toml; do
        if [[ ! -L "$HOME/.config/mise/$configName" ]]; then
            printf 'mise bootstrap missing early config link: %s\n' "$configName" >&2
            exit 9
        fi
    done
fi
printf 'mise %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF

cat > "$temporaryDir/bin/mise-installer" <<'EOF'
#!/bin/sh
set -eu
mkdir -p "$(dirname "$MISE_INSTALL_PATH")"
cp "$BOOTSTRAP_TEST_MISE" "$MISE_INSTALL_PATH"
chmod 700 "$MISE_INSTALL_PATH"
EOF

cat > "$temporaryDir/bin/open" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'open %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
EOF

cat > "$temporaryDir/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output=''
url=''
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o)
            output="$2"
            shift 2
            ;;
        -*)
            shift
            ;;
        *)
            url="$1"
            shift
            ;;
    esac
done
[[ "$url" == https://mise.run ]]
[[ -n "$output" ]]
cp "$BOOTSTRAP_TEST_MISE_INSTALLER" "$output"
printf 'curl %s\n' "$url" >> "$BOOTSTRAP_TEST_LOG"
EOF

chmod 700 "$temporaryDir/bin/brew" "$temporaryDir/bin/curl" "$temporaryDir/bin/mise" "$temporaryDir/bin/mise-installer" "$temporaryDir/bin/open"
export BOOTSTRAP_TEST_LOG="$temporaryDir/actions.log"
export BOOTSTRAP_TEST_MISE="$temporaryDir/bin/mise"
export BOOTSTRAP_TEST_MISE_INSTALLER="$temporaryDir/bin/mise-installer"
testPath="$temporaryDir/bin:/usr/bin:/bin:/usr/sbin:/sbin"

runInstaller() {
    env \
        -u XDG_CONFIG_HOME \
        -u DOTFILES_ROLE \
        -u DOTFILES_DIR \
        -u DOTFILES_REPO \
        HOME="$1" \
        PATH="$testPath" \
        MISE_PROJECT_ROOT="$repoRoot" \
        DOTFILES_SKIP_1PASSWORD_PROMPT=1 \
        GIT_USER_NAME='Test User' \
        GIT_USER_EMAIL='test@example.com' \
        "$repoRoot/install.sh" "${@:2}"
}

grep -Fq 'Checkout location (default: ~/Source/dotfiles).' <("$repoRoot/install.sh" --help) || fail 'help does not show the Source checkout default'

if updateOutput="$(runInstaller "$temporaryDir/home" --update 2>&1)"; then
    fail 'retired --update option was accepted'
fi
grep -Fq 'run `mise run sync`' <<<"$updateOutput" || fail 'retired --update option lacked sync guidance'
[[ ! -s "$BOOTSTRAP_TEST_LOG" ]] || fail 'retired --update option ran external setup actions'

# A fresh work setup gets the same interactive 1Password preparation as personal.
promptRepo="$temporaryDir/prompt-repo"
promptHome="$temporaryDir/prompt-home"
promptLog="$temporaryDir/prompt-actions.log"
cp -R "$repoRoot" "$promptRepo"
promptOutput="$(
    env \
        -u XDG_CONFIG_HOME \
        -u DOTFILES_ROLE \
        -u DOTFILES_DIR \
        -u DOTFILES_REPO \
        HOME="$promptHome" \
        PATH="$testPath" \
        MISE_PROJECT_ROOT="$promptRepo" \
        BOOTSTRAP_TEST_LOG="$promptLog" \
        GIT_USER_NAME='Test User' \
        GIT_USER_EMAIL='test@example.com' \
        /usr/bin/expect -f - "$promptRepo/install.sh" <<'EOF'
set timeout 10
spawn -noecho [lindex $argv 0] work
expect {
    "Press Return when 1Password is ready." { send -- "\r" }
    timeout { puts stderr "Timed out waiting for the 1Password prompt"; exit 1 }
    eof { puts stderr "Installer exited before the 1Password prompt"; exit 1 }
}
expect {
    eof {}
    timeout { puts stderr "Timed out waiting for the installer to finish"; exit 1 }
}
set result [wait]
if {[lindex $result 2] != 0 || [lindex $result 4] eq "CHILDKILLED"} { exit 1 }
exit [lindex $result 3]
EOF
)"
grep -Fq 'Integrate with' <<<"$promptOutput" || fail 'work setup did not show the 1Password integration prompt'
grep -Fqx 'open -a 1Password' "$promptLog" || fail 'work setup did not open 1Password'

runInstaller "$temporaryDir/home" personal >/dev/null

localConfig="$repoRoot/mise.local.toml"
gitConfig="$temporaryDir/home/.config/git/config.local"
grep -Fqx 'DOTFILES_ROLE = "personal"' "$localConfig" || fail 'personal role was not written'
[[ "$(git config --file "$gitConfig" user.name)" == 'Test User' ]] || fail 'Git name was not written'
[[ "$(git config --file "$gitConfig" user.email)" == 'test@example.com' ]] || fail 'Git email was not written'
for configName in miserc.toml config.toml config.macos-x64.toml; do
    [[ "$(readlink "$temporaryDir/home/.config/mise/$configName")" == "$repoRoot/home/.config/mise/$configName" ]] ||
        fail "global mise config was not linked: $configName"
done
[[ -x "$temporaryDir/home/.local/bin/mise" ]] || fail 'official mise binary was not installed'
grep -Fqx 'curl https://mise.run' "$BOOTSTRAP_TEST_LOG" || fail 'official mise installer was not requested'
! grep -Eq '^brew install( |$)' "$BOOTSTRAP_TEST_LOG" || fail 'Homebrew formula installation was requested'
HOME="$temporaryDir/home" PATH="$testPath" "$repoRoot/.mise/tasks/install-mise" --update
grep -Fqx 'mise self-update --yes --no-plugins' "$BOOTSTRAP_TEST_LOG" || fail 'official mise self-update was not requested'
grep -Fqx "brew bundle install --file=$repoRoot/Brewfile --no-upgrade" "$BOOTSTRAP_TEST_LOG" || fail 'Brewfile was not converged'
[[ "$(grep -Fc 'brew bundle install ' "$BOOTSTRAP_TEST_LOG")" == 1 ]] || fail 'bootstrap converged the Brewfile more than once'
! grep -Fqx 'brew "fish"' "$repoRoot/Brewfile" || fail 'Fish remained Homebrew-managed'
! grep -Fqx 'brew "git"' "$repoRoot/Brewfile" || fail 'Git remained Homebrew-managed'
! grep -Fqx 'brew "mise"' "$repoRoot/Brewfile" || fail 'mise remained Homebrew-managed'
grep -Fqx 'fish = "aqua:fish-shell/fish-shell"' "$repoRoot/home/.config/mise/config.toml" || fail 'Fish mise backend was not declared'
grep -Fqx 'fish = "latest"' "$repoRoot/home/.config/mise/config.toml" || fail 'Fish mise version was not declared'
grep -Fqx 'git = "conda:git"' "$repoRoot/home/.config/mise/config.toml" || fail 'Git mise backend was not declared'
grep -Fqx 'git = "latest"' "$repoRoot/home/.config/mise/config.toml" || fail 'Git mise version was not declared'
grep -Fqx "mise trust -y $repoRoot/mise.toml" "$BOOTSTRAP_TEST_LOG" || fail 'repository mise config trust was not requested'
[[ "$(grep -Fc 'mise trust ' "$BOOTSTRAP_TEST_LOG")" == 1 ]] || fail 'bootstrap trusted more than the repository config'
grep -Fqx 'mise bootstrap --yes' "$BOOTSTRAP_TEST_LOG" || fail 'mise bootstrap was not requested'

# The same role is idempotent. A conflicting role must never rewrite the file.
runInstaller "$temporaryDir/home" personal >/dev/null
if runInstaller "$temporaryDir/home" work >/dev/null 2>&1; then
    fail 'conflicting role was accepted'
fi
grep -Fqx 'DOTFILES_ROLE = "personal"' "$localConfig" || fail 'conflicting role changed the local config'

# Replacing an unrelated global config requires the explicit migration flag.
unlink "$temporaryDir/home/.config/mise/config.toml"
printf '%s\n' '[tools]' > "$temporaryDir/home/.config/mise/config.toml"
if runInstaller "$temporaryDir/home" personal >/dev/null 2>&1; then
    fail 'existing global config was replaced without force'
fi
runInstaller "$temporaryDir/home" personal --force-dotfiles >/dev/null
[[ "$(readlink "$temporaryDir/home/.config/mise/config.toml")" == "$repoRoot/home/.config/mise/config.toml" ]] || fail 'forced global config replacement failed'
grep -Fqx 'mise bootstrap --yes --force-dotfiles' "$BOOTSTRAP_TEST_LOG" || fail 'force flag was not forwarded'

# A streamed installer creates the default ~/Source parent before cloning.
mkdir -p "$temporaryDir/clone-bin" "$temporaryDir/streamed"
ln -s "$temporaryDir/bin/brew" "$temporaryDir/clone-bin/brew"
ln -s "$temporaryDir/bin/curl" "$temporaryDir/clone-bin/curl"
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
    mkdir -p "$target/.git" "$target/home/.config/mise" "$target/.mise/tasks" "$target/lib"
    cp "$BOOTSTRAP_TEST_REPO/mise.toml" "$target/mise.toml"
    cp "$BOOTSTRAP_TEST_REPO"/home/.config/mise/{miserc,config,config.macos-x64}.toml "$target/home/.config/mise/"
    cp "$BOOTSTRAP_TEST_REPO/.mise/tasks/brew-bundle" "$target/.mise/tasks/brew-bundle"
    cp "$BOOTSTRAP_TEST_REPO/.mise/tasks/install-mise" "$target/.mise/tasks/install-mise"
    cp "$BOOTSTRAP_TEST_REPO/lib/utils.sh" "$target/lib/utils.sh"
    : > "$target/Brewfile"
    printf 'git %s\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
    exit 0
fi
exec /usr/bin/git "$@"
EOF

chmod 700 "$temporaryDir/clone-bin/git" "$temporaryDir/streamed/install.sh"
cloneHome="$temporaryDir/clone-home"
clonePath="$temporaryDir/clone-bin:/usr/bin:/bin:/usr/sbin:/sbin"
env \
    -u XDG_CONFIG_HOME \
    -u MISE_PROJECT_ROOT \
    -u DOTFILES_ROLE \
    -u DOTFILES_DIR \
    -u DOTFILES_REPO \
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
for configName in miserc.toml config.toml config.macos-x64.toml; do
    [[ "$(readlink "$cloneHome/.config/mise/$configName")" == "$defaultCheckout/home/.config/mise/$configName" ]] ||
        fail "streamed install did not link global mise config: $configName"
done
[[ -x "$cloneHome/.local/bin/mise" ]] || fail 'streamed install did not install the official mise binary'

printf '%s\n' 'Bootstrap contract tests passed.'
