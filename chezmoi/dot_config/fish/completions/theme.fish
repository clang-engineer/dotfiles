complete -c theme -f
complete -c theme -n '__fish_use_subcommand' -a list -d 'List available theme profiles'
complete -c theme -n '__fish_use_subcommand' -a show -d 'Show the selected theme profile'
complete -c theme -n '__fish_use_subcommand' -a set -d 'Switch Ghostty, Neovim and tmux together'
complete -c theme -n '__fish_use_subcommand' -s h -l help -d 'Show help'
complete -c theme -n '__fish_seen_subcommand_from set; and test (count (commandline -xpc)) -eq 2' -x -a '(command theme list)' -d 'Theme profile'
