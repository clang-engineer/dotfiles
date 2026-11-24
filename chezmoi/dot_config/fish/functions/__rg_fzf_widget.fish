function __rg_fzf_widget --description 'Insert paths selected by content search'
    set -l selected (command rg.fzf --print0 | string split0)
    if set -q selected[1]
        # Insert at the cursor, not over the token: existing command text stays intact.
        commandline --insert -- (string join ' ' -- (string escape -n -- $selected))' '
    end
    commandline -f repaint
end
