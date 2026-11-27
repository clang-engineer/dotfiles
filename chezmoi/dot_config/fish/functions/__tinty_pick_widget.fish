function __tinty_pick_widget
    set -l input (commandline --current-process --cut-at-cursor)
    if not string match --quiet --regex '^\s*tinty\s+apply\s+[a-zA-Z0-9-]*$' -- "$input"
        commandline -f complete-and-search
        return
    end

    set -l row (__tinty_ranked_schemes | fzf --no-multi --no-sort --layout=reverse \
        --border --height=85% --prompt='Theme> ' --delimiter '\t' --with-nth 2 \
        --header 'Sort: GitHub Stars ↓ | Enter: insert theme | Esc: cancel')
    if test $status -eq 0; and test -n "$row"
        set -l fields (string split -m1 \t -- "$row")
        commandline --current-token --replace -- "$fields[1]"
    end
    commandline -f repaint
end
