complete -c harlequin-config -f
complete -c harlequin-config -n '__fish_use_subcommand' -a init -d 'Register a connection catalog or print shell integration'
complete -c harlequin-config -n '__fish_use_subcommand' -s h -l help -d 'Show help'
complete -c harlequin-config -n '__fish_seen_subcommand_from init; and test (count (commandline -xpc)) -eq 2' -a zsh -d 'Print zsh integration'
complete -c harlequin-config -n '__fish_seen_subcommand_from init; and not __fish_seen_subcommand_from zsh' -l source -x -a '(__fish_complete_directories)' -d 'Register a connection catalog directory'
