if status is-interactive
    # Clear any stale global tide_ variables left by previous conf.d versions.
    # No-op on fresh shells; repairs old sessions without reopening.
    for _tide_var in (set --global --names | string match -r '^tide_')
        set --erase --global $_tide_var
    end

    # ── Layout & icons (shared) ────────────────────────────────────────────────
    set -U tide_character_icon ▶
    set -U tide_left_prompt_items pwd git
    set -U tide_right_prompt_items status cmd_duration context jobs
    set -U tide_status_icon ✓
    set -U tide_status_icon_failure ✕
    set -U tide_jobs_icon ⋯
    set -U tide_git_truncation_length 50

    # ── Everforest Dark Medium ─────────────────────────────────────────────────
    # All palette values from sainnhe/everforest autoload/everforest.vim
    function _tide_ef_dark
        set -l _seg  3d484d   # bg2       — segment background
        set -l _gitu 4d4c43   # bg_yellow — unstable git (dirty/staged/untracked)
        set -l _gitr 514045   # bg_red    — urgent git (conflicts/operations)

        set -U tide_prompt_color_frame_and_connection 475258  # bg3
        set -U tide_prompt_color_separator_same_color 9da9a0  # grey2

        set -U tide_character_color         a7c080  # green
        set -U tide_character_color_failure e67e80  # red

        set -U tide_pwd_bg_color             $_seg
        set -U tide_pwd_color_anchors        7fbbb3  # blue  — project roots
        set -U tide_pwd_color_dirs           83c092  # aqua  — normal dirs
        set -U tide_pwd_color_truncated_dirs 859289  # grey1 — truncated

        set -U tide_git_bg_color          $_seg
        set -U tide_git_bg_color_unstable $_gitu
        set -U tide_git_bg_color_urgent   $_gitr
        set -U tide_git_color_branch      a7c080  # green
        set -U tide_git_color_dirty       dbbc7f  # yellow
        set -U tide_git_color_staged      dbbc7f  # yellow
        set -U tide_git_color_stash       a7c080  # green
        set -U tide_git_color_untracked   7fbbb3  # blue
        set -U tide_git_color_upstream    a7c080  # green
        set -U tide_git_color_conflicted  e67e80  # red
        set -U tide_git_color_operation   e67e80  # red

        set -U tide_status_bg_color         $_seg
        set -U tide_status_bg_color_failure $_seg
        set -U tide_status_color            a7c080  # green
        set -U tide_status_color_failure    e67e80  # red

        set -U tide_cmd_duration_bg_color $_seg
        set -U tide_cmd_duration_color    859289  # grey1

        set -U tide_context_bg_color        $_seg
        set -U tide_context_color_default   d3c6aa  # fg
        set -U tide_context_color_root      e67e80  # red
        set -U tide_context_color_ssh       dbbc7f  # yellow

        set -U tide_jobs_bg_color $_seg
        set -U tide_jobs_color    83c092  # aqua

        set -U tide_vi_mode_bg_color_default $_seg
        set -U tide_vi_mode_bg_color_insert  $_seg
        set -U tide_vi_mode_bg_color_replace $_seg
        set -U tide_vi_mode_bg_color_visual  $_seg
        set -U tide_vi_mode_color_default    9da9a0  # grey2
        set -U tide_vi_mode_color_insert     7fbbb3  # blue
        set -U tide_vi_mode_color_replace    a7c080  # green
        set -U tide_vi_mode_color_visual     e69875  # orange

        set -U tide_direnv_bg_color          $_seg
        set -U tide_direnv_bg_color_denied   $_seg
        set -U tide_direnv_color             dbbc7f  # yellow
        set -U tide_direnv_color_denied      e67e80  # red

        # Runtimes
        set -U tide_node_bg_color    $_seg ; set -U tide_node_color    a7c080  # green
        set -U tide_python_bg_color  $_seg ; set -U tide_python_color  7fbbb3  # blue
        set -U tide_rustc_bg_color   $_seg ; set -U tide_rustc_color   e69875  # orange
        set -U tide_go_bg_color      $_seg ; set -U tide_go_color      83c092  # aqua
        set -U tide_java_bg_color    $_seg ; set -U tide_java_color    e69875  # orange
        set -U tide_ruby_bg_color    $_seg ; set -U tide_ruby_color    e67e80  # red
        set -U tide_php_bg_color     $_seg ; set -U tide_php_color     7fbbb3  # blue
        set -U tide_bun_bg_color     $_seg ; set -U tide_bun_color     d3c6aa  # fg
        set -U tide_crystal_bg_color $_seg ; set -U tide_crystal_color d3c6aa  # fg
        set -U tide_elixir_bg_color  $_seg ; set -U tide_elixir_color  d699b6  # purple
        set -U tide_zig_bg_color     $_seg ; set -U tide_zig_color     dbbc7f  # yellow

        # Infra
        set -U tide_aws_bg_color       $_seg ; set -U tide_aws_color       dbbc7f  # yellow
        set -U tide_gcloud_bg_color    $_seg ; set -U tide_gcloud_color    7fbbb3  # blue
        set -U tide_kubectl_bg_color   $_seg ; set -U tide_kubectl_color   7fbbb3  # blue
        set -U tide_docker_bg_color    $_seg ; set -U tide_docker_color    7fbbb3  # blue
        set -U tide_terraform_bg_color $_seg ; set -U tide_terraform_color d699b6  # purple
        set -U tide_pulumi_bg_color    $_seg ; set -U tide_pulumi_color    d699b6  # purple
        set -U tide_nix_shell_bg_color $_seg ; set -U tide_nix_shell_color 7fbbb3  # blue

        # Misc
        set -U tide_distrobox_bg_color    $_seg ; set -U tide_distrobox_color    d699b6  # purple
        set -U tide_toolbox_bg_color      $_seg ; set -U tide_toolbox_color      d699b6  # purple
        set -U tide_os_bg_color           $_seg ; set -U tide_os_color           d3c6aa  # fg
        set -U tide_shlvl_bg_color        $_seg ; set -U tide_shlvl_color        dbbc7f  # yellow
        set -U tide_time_bg_color         $_seg ; set -U tide_time_color         859289  # grey1
        set -U tide_private_mode_bg_color $_seg ; set -U tide_private_mode_color d3c6aa  # fg
    end

    # ── Everforest Light Medium ────────────────────────────────────────────────
    function _tide_ef_light
        set -l _seg  e6e2cc   # bg3       — segment background
        set -l _gitu faedcd   # bg_yellow — unstable git
        set -l _gitr fde3da   # bg_red    — urgent git

        set -U tide_prompt_color_frame_and_connection e0dcc7  # bg4
        set -U tide_prompt_color_separator_same_color 939f91  # grey1

        set -U tide_character_color         8da101  # green
        set -U tide_character_color_failure f85552  # red

        set -U tide_pwd_bg_color             $_seg
        set -U tide_pwd_color_anchors        3a94c5  # blue
        set -U tide_pwd_color_dirs           35a77c  # aqua
        set -U tide_pwd_color_truncated_dirs 939f91  # grey1

        set -U tide_git_bg_color          $_seg
        set -U tide_git_bg_color_unstable $_gitu
        set -U tide_git_bg_color_urgent   $_gitr
        set -U tide_git_color_branch      8da101  # green
        set -U tide_git_color_dirty       dfa000  # yellow
        set -U tide_git_color_staged      dfa000  # yellow
        set -U tide_git_color_stash       8da101  # green
        set -U tide_git_color_untracked   3a94c5  # blue
        set -U tide_git_color_upstream    8da101  # green
        set -U tide_git_color_conflicted  f85552  # red
        set -U tide_git_color_operation   f85552  # red

        set -U tide_status_bg_color         $_seg
        set -U tide_status_bg_color_failure $_seg
        set -U tide_status_color            8da101  # green
        set -U tide_status_color_failure    f85552  # red

        set -U tide_cmd_duration_bg_color $_seg
        set -U tide_cmd_duration_color    939f91  # grey1

        set -U tide_context_bg_color        $_seg
        set -U tide_context_color_default   5c6a72  # fg
        set -U tide_context_color_root      f85552  # red
        set -U tide_context_color_ssh       dfa000  # yellow

        set -U tide_jobs_bg_color $_seg
        set -U tide_jobs_color    35a77c  # aqua

        set -U tide_vi_mode_bg_color_default $_seg
        set -U tide_vi_mode_bg_color_insert  $_seg
        set -U tide_vi_mode_bg_color_replace $_seg
        set -U tide_vi_mode_bg_color_visual  $_seg
        set -U tide_vi_mode_color_default    829181  # grey2
        set -U tide_vi_mode_color_insert     3a94c5  # blue
        set -U tide_vi_mode_color_replace    8da101  # green
        set -U tide_vi_mode_color_visual     f57d26  # orange

        set -U tide_direnv_bg_color          $_seg
        set -U tide_direnv_bg_color_denied   $_seg
        set -U tide_direnv_color             dfa000  # yellow
        set -U tide_direnv_color_denied      f85552  # red

        # Runtimes
        set -U tide_node_bg_color    $_seg ; set -U tide_node_color    8da101  # green
        set -U tide_python_bg_color  $_seg ; set -U tide_python_color  3a94c5  # blue
        set -U tide_rustc_bg_color   $_seg ; set -U tide_rustc_color   f57d26  # orange
        set -U tide_go_bg_color      $_seg ; set -U tide_go_color      35a77c  # aqua
        set -U tide_java_bg_color    $_seg ; set -U tide_java_color    f57d26  # orange
        set -U tide_ruby_bg_color    $_seg ; set -U tide_ruby_color    f85552  # red
        set -U tide_php_bg_color     $_seg ; set -U tide_php_color     3a94c5  # blue
        set -U tide_bun_bg_color     $_seg ; set -U tide_bun_color     5c6a72  # fg
        set -U tide_crystal_bg_color $_seg ; set -U tide_crystal_color 5c6a72  # fg
        set -U tide_elixir_bg_color  $_seg ; set -U tide_elixir_color  df69ba  # purple
        set -U tide_zig_bg_color     $_seg ; set -U tide_zig_color     dfa000  # yellow

        # Infra
        set -U tide_aws_bg_color       $_seg ; set -U tide_aws_color       dfa000  # yellow
        set -U tide_gcloud_bg_color    $_seg ; set -U tide_gcloud_color    3a94c5  # blue
        set -U tide_kubectl_bg_color   $_seg ; set -U tide_kubectl_color   3a94c5  # blue
        set -U tide_docker_bg_color    $_seg ; set -U tide_docker_color    3a94c5  # blue
        set -U tide_terraform_bg_color $_seg ; set -U tide_terraform_color df69ba  # purple
        set -U tide_pulumi_bg_color    $_seg ; set -U tide_pulumi_color    df69ba  # purple
        set -U tide_nix_shell_bg_color $_seg ; set -U tide_nix_shell_color 3a94c5  # blue

        # Misc
        set -U tide_distrobox_bg_color    $_seg ; set -U tide_distrobox_color    df69ba  # purple
        set -U tide_toolbox_bg_color      $_seg ; set -U tide_toolbox_color      df69ba  # purple
        set -U tide_os_bg_color           $_seg ; set -U tide_os_color           5c6a72  # fg
        set -U tide_shlvl_bg_color        $_seg ; set -U tide_shlvl_color        dfa000  # yellow
        set -U tide_time_bg_color         $_seg ; set -U tide_time_color         939f91  # grey1
        set -U tide_private_mode_bg_color $_seg ; set -U tide_private_mode_color 5c6a72  # fg
    end

    # ── Apply on shell start ──────────────────────────────────────────────────
    # _ef_last_mode is synced with macOS appearance by color-theme.fish
    # (which runs first, alphabetically). Mid-session: ef_light / ef_dark.
    if test "$_ef_last_mode" = light
        _tide_ef_light
    else
        _tide_ef_dark
    end
end