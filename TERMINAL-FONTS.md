# Terminal fonts

Ghostty font settings live in [`chezmoi/dot_config/ghostty/config`](chezmoi/dot_config/ghostty/config),
which chezmoi manages as `~/.config/ghostty/config`. macOS also loads
`~/Library/Application Support/com.mitchellh.ghostty/config` **after** the XDG
file; keep font settings in the XDG file so the macOS file does not override
them. Homebrew fonts are listed in [`packages/Brewfile.cask`](packages/Brewfile.cask).
No `font-size` override is set; Ghostty uses its default size.

## Current combination

- **Latin text and Nerd Font symbols:** `Jetendard` (JetBrains Mono Nerd Font +
  Pretendard). It is the first `font-family`.
- **Korean syllables and compatibility jamo:** `IBM Plex Sans KR`, selected by
  `font-codepoint-map` for `U+AC00–U+D7A3` and `U+3130–U+318F`. Other codepoints
  can still fall back to Jetendard or the remaining fonts.
- **Further fallbacks:** `IBM Plex Mono`, `JuliaMono`, `Symbols Nerd Font Mono`,
  in that order.

IBM Plex Sans KR is proportional, not a Korean variant of IBM Plex Mono. Its
glyph widths and spacing can look uneven beside Jetendard in mixed Korean/English
terminal text. The current appearance is preferred despite that minor tradeoff;
keep this combination unless the spacing becomes distracting.

## Installed alternatives

| Family for `font-family` | Notes |
| --- | --- |
| `Jetendard` | Current primary; includes Korean and Nerd Font glyphs. |
| `IBM Plex Mono` | Monospaced Latin; needs a Korean fallback. |
| `IBM Plex Sans KR` | Korean candidate; proportional, so use with care in terminal grids. |
| `D2Coding` | Monospaced Korean/Latin candidate. |
| `Maple Mono NF` | Rounded Latin with Nerd Font glyphs; lacks Korean. |
| `JetBrains Mono` | Earlier primary; lacks Korean. |
| `Hack Nerd Font Mono` | Additional installed candidate. |

`JuliaMono` and `Symbols Nerd Font Mono` remain in the configured fallback list.
Do not uninstall a candidate when changing the active font; switch back by
editing the first `font-family` entry.

## Switching and checking

1. Edit `chezmoi/dot_config/ghostty/config`. Change the first `font-family` to
   the chosen family; leave the rest as fallbacks unless there is a reason to
   change them.
2. If testing a font's **own Korean glyphs** (especially Jetendard or D2Coding),
   remove or comment out `font-codepoint-map` first. Otherwise IBM Plex Sans KR
   still renders the mapped Hangul. Removing the mapping with Jetendard as the
   primary returns both Latin and Korean to Jetendard.
3. Apply only this config with `chezmoi apply ~/.config/ghostty/config`, then
   open a **new Ghostty tab or window**. `font-codepoint-map` changes affect
   new terminals only.
4. Verify the font actually chosen for each glyph:

   ```sh
   ghostty +list-fonts --family='Jetendard'
   ghostty +list-fonts --family='IBM Plex Sans KR'
   ghostty +show-face --string='A한글ㄱ❯'
   ghostty +validate-config
   ```

`+list-fonts` lists available font families; `+show-face` resolves the real font
used for each character. Compare Korean/English text and aligned columns in a
new terminal, not only the family names. Color themes are independent of font
selection; the saved Cyberdream theme remains available in
`chezmoi/dot_config/ghostty/themes/cyberdream`.
