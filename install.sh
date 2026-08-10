#!/usr/bin/env bash

# Zero-stage macOS installer. It can run from a checkout or directly from a
# public raw GitHub URL: curl .../install.sh | bash -s -- personal
set -euo pipefail
[[ "${DOTFILES_INSTALL_DEBUG:-}" == 1 ]] && set -x

readonly defaultRepoUrl='https://github.com/jcarter/dotfiles.git'
readonly defaultDotfilesDir="$HOME/Source/dotfiles"

role="${DOTFILES_ROLE:-}"
forceDotfiles=false
updateOnly=false
createdRoleConfig=false
repoRoot=''

usage() {
    cat <<'EOF'
Usage: install.sh <personal|work> [--force-dotfiles]
       install.sh --update

Options:
  --force-dotfiles  Replace existing regular files during a one-time migration.
  --update          Fast-forward an existing checkout and converge it.
  -h, --help        Show this help.

Environment:
  DOTFILES_DIR      Checkout location (default: ~/Source/dotfiles).
  DOTFILES_REPO     Clone URL (default: https://github.com/jcarter/dotfiles.git).
  DOTFILES_ROLE     Alternative to the personal/work positional argument.
  GIT_USER_NAME     Non-interactive Git identity name.
  GIT_USER_EMAIL    Non-interactive Git identity email.
EOF
}

parseArgs() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            personal|work)
                if [[ -n "$role" && "$role" != "$1" ]]; then
                    printf 'Conflicting machine roles: %s and %s\n' "$role" "$1" >&2
                    exit 2
                fi
                role="$1"
                ;;
            --force-dotfiles)
                forceDotfiles=true
                ;;
            --update)
                updateOnly=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                printf 'Unknown option: %s\n' "$1" >&2
                usage >&2
                exit 2
                ;;
        esac
        shift
    done
}

brewBin() {
    if command -v brew >/dev/null 2>&1; then
        command -v brew
    elif [[ -x /opt/homebrew/bin/brew ]]; then
        printf '%s\n' /opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew ]]; then
        printf '%s\n' /usr/local/bin/brew
    fi
}

installHomebrew() {
    local brew
    brew="$(brewBin || true)"
    if [[ -z "$brew" ]]; then
        printf '%s\n' 'Installing Homebrew (macOS may first install Command Line Tools)...'
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        brew="$(brewBin || true)"
    fi
    if [[ -z "$brew" ]]; then
        printf '%s\n' 'Homebrew was not found after installation. Complete its post-install instructions, then rerun.' >&2
        exit 1
    fi
    eval "$("$brew" shellenv)"
    "$brew" install git mise
}

resolveRepo() {
    local scriptPath scriptDir targetDir repoUrl
    scriptPath="${BASH_SOURCE[0]:-}"
    if [[ -n "$scriptPath" && -f "$scriptPath" ]]; then
        scriptDir="$(cd "$(dirname "$scriptPath")" && pwd)"
        if [[ -f "$scriptDir/mise.toml" ]]; then
            repoRoot="$scriptDir"
            return
        fi
    fi

    targetDir="${DOTFILES_DIR:-$defaultDotfilesDir}"
    repoUrl="${DOTFILES_REPO:-$defaultRepoUrl}"
    if [[ -e "$targetDir" && ! -d "$targetDir/.git" ]]; then
        printf 'Refusing to clone over non-repository path: %s\n' "$targetDir" >&2
        exit 1
    fi
    if [[ ! -d "$targetDir/.git" ]]; then
        printf 'Cloning dotfiles into %s...\n' "$targetDir"
        mkdir -p "$(dirname "$targetDir")"
        git clone --depth 1 "$repoUrl" "$targetDir"
    fi
    repoRoot="$targetDir"
}

updateRepo() {
    [[ "$updateOnly" == true ]] || return 0
    if [[ -n "$(git -C "$repoRoot" status --porcelain --untracked-files=normal)" ]]; then
        printf '%s\n' 'Refusing to update a dirty dotfiles checkout.' >&2
        exit 1
    fi
    git -C "$repoRoot" pull --ff-only
}

readConfiguredRole() {
    local config="$1"
    sed -nE 's/^[[:space:]]*DOTFILES_ROLE[[:space:]]*=[[:space:]]*["'\'' ]*([^"'\'' #]+).*/\1/p' "$config" | head -1
}

ensureRoleConfig() {
    local configDir config configuredRole
    configDir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
    config="$configDir/config.local.toml"

    if [[ -e "$config" ]]; then
        configuredRole="$(readConfiguredRole "$config")"
        if [[ "$configuredRole" != personal && "$configuredRole" != work ]]; then
            printf 'Set DOTFILES_ROLE to personal or work in %s.\n' "$config" >&2
            exit 1
        fi
        if [[ -n "$role" && "$role" != "$configuredRole" ]]; then
            printf 'Requested role %s conflicts with %s in %s.\n' "$role" "$configuredRole" "$config" >&2
            exit 1
        fi
        role="$configuredRole"
        return
    fi

    if [[ "$role" != personal && "$role" != work ]]; then
        printf '%s\n' 'A fresh install requires the personal or work role.' >&2
        usage >&2
        exit 2
    fi

    mkdir -p "$configDir"
    (
        umask 077
        printf '%s\n' \
            '# Machine-local, non-secret settings. This file is not tracked.' \
            '[env]' \
            "DOTFILES_ROLE = \"$role\"" \
            '# Add other host-specific environment variables below.' \
            > "$config"
    )
    createdRoleConfig=true
    printf 'Created %s for the %s role.\n' "$config" "$role"
}

promptValue() {
    local prompt="$1" defaultValue="$2" result
    if [[ -t 1 && -r /dev/tty ]]; then
        if [[ -n "$defaultValue" ]]; then
            printf '%s [%s]: ' "$prompt" "$defaultValue" >/dev/tty
        else
            printf '%s: ' "$prompt" >/dev/tty
        fi
        IFS= read -r result </dev/tty || result=''
        printf '%s\n' "${result:-$defaultValue}"
    else
        printf '%s\n' "$defaultValue"
    fi
}

ensureGitIdentity() {
    local configDir config name email
    configDir="${XDG_CONFIG_HOME:-$HOME/.config}/git"
    config="$configDir/config.local"
    if git config --file "$config" user.name >/dev/null 2>&1 &&
       git config --file "$config" user.email >/dev/null 2>&1; then
        return
    fi

    name="${GIT_USER_NAME:-$(git config --global user.name 2>/dev/null || true)}"
    email="${GIT_USER_EMAIL:-$(git config --global user.email 2>/dev/null || true)}"
    if [[ -z "${GIT_USER_NAME:-}" ]]; then
        name="$(promptValue 'Git user name' "$name")"
    fi
    if [[ -z "${GIT_USER_EMAIL:-}" ]]; then
        email="$(promptValue 'Git email' "$email")"
    fi
    if [[ -z "$name" || -z "$email" ]]; then
        printf '%s\n' 'Git identity is required. Set GIT_USER_NAME and GIT_USER_EMAIL, then rerun.' >&2
        exit 1
    fi

    mkdir -p "$configDir"
    git config --file "$config" user.name "$name"
    git config --file "$config" user.email "$email"
    chmod 600 "$config"
    printf 'Created machine-local Git identity at %s.\n' "$config"
}

linkGlobalMiseConfig() {
    local configDir target linkTarget
    configDir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
    target="$configDir/config.toml"
    linkTarget="$repoRoot/home/.config/mise/config.toml"
    mkdir -p "$configDir"

    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -L "$target" && "$(readlink "$target")" == "$linkTarget" ]]; then
            return
        fi
        if [[ "$forceDotfiles" != true ]]; then
            printf 'Refusing to replace existing %s without --force-dotfiles.\n' "$target" >&2
            exit 1
        fi
    fi
    ln -sfn "$linkTarget" "$target"
}

installDeclaredPackages() {
    brew bundle install --file="$repoRoot/Brewfile" --no-upgrade
}

prepareOnePassword() {
    [[ "$role" == personal ]] || return 0
    [[ "$createdRoleConfig" == true ]] || return 0
    [[ "${DOTFILES_SKIP_1PASSWORD_PROMPT:-}" == 1 ]] && return 0
    if [[ -t 1 && -r /dev/tty ]]; then
        open -a 1Password >/dev/null 2>&1 || true
        cat >/dev/tty <<'EOF'

Sign in to 1Password and enable Settings > Developer > Integrate with
1Password CLI. The personal OMP configuration will request Touch ID.
Press Return when 1Password is ready.
EOF
        IFS= read -r _ </dev/tty
    fi
}

runBootstrap() {
    local -a args=(bootstrap --yes)
    [[ "$forceDotfiles" == true ]] && args+=(--force-dotfiles)
    cd "$repoRoot"
    mise trust -y -a
    mise "${args[@]}"
}

main() {
    parseArgs "$@"
    if [[ "$(uname -s)" != Darwin ]]; then
        printf '%s\n' 'This installer currently supports macOS only.' >&2
        exit 1
    fi
    installHomebrew
    resolveRepo
    updateRepo
    ensureRoleConfig
    ensureGitIdentity
    linkGlobalMiseConfig
    installDeclaredPackages
    prepareOnePassword
    runBootstrap
}

main "$@"
