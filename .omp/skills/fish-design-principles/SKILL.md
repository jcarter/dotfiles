---
name: fish-design-principles
description: Fish shell config review checklist derived from fish's five design laws. Covers variable scope (set -g vs -gx vs -U), fork-free hot paths for preexec/prompt hooks, and fish-specific command substitution gotchas. Use when writing or reviewing config.fish, conf.d scripts, or fish functions.
globs:
  - "**/*.fish"
---

# Fish Design Principles

## Overview

Fish has five design laws. Two of them — **orthogonality** and **responsiveness** — produce concrete, checkable rules for config authoring. The others (user focus, discoverability, configurability) govern fish itself, not user config.

Source: https://fishshell.com/docs/current/design.html

## Checklist — Run Before Any Fish Config Change

<critical>
**Responsiveness (no forks in hot paths)**
- [ ] Hot paths (`fish_preexec`, `fish_prompt` hooks, startup) use builtins only
- [ ] `read -l var < file` not `cat file | ...` (read is a builtin; cat forks)
- [ ] `string` not external `grep`/`sed`/`awk` for string work
- [ ] External commands (`defaults`, `mise`, `brew`) are one-time startup calls, not per-prompt

**Orthogonality (right tool, right scope)**
- [ ] `set -g` for fish-internal config vars (tide, fzf, etc.) — they never need child process export
- [ ] `set -gx` only when the variable must reach external commands (`HOMEBREW_*`, `*_FLAGS`, `EDITOR`)
- [ ] `set -U` only for values that should persist across sessions without config.fish setting them each time
- [ ] No aliases if a function does the same job

**Correctness (fish-specific gotchas)**
- [ ] Command substitution with no output produces an **empty list**, not an empty string
- [ ] Never `test (cmd) = X` — assign first: `set -l v (cmd); test "$v" = X`
- [ ] `set -l` inside an `if`/`for`/`while` block is scoped to that block — declare defaults outside
</critical>

## Scope Flag Quick Reference

| Flag | Scope | Exported? | When to use |
|------|-------|-----------|-------------|
| `-l` | Current block | No | Temporaries inside functions/blocks |
| `-g` | Current session | No | Per-session config (prompt, plugin vars) |
| `-U` | All sessions (persists) | No | User preferences that survive across sessions |
| `-x` | (modifier) | Yes | Add to `-g` or `-U` when child processes need it |
| `-gx` | Session + export | Yes | Env vars for external tools: `EDITOR`, `PAGER`, `*_NO_*` |

**Rule of thumb:** If a tide/fzf/fish plugin reads it, use `-g`. If `git` or `brew` reads it, use `-gx`.

## Hot Path Pattern

`fish_preexec` fires on every command. Keep it cheap:

```fish
# Good — one builtin file read, cached guard variable
function __my_hook --on-event fish_preexec
    if test -f "$__fish_config_dir/.some_marker"
        read -l value < "$__fish_config_dir/.some_marker"  # builtin, no fork
    else
        set -l value default
    end
    if test "$value" != "$__my_cached_value"              # guard: skip if unchanged
        set -g __my_cached_value $value
        # do the work
    end
end

# Bad — forks on every command
function __my_hook --on-event fish_preexec
    set -l value (cat "$__fish_config_dir/.some_marker")  # forks cat every command
    set -l mode (defaults read -g AppleInterfaceStyle 2>/dev/null)  # forks defaults every command
end
```

## Common Mistakes

<avoid>
| Mistake | Fix |
|---------|-----|
| `set -gx tide_left_prompt_items ...` | `set -g tide_left_prompt_items ...` — tide is a fish function, not an external command |
| `test (defaults read -g X 2>/dev/null) = Dark` | `set -l v (defaults ...); test "$v" = Dark` — empty output produces empty list, not empty string |
| `set -l mode (cat file)` in preexec | `read -l mode < file` — avoids forking cat on every command |
| `set -l result light; if ...; set -l result dark; end` | Declare outside, reassign inside: `set -l result light; if ...; set result dark; end` |

</avoid>