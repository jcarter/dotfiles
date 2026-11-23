# Named zz-* on purpose: conf.d loads alphabetically, before config.fish activates
# mise. This must sort after color-theme.fish, because fish_config calls `cat`
# while loading themes and `alias cat 'bat ...'` would fail with bat not on PATH yet.
if status is-interactive
    # File system
    alias ls 'eza -lh --group-directories-first --icons=auto'
    alias ll 'ls'
    alias lsa 'ls -a'
    alias lt 'eza --tree --level=2 --long --icons --git'
    alias lta 'lt -a'

    function ff
        if test "$TERM" = xterm-kitty
            fzf --preview '
                switch (file --mime-type -b {})
                    case "image/*"
                        kitty icat --clear --transfer-mode=memory --stdin=no --place="$FZF_PREVIEW_COLUMNS"x"$FZF_PREVIEW_LINES"@0x0 {}
                    case "*"
                        bat --style=numbers --color=always {}
                end
            ' $argv
        else
            fzf --preview 'bat --style=numbers --color=always {}' $argv
        end
    end

    # Directories
    alias .. 'cd ..'
    alias ... 'cd ../..'
    alias .... 'cd ../../..'

    alias cat 'bat --paging=never'
end
