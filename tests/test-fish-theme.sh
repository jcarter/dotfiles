#!/usr/bin/env bash

set -euo pipefail

repoRoot="$(cd "$(dirname "$0")/.." && pwd)"
temporaryDir="$(mktemp -d)"
trap 'rm -rf "$temporaryDir"' EXIT

output="$temporaryDir/output"
fishBin="$(command -v fish)"
(
  cd "$temporaryDir"
  env -i \
    PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    TERM=xterm-256color \
    HOME="$temporaryDir/home" \
    XDG_CONFIG_HOME="$temporaryDir/config" \
    XDG_DATA_HOME="$temporaryDir/data" \
    XDG_STATE_HOME="$temporaryDir/state" \
    "$fishBin" -i -c '
      function fish_config
          set -ga _test_calls config:$argv[-1]
      end
      function _tide_sub_reload
          set -ga _test_calls reload
          set -g _tide_repaint stale
      end
      function commandline
          if set -q _tide_repaint
              set -ga _test_calls stale-cache
          end
          set -ga _test_calls repaint
      end
      set -p fish_function_path "$argv[1]/home/.config/fish/functions"
      source "$argv[1]/home/.config/fish/conf.d/tide.fish"
      set -g _seg sentinel
      set -g _red sentinel
      for mode in light dark light
          set -g _test_calls
          if test "$mode" = light
              ef_light
          else
              ef_dark
          end
          printf "%s:%s:%s\n" $_ef_last_mode $tide_character_color (string join , $_test_calls)
      end
      set --show tide_character_color
      if set -q _green
          printf "temporary-global=yes\n"
      else
          printf "temporary-global=no\n"
      end
      printf "sentinels=%s,%s\n" $_seg $_red
    ' -- "$repoRoot"
) > "$output"

[[ "$(grep -Fxc 'light:8da101:config:--color-theme=light,reload,repaint' "$output")" == 2 ]]
grep -Fqx 'dark:a7c080:config:--color-theme=dark,reload,repaint' "$output"
grep -Fq 'set in universal scope' "$output"
grep -Fqx 'temporary-global=no' "$output"
grep -Fqx 'sentinels=sentinel,sentinel' "$output"

printf 'Fish theme helper behavior and universal scope verified\n'
