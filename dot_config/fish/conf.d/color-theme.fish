if status is-interactive
    # ── Startup: apply Fish syntax theme from last-known mode ──────────────────
    # _ef_last_mode (universal) persists across sessions. Tide colors are
    # applied separately by tide.fish (which runs after this file, t > c).
    if test "$_ef_last_mode" = light
        fish_config theme choose everforest-medium --color-theme=light
    else
        fish_config theme choose everforest-medium --color-theme=dark
    end

    # ── Primary: instant detection via terminal background query ───────────────
    # Fish 4.3+ sets fish_terminal_color_theme when the terminal reports a
    # background-color change via OSC 11. Ghostty sends this automatically
    # when its dark:/light: theme pair switches on macOS appearance toggle.
    # Zero forks, fires at exactly the right moment.
    function _ef_on_color_theme_change --on-variable fish_terminal_color_theme
        switch $fish_terminal_color_theme
            case light
                test "$_ef_last_mode" = light; and return
                ef_light
            case dark
                test "$_ef_last_mode" = dark; and return
                ef_dark
        end
    end

    # ── Fallback: focus-in check for terminals without OSC 11 ──────────────────
    # Fires when the user returns to the terminal after toggling appearance.
    # Self-erases once fish_terminal_color_theme becomes available, since
    # the primary handler takes over at that point.
    if command -q defaults
        function _ef_check_on_focus --on-event fish_focus_in
            if set -q fish_terminal_color_theme[1]
                functions -e _ef_check_on_focus
                return
            end
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
