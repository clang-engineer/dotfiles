function fish_user_key_bindings
    # Only Harlequin profile arguments use fzf; everything else keeps fish completion.
    bind \t '__harlequin_profiles --tab'
    if command --query rg.fzf
        bind \cf __rg_fzf_widget
    end
end
