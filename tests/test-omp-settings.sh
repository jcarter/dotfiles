#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

test_repo="$temporary_dir/repo"
test_home="$temporary_dir/home"
live_config="$test_home/.omp/agent/config.yml"
saved_config="$temporary_dir/saved.yml"
fnox_log="$temporary_dir/fnox.log"
fnox_value="$temporary_dir/fnox.value"
protected_value='https://hindsight.example/api?scope=prod*&set=[one]'

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

expect_failure() {
    if "$@" >/dev/null 2>&1; then
        fail "expected failure: $*"
    fi
}

assert_line() {
    grep -Fqx -- "$1" "$live_config" || fail "live config lacks line: $1"
}

assert_no_secret() {
    ! grep -Fq -- "$protected_value" "$1" || fail "protected value leaked into ${1##*/}"
}

# Run real mise against the fixture with nothing inherited from this machine.
run_mise() {
    env -i \
        HOME="$test_home" \
        PATH="$temporary_dir/bin:$PATH" \
        MISE_CACHE_DIR="$temporary_dir/cache" \
        MISE_CONFIG_DIR="$temporary_dir/config" \
        MISE_DATA_DIR="$temporary_dir/data" \
        MISE_STATE_DIR="$temporary_dir/state" \
        MISE_TRUSTED_CONFIG_PATHS="$test_repo" \
        FNOX_LOG="$fnox_log" \
        FNOX_VALUE="$fnox_value" \
        mise -C "$test_repo" "$@"
}

set_role() {
    printf '%s\n' '[env]' "DOTFILES_ROLE = \"$1\"" > "$test_repo/mise.local.toml"
}

apply_config() {
    run_mise bootstrap dotfiles apply --yes "$live_config"
}

config_drifted() {
    ! run_mise dot status --missing "$live_config" >/dev/null 2>&1
}

mkdir -p "$test_repo/.mise" "$temporary_dir/bin"
cp "$repo_root/mise.toml" "$test_repo/"
cp -R "$repo_root/templates" "$test_repo/"
cp -R "$repo_root/.mise/tasks" "$test_repo/.mise/"

# The fnox stub records each read; a missing value file is a failed read.
cat > "$temporary_dir/bin/fnox" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$FNOX_LOG"
[[ "$1" == --config && "$3" == get && "$4" == OMP_HINDSIGHT_API_URL ]]
cat "$FNOX_VALUE"
EOF
chmod 700 "$temporary_dir/bin/fnox"

# Personal: the dotfiles step creates a private config without reading the secret.
set_role personal
apply_config > "$temporary_dir/personal.out" 2>&1
assert_line '  backend: hindsight'
[[ "$(stat -f '%Lp' "$live_config")" == 600 ]] || fail 'live config is not mode 0600'
! config_drifted || fail 'apply left declared keys drifted'
[[ ! -e "$fnox_log" ]] || fail 'dotfiles step read the secret'

# OMP keeps its own keys, including this Mac's models; declared-key drift is corrected.
printf '%s\n' '# written by omp' 'setupVersion: 2' 'modelRoles:' '  default: machine/model' >> "$live_config"
sed -i '' 's/backend: hindsight/backend: off/' "$live_config"
config_drifted || fail 'declared-key drift was not detected'
apply_config >> "$temporary_dir/personal.out" 2>&1
assert_line '  backend: hindsight'
assert_line '# written by omp'
assert_line 'setupVersion: 2'
assert_line '  default: machine/model'
! config_drifted || fail 'apply did not correct declared-key drift'
cp "$live_config" "$saved_config"
apply_config >> "$temporary_dir/personal.out" 2>&1
cmp -s "$saved_config" "$live_config" || fail 'reapply changed a converged config'

# The post-tools task sets the URL without printing it and refreshes a stale one.
printf '%s' "$protected_value" > "$fnox_value"
run_mise run omp-hindsight >> "$temporary_dir/personal.out" 2>&1
assert_line "  apiUrl: \"$protected_value\""
sed -i '' 's|apiUrl: .*|apiUrl: "https://stale.example"|' "$live_config"
! config_drifted || fail 'status reported the secret-backed key'
run_mise run omp-hindsight >> "$temporary_dir/personal.out" 2>&1
assert_line "  apiUrl: \"$protected_value\""
assert_line 'setupVersion: 2'
assert_no_secret "$temporary_dir/personal.out"
[[ "$(wc -l < "$fnox_log")" -eq 2 ]] || fail 'the secret was read outside the task'

# An empty or failed secret read leaves the config untouched.
cp "$live_config" "$saved_config"
: > "$fnox_value"
expect_failure run_mise run omp-hindsight
rm "$fnox_value"
expect_failure run_mise run omp-hindsight
cmp -s "$saved_config" "$live_config" || fail 'failed secret read changed the live config'

# Work: its own keys on a fresh home, and the secret is never read or written.
rm -rf "$test_home" "$fnox_log"
printf '%s' "$protected_value" > "$fnox_value"
set_role work
apply_config > "$temporary_dir/work.out" 2>&1
run_mise run omp-hindsight >> "$temporary_dir/work.out" 2>&1
assert_line '  backend: off'
! config_drifted || fail 'work apply left declared keys drifted'
[[ ! -e "$fnox_log" ]] || fail 'work role read the secret'
! grep -Fq 'apiUrl' "$live_config" || fail 'work config has a Hindsight URL'
assert_no_secret "$live_config"
assert_no_secret "$temporary_dir/work.out"

# An unknown or missing role fails loudly and leaves the config untouched.
cp "$live_config" "$saved_config"
set_role other
if role_error="$(apply_config 2>&1)"; then
    fail 'unknown role was accepted'
fi
grep -Fq 'DOTFILES_ROLE' <<<"$role_error" || fail 'unknown role error does not name DOTFILES_ROLE'
rm "$test_repo/mise.local.toml"
expect_failure apply_config
cmp -s "$saved_config" "$live_config" || fail 'invalid role changed the live config'

printf '%s\n' 'OMP merge tests passed.'
