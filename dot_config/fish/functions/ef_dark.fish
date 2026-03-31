function ef_dark --description 'Switch to Everforest dark medium theme'
    set -U _ef_last_mode dark
    fish_config theme choose everforest-medium --color-theme=dark
    _tide_ef_dark
    _tide_sub_reload  # re-sources fish_prompt.fish → rebakes _tide_pwd escape seqs with new universals
    set -e _tide_repaint
    # Trigger a second render cycle so the fresh background job (spawned
    # because _tide_repaint was cleared) runs immediately with the new
    # universals. No-op if called during command execution; effective when
    # called from the --on-variable event handler while at the prompt.
    commandline -f repaint 2>/dev/null
end
