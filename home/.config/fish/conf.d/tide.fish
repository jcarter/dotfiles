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

    # ── Everforest palettes ───────────────────────────────────────────────────
    # Keep the assignments below explicit: Tide reads these universal variables
    # from child fish processes spawned by its prompt.
    function _tide_apply_palette --argument-names mode
        if test "$mode" = light
            set -f _seg e6e2cc
            set -f _gitu faedcd
            set -f _gitr fde3da
            set -f _frame e0dcc7
            set -f _separator 939f91
            set -f _green 8da101
            set -f _red f85552
            set -f _blue 3a94c5
            set -f _aqua 35a77c
            set -f _grey1 939f91
            set -f _grey2 829181
            set -f _yellow dfa000
            set -f _fg 5c6a72
            set -f _orange f57d26
            set -f _purple df69ba
        else
            set -f _seg 3d484d
            set -f _gitu 4d4c43
            set -f _gitr 514045
            set -f _frame 475258
            set -f _separator 9da9a0
            set -f _green a7c080
            set -f _red e67e80
            set -f _blue 7fbbb3
            set -f _aqua 83c092
            set -f _grey1 859289
            set -f _grey2 9da9a0
            set -f _yellow dbbc7f
            set -f _fg d3c6aa
            set -f _orange e69875
            set -f _purple d699b6
        end

        set -U tide_prompt_color_frame_and_connection $_frame
        set -U tide_prompt_color_separator_same_color $_separator
        set -U tide_character_color $_green
        set -U tide_character_color_failure $_red
        set -U tide_pwd_bg_color $_seg
        set -U tide_pwd_color_anchors $_blue
        set -U tide_pwd_color_dirs $_aqua
        set -U tide_pwd_color_truncated_dirs $_grey1
        set -U tide_git_bg_color $_seg
        set -U tide_git_bg_color_unstable $_gitu
        set -U tide_git_bg_color_urgent $_gitr
        set -U tide_git_color_branch $_green
        set -U tide_git_color_dirty $_yellow
        set -U tide_git_color_staged $_yellow
        set -U tide_git_color_stash $_green
        set -U tide_git_color_untracked $_blue
        set -U tide_git_color_upstream $_green
        set -U tide_git_color_conflicted $_red
        set -U tide_git_color_operation $_red
        set -U tide_status_bg_color $_seg
        set -U tide_status_bg_color_failure $_seg
        set -U tide_status_color $_green
        set -U tide_status_color_failure $_red
        set -U tide_cmd_duration_bg_color $_seg
        set -U tide_cmd_duration_color $_grey1
        set -U tide_context_bg_color $_seg
        set -U tide_context_color_default $_fg
        set -U tide_context_color_root $_red
        set -U tide_context_color_ssh $_yellow
        set -U tide_jobs_bg_color $_seg
        set -U tide_jobs_color $_aqua
        set -U tide_vi_mode_bg_color_default $_seg
        set -U tide_vi_mode_bg_color_insert $_seg
        set -U tide_vi_mode_bg_color_replace $_seg
        set -U tide_vi_mode_bg_color_visual $_seg
        set -U tide_vi_mode_color_default $_grey2
        set -U tide_vi_mode_color_insert $_blue
        set -U tide_vi_mode_color_replace $_green
        set -U tide_vi_mode_color_visual $_orange
        set -U tide_direnv_bg_color $_seg
        set -U tide_direnv_bg_color_denied $_seg
        set -U tide_direnv_color $_yellow
        set -U tide_direnv_color_denied $_red

        # Runtimes
        set -U tide_node_bg_color $_seg; set -U tide_node_color $_green
        set -U tide_python_bg_color $_seg; set -U tide_python_color $_blue
        set -U tide_rustc_bg_color $_seg; set -U tide_rustc_color $_orange
        set -U tide_go_bg_color $_seg; set -U tide_go_color $_aqua
        set -U tide_java_bg_color $_seg; set -U tide_java_color $_orange
        set -U tide_ruby_bg_color $_seg; set -U tide_ruby_color $_red
        set -U tide_php_bg_color $_seg; set -U tide_php_color $_blue
        set -U tide_bun_bg_color $_seg; set -U tide_bun_color $_fg
        set -U tide_crystal_bg_color $_seg; set -U tide_crystal_color $_fg
        set -U tide_elixir_bg_color $_seg; set -U tide_elixir_color $_purple
        set -U tide_zig_bg_color $_seg; set -U tide_zig_color $_yellow

        # Infra
        set -U tide_aws_bg_color $_seg; set -U tide_aws_color $_yellow
        set -U tide_gcloud_bg_color $_seg; set -U tide_gcloud_color $_blue
        set -U tide_kubectl_bg_color $_seg; set -U tide_kubectl_color $_blue
        set -U tide_docker_bg_color $_seg; set -U tide_docker_color $_blue
        set -U tide_terraform_bg_color $_seg; set -U tide_terraform_color $_purple
        set -U tide_pulumi_bg_color $_seg; set -U tide_pulumi_color $_purple
        set -U tide_nix_shell_bg_color $_seg; set -U tide_nix_shell_color $_blue

        # Misc
        set -U tide_distrobox_bg_color $_seg; set -U tide_distrobox_color $_purple
        set -U tide_toolbox_bg_color $_seg; set -U tide_toolbox_color $_purple
        set -U tide_os_bg_color $_seg; set -U tide_os_color $_fg
        set -U tide_shlvl_bg_color $_seg; set -U tide_shlvl_color $_yellow
        set -U tide_time_bg_color $_seg; set -U tide_time_color $_grey1
        set -U tide_private_mode_bg_color $_seg; set -U tide_private_mode_color $_fg
    end

    function _tide_ef_dark
        _tide_apply_palette dark
    end

    function _tide_ef_light
        _tide_apply_palette light
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
