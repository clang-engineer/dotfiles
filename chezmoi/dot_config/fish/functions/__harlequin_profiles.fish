function __harlequin_profiles --argument-names action
    if test "$action" != --tab
        type -q harlequin-config; or return 1
        set -l tokens (commandline -xp)
        # Fish expands quoted paths and variables; the generator owns environment fallback.
        argparse --move-unknown --strict-longopts 'config-path=' -- $tokens[2..] 2>/dev/null; or return 1
        harlequin-config --complete-harlequin-profiles $_flag_config_path 2>/dev/null
        return $status
    end

    set -l before (commandline -xpc)
    if contains -- "$before[1]" command exec
        set before $before[2..]
    end
    set -l current (commandline -ct)
    set -l prefix ''
    set -l profile_position 0
    if string match -qr '(^|/)harlequin$' -- "$before[1]"; and not contains -- -- $before
        if contains -- "$before[-1]" -P --profile
            set profile_position 1
        else if test "$before[-1]" != --config-path
            if string match -q -- '--profile=*' "$current"
                set prefix --profile=
                set profile_position 1
            else if string match -qr '^-P' -- "$current"
                set prefix -P
                set profile_position 1
            end
        end
    end

    if test $profile_position -eq 0; or not type -q fzf; or not type -q harlequin-config
        commandline -f complete
        return
    end

    set -l profiles (complete -C (commandline -cp) 2>/dev/null | string replace -r '\t.*$' '')
    if test -n "$prefix"
        set profiles (string replace -r "^$prefix" '' -- $profiles)
    end
    if test (count $profiles) -eq 0
        commandline -f complete
        return
    end
    set -l start (math (string length -- "$prefix") + 1)
    set -l query (string sub -s $start -- "$current")
    set query (string unescape -- "$query" 2>/dev/null)
    # Keep global actions/output options isolated while inheriting the shared color theme.
    set -l selected (printf '%s\n' $profiles | env FZF_DEFAULT_OPTS= fzf \
        --height=40% --layout=reverse --query="$query" --prompt='Harlequin profile> ')
    if test $status -eq 0; and test (count $selected) -eq 1
        commandline --current-token --replace -- "$prefix"(string escape -- "$selected")
    end
    commandline -f repaint
end
