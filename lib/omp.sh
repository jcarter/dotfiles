#!/usr/bin/env bash

# Shared, OMP-specific rules for the renderer and sync task.

readonly ompBackendSentinel='__OMP_MEMORY_BACKEND__'
readonly ompHindsightSentinel='__FNOX_OMP_HINDSIGHT_API_URL__'

omp_role_backend() {
  case "${DOTFILES_ROLE:-}" in
    personal) printf '%s\n' hindsight ;;
    work) printf '%s\n' off ;;
    *)
      printf '%s\n' "DOTFILES_ROLE must be personal or work (set it in the repository's mise.local.toml)." >&2
      return 2
      ;;
  esac
}

omp_init_paths() {
  local scriptDir="$1"
  repoRoot="${DOTFILES_REPO_ROOT:-$(cd "$scriptDir/../.." && pwd)}"
  sourcePath="${OMP_TEMPLATE_PATH:-$repoRoot/templates/omp/config.yml}"
  liveConfigPath="${OMP_CONFIG_PATH:-$HOME/.omp/agent/config.yml}"
  fnoxConfigPath="${FNOX_CONFIG_PATH:-$HOME/.config/fnox/config.toml}"
  fnoxBin="${FNOX_BIN:-fnox}"
}

omp_hindsight_api_url() {
  local value
  value="$("$fnoxBin" --config "$fnoxConfigPath" get OMP_HINDSIGHT_API_URL)" || return
  if [[ -z "$value" ]]; then
    printf '%s\n' 'fnox returned an empty OMP_HINDSIGHT_API_URL.' >&2
    return 1
  fi
  printf '%s' "$value"
}

omp_yaml_double_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '"%s"' "$value"
}

omp_escape_glob_pattern() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\*/\\*}"
  value="${value//\?/\\?}"
  value="${value//\[/\\[}"
  printf '%s' "$value"
}

omp_atomic_write() {
  local content="$1" targetPath="$2" targetDir temporaryPath
  umask 077
  targetDir="$(dirname "$targetPath")"
  mkdir -p "$targetDir"
  temporaryPath="$(mktemp "$targetDir/.config.yml.XXXXXX")"
  trap 'rm -f "$temporaryPath"' EXIT
  printf '%s\n' "$content" > "$temporaryPath"
  chmod 600 "$temporaryPath"
  mv -f "$temporaryPath" "$targetPath"
  trap - EXIT
}
