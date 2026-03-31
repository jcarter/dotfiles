if status is-interactive
    # Sync _ef_last_mode with macOS appearance at startup.
    # Handles cases where appearance changed between sessions (e.g. overnight).
    # Runs before tide.fish (c < t alphabetically) so _ef_last_mode is correct
    # when tide.fish applies Tide colors.
    if command -q defaults
        set -l _want dark
        if not defaults read -g AppleInterfaceStyle >/dev/null 2>/dev/null
            set _want light
        end
        if test "$_want" != "$_ef_last_mode"
            set -U _ef_last_mode $_want
        end
    end

    # Apply Fish syntax theme matching current mode.
    if test "$_ef_last_mode" = light
        fish_config theme choose everforest-medium --color-theme=light
    else
        fish_config theme choose everforest-medium --color-theme=dark
    end

    # Auto-detect macOS appearance changes mid-session.
    # Uses fish_prompt event (fires before each prompt draw).
    # Counter rate-limits to one `defaults read` per 5 prompts — math
    # and test are builtins (zero forks for the counter path).
    if command -q defaults
        function _ef_check_macos_appearance --on-event fish_prompt
            set -q _ef_check_n; or set -g _ef_check_n 0
            set -g _ef_check_n (math "$_ef_check_n + 1")
            test "$_ef_check_n" -ge 5; or return
            set -g _ef_check_n 0

            set -l want dark
            if not defaults read -g AppleInterfaceStyle >/dev/null 2>/dev/null
                set want light
            end
            test "$want" != "$_ef_last_mode"; or return

            if test "$want" = light
                ef_light
            else
                ef_dark
            end
        end
    end
end
