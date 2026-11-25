# Clear exported assignments without executing the env file; does not restore old values.
# With no argument, pick a .env* file in the current directory using fzf.
function env_unset --description 'Clear variables listed as export NAME=value in a file'
    if test (count $argv) -gt 1
        printf '%s\n' 'Usage: env_unset [FILE]' >&2
        return 2
    end
    set --local __env_unset_file
    if test (count $argv) -eq 0
        if not command --query fzf
            printf '%s\n' 'env_unset: fzf is required when no file is given' >&2
            return 1
        end
        set --local __env_unset_candidates (command find . ! -name . -prune -type f -name '.env*' -print)
        or return
        if test (count $__env_unset_candidates) -eq 0
            printf '%s\n' 'env_unset: no .env* files in the current directory' >&2
            return 1
        end
        set __env_unset_file (printf '%s\n' $__env_unset_candidates | command fzf --no-multi --height=40% --reverse --prompt='env_unset> ')
        or return
    else
        set __env_unset_file "$argv[1]"
    end
    if not test -f "$__env_unset_file"; or not test -r "$__env_unset_file"
        printf '%s\n' 'env_unset: expected a readable file' >&2
        return 1
    end
    while read --local __env_unset_line
        set --local __env_unset_name (string match --regex --groups-only '^export ([A-Za-z_][A-Za-z0-9_]*)=' -- "$__env_unset_line")
        if test (count $__env_unset_name) -eq 1
            if set --query --global "$__env_unset_name"
                set --erase --global "$__env_unset_name"; or return
            end
        end
    end < "$__env_unset_file"
    return 0
end
