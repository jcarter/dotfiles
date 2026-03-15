if status is-interactive
    set -g tide_character_icon ▶
    set -g tide_left_prompt_items pwd git
    set -g tide_right_prompt_items status cmd_duration context jobs
    set -g tide_status_icon ✓
    set -g tide_status_icon_failure ✕
    set -g tide_jobs_icon ⋯
    set -g tide_git_truncation_length 50
end
