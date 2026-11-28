Output docs/demos/navigation.gif
Set Shell "fish"
Set FontSize 18
Set Width 1100
Set Height 650
Set TypingSpeed 65ms

Type "cd (chezmoi source-path | string replace -r '/chezmoi$' '')"
Enter
Sleep 1s
Ctrl+T
Sleep 1s
Type "README"
Sleep 1s
Ctrl+/
Sleep 3s
Escape
Ctrl+C
Type "rg.fzf chezmoi"
Enter
Sleep 3s
Escape
