command -q tinty; or return
command tinty generate-completion fish | source

complete -c tinty -n '__fish_tinty_using_subcommand apply' -f -a '(command tinty list)' -d 'Scheme'
complete -c tinty -n '__fish_tinty_using_subcommand info' -f -a '(command tinty list)' -d 'Scheme'
