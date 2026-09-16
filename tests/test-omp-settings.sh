#!/usr/bin/env bash

set -euo pipefail

repoRoot="$(cd "$(dirname "$0")/.." && pwd)"
temporaryDir="$(mktemp -d)"
trap 'rm -rf "$temporaryDir"' EXIT

# Keep inherited machine settings from redirecting fixture operations outside
# this temporary environment.
unset HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME OMP_TEMPLATE_PATH \
  OMP_CONFIG_PATH FNOX_CONFIG_PATH FNOX_BIN DOTFILES_REPO_ROOT DOTFILES_ROLE

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assertContains() {
  local needle="$1"
  local file="$2"
  grep -Fqx "$needle" "$file" >/dev/null || fail "missing $needle"
}

assertNotContains() {
  local needle="$1"
  local file="$2"
  if grep -Fq "$needle" "$file"; then
    fail "unexpected protected value"
  fi
}

mkdir -p "$temporaryDir/source/templates/omp" "$temporaryDir/live/agent" "$temporaryDir/bin"
export HOME="$temporaryDir/home"
export XDG_CONFIG_HOME="$temporaryDir/home/.config"
export XDG_DATA_HOME="$temporaryDir/home/.local/share"
export XDG_STATE_HOME="$temporaryDir/home/.local/state"
cp "$repoRoot/templates/omp/config.yml" "$temporaryDir/source/templates/omp/config.yml"
protectedValue='https://hindsight.example/api?scope=prod*&set=[one]'

cat > "$temporaryDir/bin/fnox" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == '--config' && "$3" == 'get' && "$4" == 'OMP_HINDSIGHT_API_URL' ]]
printf '%s' 'https://hindsight.example/api?scope=prod*&set=[one]'
EOF
chmod 700 "$temporaryDir/bin/fnox"
cp "$temporaryDir/bin/fnox" "$temporaryDir/bin/fnox with spaces"
chmod 700 "$temporaryDir/bin/fnox with spaces"

DOTFILES_ROLE=personal \
  DOTFILES_REPO_ROOT="$temporaryDir/source" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
  FNOX_CONFIG_PATH="$temporaryDir/fnox.toml" \
  FNOX_BIN="$temporaryDir/bin/fnox with spaces" \
  "$repoRoot/.mise/tasks/omp-render-settings" > "$temporaryDir/personal.out"

assertContains '  backend: hindsight' "$temporaryDir/live/agent/config.yml"
assertContains "  apiUrl: \"$protectedValue\"" "$temporaryDir/live/agent/config.yml"
assertNotContains "$protectedValue" "$temporaryDir/personal.out"
[[ "$(stat -f '%Lp' "$temporaryDir/live/agent/config.yml")" == '600' ]] || fail 'live config is not mode 0600'

# Simulate an OMP-authored non-secret setting, then ensure sync keeps only the
# renderer sentinels in the committed source.
sed -i '' 's/mode: prompt/mode: interactive/' "$temporaryDir/live/agent/config.yml"
DOTFILES_ROLE=personal \
  DOTFILES_REPO_ROOT="$temporaryDir/source" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
  FNOX_CONFIG_PATH="$temporaryDir/fnox.toml" \
  FNOX_BIN="$temporaryDir/bin/fnox with spaces" \
  "$repoRoot/.mise/tasks/omp-sync-settings" > "$temporaryDir/sync.out"

assertContains '  backend: __OMP_MEMORY_BACKEND__' "$temporaryDir/source/templates/omp/config.yml"
assertContains '  apiUrl: __FNOX_OMP_HINDSIGHT_API_URL__' "$temporaryDir/source/templates/omp/config.yml"
assertContains '  mode: interactive' "$temporaryDir/source/templates/omp/config.yml"
assertContains '  bankId: Code' "$temporaryDir/source/templates/omp/config.yml"
assertNotContains "$protectedValue" "$temporaryDir/source/templates/omp/config.yml"
assertNotContains "$protectedValue" "$temporaryDir/sync.out"

DOTFILES_ROLE=work \
  DOTFILES_REPO_ROOT="$temporaryDir/source" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
  FNOX_BIN="$temporaryDir/bin/not-called" \
  "$repoRoot/.mise/tasks/omp-render-settings" > "$temporaryDir/work.out"

assertContains '  backend: off' "$temporaryDir/live/agent/config.yml"
assertContains '  apiUrl: ""' "$temporaryDir/live/agent/config.yml"
assertNotContains "$protectedValue" "$temporaryDir/work.out"

# Installed commands are symlinks. They must still locate the repository when
# called directly outside a mise task.
ln -s "$repoRoot/.mise/tasks/omp-render-settings" "$temporaryDir/bin/omp-render-settings"
DOTFILES_ROLE=work \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/from-symlink.yml" \
  FNOX_BIN="$temporaryDir/bin/not-called" \
  "$temporaryDir/bin/omp-render-settings" > "$temporaryDir/symlink.out"
assertContains '  backend: off' "$temporaryDir/live/agent/from-symlink.yml"
assertContains '  apiUrl: ""' "$temporaryDir/live/agent/from-symlink.yml"

DOTFILES_ROLE=work \
  DOTFILES_REPO_ROOT="$temporaryDir/source" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
  FNOX_BIN="$temporaryDir/bin/not-called" \
  "$repoRoot/.mise/tasks/omp-sync-settings" > "$temporaryDir/work-sync.out"

assertContains '  backend: __OMP_MEMORY_BACKEND__' "$temporaryDir/source/templates/omp/config.yml"
assertContains '  apiUrl: __FNOX_OMP_HINDSIGHT_API_URL__' "$temporaryDir/source/templates/omp/config.yml"
assertNotContains "$protectedValue" "$temporaryDir/source/templates/omp/config.yml"
assertNotContains "$protectedValue" "$temporaryDir/work-sync.out"

expectFailure() {
  if "$@" >/dev/null 2>&1; then
    fail "expected command to fail: $1"
  fi
}

# Invalid roles, incomplete templates, fnox failures/empty values, and role
# mismatches must leave their existing destination untouched.
cp "$temporaryDir/live/agent/config.yml" "$temporaryDir/before-failure-live.yml"
expectFailure env DOTFILES_ROLE=other OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
  FNOX_BIN="$temporaryDir/bin/not-called" "$repoRoot/.mise/tasks/omp-render-settings"
cmp -s "$temporaryDir/before-failure-live.yml" "$temporaryDir/live/agent/config.yml" || fail 'invalid role changed live config'

cp "$temporaryDir/source/templates/omp/config.yml" "$temporaryDir/source/missing-sentinel.yml"
sed -i '' 's/__OMP_MEMORY_BACKEND__/removed/' "$temporaryDir/source/missing-sentinel.yml"
cp "$temporaryDir/live/agent/config.yml" "$temporaryDir/before-missing-sentinel-live.yml"
expectFailure env DOTFILES_ROLE=work OMP_TEMPLATE_PATH="$temporaryDir/source/missing-sentinel.yml" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" FNOX_BIN="$temporaryDir/bin/not-called" \
  "$repoRoot/.mise/tasks/omp-render-settings"
cmp -s "$temporaryDir/before-missing-sentinel-live.yml" "$temporaryDir/live/agent/config.yml" || fail 'missing sentinel changed live config'

cat > "$temporaryDir/bin/fnox-failed" <<'EOF'
#!/usr/bin/env bash
exit 7
EOF
cat > "$temporaryDir/bin/fnox-empty" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 700 "$temporaryDir/bin/fnox-failed" "$temporaryDir/bin/fnox-empty"
for fnoxFailure in fnox-failed fnox-empty; do
  cp "$temporaryDir/live/agent/config.yml" "$temporaryDir/before-$fnoxFailure-live.yml"
  expectFailure env DOTFILES_ROLE=personal OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
    FNOX_BIN="$temporaryDir/bin/$fnoxFailure" "$repoRoot/.mise/tasks/omp-render-settings"
  cmp -s "$temporaryDir/before-$fnoxFailure-live.yml" "$temporaryDir/live/agent/config.yml" || fail "$fnoxFailure changed live config"
done

sed -i '' 's/backend: off/backend: hindsight/' "$temporaryDir/live/agent/config.yml"
cp "$temporaryDir/source/templates/omp/config.yml" "$temporaryDir/before-role-mismatch-source.yml"
expectFailure env DOTFILES_ROLE=work DOTFILES_REPO_ROOT="$temporaryDir/source" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" FNOX_BIN="$temporaryDir/bin/not-called" \
  "$repoRoot/.mise/tasks/omp-sync-settings"
cmp -s "$temporaryDir/before-role-mismatch-source.yml" "$temporaryDir/source/templates/omp/config.yml" || fail 'role mismatch changed source template'
printf '%s\n' 'OMP renderer and sync tests passed.'
