if status is-interactive
    # Expand replacements visibly so scripts and copied commands keep their
    # original Unix behavior.
    abbr --add ls -- eza
    abbr --add ll -- eza -l
    abbr --add cat -- bat --paging=never
end
