function tinty_pick --description 'Select and apply a Tinty scheme'
    command -q tinty; or return 127
    command -q fzf; or return 127
    set -l scheme (command tinty list | command fzf --no-multi --prompt='Theme> ')
    test -n "$scheme"; or return 0
    command tinty apply "$scheme"; or return $status
    set -l root "$HOME/.config"
    if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
        set root "$XDG_CONFIG_HOME"
    end
    set -l generated "$root/tinted-theming/tinty/generated/fzf.fish"
    if test -f "$generated"
        source "$generated"
    end
end
