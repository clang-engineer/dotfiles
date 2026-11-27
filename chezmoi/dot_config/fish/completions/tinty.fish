function __tinty_completion_schemes
    if command -q jq
        __tinty_ranked_schemes | cut -f1
    else
        command tinty list | string match 'base16-*'
    end
end
complete -c tinty -n '__fish_tinty_using_subcommand apply' -f --keep-order -a '(__tinty_completion_schemes)'

complete -c tinty -n '__fish_tinty_using_subcommand info' -f -a '(command tinty list)' -d 'Scheme'