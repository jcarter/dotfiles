#!/usr/bin/env bash

set -euo pipefail

repoRoot="$(cd "$(dirname "$0")/.." && pwd)"
temporaryDir="$(mktemp -d)"
trap 'rm -rf "$temporaryDir"' EXIT

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
cp "$repoRoot/templates/omp/config.yml" "$temporaryDir/source/templates/omp/config.yml"

cat > "$temporaryDir/bin/fnox" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == '--config' && "$3" == 'get' && "$4" == 'OMP_HINDSIGHT_API_URL' ]]
printf '%s' 'fake-hindsight-secret'
EOF
chmod 700 "$temporaryDir/bin/fnox"

DOTFILES_ROLE=personal \
  DOTFILES_REPO_ROOT="$temporaryDir/source" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
  FNOX_CONFIG_PATH="$temporaryDir/fnox.toml" \
  FNOX_BIN="$temporaryDir/bin/fnox" \
  "$repoRoot/.mise/tasks/omp-render-settings" > "$temporaryDir/personal.out"

assertContains '  backend: hindsight' "$temporaryDir/live/agent/config.yml"
assertContains '  apiUrl: "fake-hindsight-secret"' "$temporaryDir/live/agent/config.yml"
assertNotContains 'fake-hindsight-secret' "$temporaryDir/personal.out"
[[ "$(stat -f '%Lp' "$temporaryDir/live/agent/config.yml")" == '600' ]] || fail 'live config is not mode 0600'

# Simulate an OMP-authored non-secret setting, then ensure sync keeps only the
# renderer sentinels in the committed source.
sed -i '' 's/mode: prompt/mode: interactive/' "$temporaryDir/live/agent/config.yml"
DOTFILES_ROLE=personal \
  DOTFILES_REPO_ROOT="$temporaryDir/source" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
  FNOX_CONFIG_PATH="$temporaryDir/fnox.toml" \
  FNOX_BIN="$temporaryDir/bin/fnox" \
  "$repoRoot/.mise/tasks/omp-sync-settings" > "$temporaryDir/sync.out"

assertContains '  backend: __OMP_MEMORY_BACKEND__' "$temporaryDir/source/templates/omp/config.yml"
assertContains '  apiUrl: __FNOX_OMP_HINDSIGHT_API_URL__' "$temporaryDir/source/templates/omp/config.yml"
assertContains '  mode: interactive' "$temporaryDir/source/templates/omp/config.yml"
assertNotContains 'fake-hindsight-secret' "$temporaryDir/source/templates/omp/config.yml"
assertNotContains 'fake-hindsight-secret' "$temporaryDir/sync.out"

DOTFILES_ROLE=work \
  DOTFILES_REPO_ROOT="$temporaryDir/source" \
  OMP_CONFIG_PATH="$temporaryDir/live/agent/config.yml" \
  FNOX_BIN="$temporaryDir/bin/not-called" \
  "$repoRoot/.mise/tasks/omp-render-settings" > "$temporaryDir/work.out"

assertContains '  backend: off' "$temporaryDir/live/agent/config.yml"
assertContains '  apiUrl: ""' "$temporaryDir/live/agent/config.yml"
assertNotContains 'fake-hindsight-secret' "$temporaryDir/work.out"

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
assertNotContains 'fake-hindsight-secret' "$temporaryDir/source/templates/omp/config.yml"
assertNotContains 'fake-hindsight-secret' "$temporaryDir/work-sync.out"
printf '%s\n' 'OMP renderer and sync tests passed.'
