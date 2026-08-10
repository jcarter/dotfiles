if status is-login
    if test -x /opt/homebrew/bin/brew
        eval (/opt/homebrew/bin/brew shellenv fish)
    else if test -x /usr/local/bin/brew
        eval (/usr/local/bin/brew shellenv fish)
    end
end

if status is-interactive
    set -g fish_greeting

    mise activate fish | source
    set -gx HOMEBREW_NO_AUTOREMOVE 1
    set -gx ERL_AFLAGS "-kernel shell_history enabled"
end
