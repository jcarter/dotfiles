if status is-login
    if test -x /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv fish)
    else if test -x /usr/local/bin/brew
        eval (/usr/local/bin/brew shellenv fish)
    end
end

fish_add_path --path "$HOME/.local/bin"

if status is-interactive
    set -g fish_greeting

    mise activate fish | source

    # Use Kitty's active ANSI palette so file colors follow Everforest when
    # macOS switches between light and dark appearance.
    if command -q vivid
        set -gx LS_COLORS (vivid generate ansi)
    end

    set -gx HOMEBREW_NO_AUTOREMOVE 1
    set -gx ERL_AFLAGS "-kernel shell_history enabled"
end
