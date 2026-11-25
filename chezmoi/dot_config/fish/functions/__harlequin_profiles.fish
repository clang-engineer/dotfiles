function __harlequin_profiles
    type -q harlequin-config; or return 1
    set -l tokens (commandline -xp)
    # Fish expands quoted paths and variables; the generator owns environment fallback.
    argparse --move-unknown --strict-longopts 'config-path=' -- $tokens[2..] 2>/dev/null; or return 1
    harlequin-config --complete-harlequin-profiles $_flag_config_path 2>/dev/null
end
