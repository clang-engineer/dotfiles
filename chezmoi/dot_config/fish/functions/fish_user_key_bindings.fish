function fish_user_key_bindings
    # Only Harlequin profile arguments use fzf; everything else keeps fish completion.
    bind \t '__harlequin_profiles --tab'
end
