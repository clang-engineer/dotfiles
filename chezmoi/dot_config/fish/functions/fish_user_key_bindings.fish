function fish_user_key_bindings
    if command --query rg.fzf
        bind \cf __rg_fzf_widget
    end
    if command -q tinty; and command -q fzf
        bind \e\ct tinty_pick
    if command --query tinty; and command --query fzf; and command --query jq
        bind shift-tab __tinty_pick_widget
    if command --query tinty; and command --query fzf
        bind shift-tab __tinty_scheme_widget
    end
end
