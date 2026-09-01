# Store Fisher config separately from "user space" config.

set fisher_path $__fish_config_dir/fisher

set -p fish_complete_path $fisher_path/completions
set -p fish_function_path $fisher_path/functions

for file in $fisher_path/conf.d/*.fish
    source $file
end
