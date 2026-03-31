function ef_dark --description 'Switch to Everforest dark medium theme'
    set -U _ef_last_mode dark
    fish_config theme choose everforest-medium --color-theme=dark
    _tide_ef_dark
    # Refresh Tide's cached escape sequences so the background render
    # process inherits the updated separator and branch color values.
    _tide_cache_variables
    # Clear the repaint flag so the next fish_prompt spawns a fresh
    # background job instead of displaying the stale cached result.
    set -e _tide_repaint
end
