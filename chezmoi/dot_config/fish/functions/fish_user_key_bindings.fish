function fish_user_key_bindings
    if command --query rg.fzf
        bind \cf __rg_fzf_widget
    end
    if command --query tinty; and command --query fzf; and command --query jq
        bind shift-tab __tinty_scheme_widget
    end
end
