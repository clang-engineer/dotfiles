function fish_user_key_bindings
    if command --query rg.fzf
        bind \cf __rg_fzf_widget
    end
    if command -q tinty; and command -q fzf
        bind \e\ct tinty_pick
    end
end
