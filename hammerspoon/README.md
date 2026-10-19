# Hammerspoon

This directory is symlinked to `~/.hammerspoon`. AeroSpace owns workspaces and
tiling, Raycast provides search-oriented commands, and Hammerspoon handles
floating-window shortcuts and event-driven macOS automation.

## Current configuration

| File | Responsibility |
|---|---|
| `init.lua` | Install the `hs` CLI and load active modules |
| `modules/rectangle.lua` | Rectangle-compatible floating-window placement |
| `modules/window-hint.lua` | Select a window with `Shift+F1` |
| `modules/aerospace-windows.lua` | Display AeroSpace workspace and move notifications |
| `modules/aerospace-move-node.sh` | Move a window and report the result |
| `modules/aerospace-reflow.sh` | Reapply workspace placement rules to open windows |
| `modules/hjkl.lua` | Disabled global Ctrl-HJKL navigation experiment |

The window-management ownership should remain explicit:

- AeroSpace: workspaces, tiled windows, directional focus, and node movement
- Raycast or Hammerspoon: floating-window placement; avoid maintaining both
- Hammerspoon: event watchers and integration between macOS tools

## Troubleshooting: AeroSpace window-move shortcuts do nothing

If `Option+Shift+1–4` does nothing after a fresh macOS installation, but running
`modules/aerospace-move-node.sh` from Terminal works, check AeroSpace's folder
access permissions—not just Accessibility.

`~/.hammerspoon` is a symlink to this repository. If the repository is under
Desktop, AeroSpace needs permission to access Desktop when its
`exec-and-forget` binding launches the script. Terminal's permission does not
grant the same access to AeroSpace.

1. Open **System Settings → Privacy & Security → Files and Folders → AeroSpace**.
2. Enable **Desktop Folder** access if the repository is stored there.
3. Quit AeroSpace completely, reopen it, and retry the shortcut.

For other protected locations, check the corresponding folder permission.
Accessibility and folder access are separate permissions; restarting AeroSpace
alone does not grant missing access.

To compare the two execution paths, focus a window outside `1:Browser` and run
these commands separately. Each attempts to send that window to `1:Browser`;
refocus a window outside the target workspace before the second test:

```sh
# Runs with the terminal app's permissions.
bash ~/.hammerspoon/modules/aerospace-move-node.sh '1:Browser'

# Runs the configured binding through AeroSpace, with AeroSpace's permissions.
aerospace trigger-binding --mode main alt-shift-1
```

If only the first works, folder access is one possible cause. AeroSpace's
`exec-and-forget` discards stdout, stderr, and exit status, so a script launch
failure may appear completely silent. This Desktop permission issue was
confirmed after a macOS reinstall on 2026-10-20.

## Common patterns to consider

These are proposals, not currently enabled features. Public Hammerspoon
configurations commonly use small native Lua modules rather than many Spoons.

### Configuration reload

Watch Lua files under `~/.hammerspoon` and call `hs.reload()` after changes. A
filtered `hs.pathwatcher` is smaller than `ReloadConfiguration.spoon` and works
well with this repository's live symlink. Keep `hs.ipc` as a manual fallback.

### Input sources

Use `hs.keycodes.currentSourceID()` for explicit Korean/English selection and,
if useful, force English when Ghostty becomes active. Prefer bundle IDs and a
small local module over app-name-based `InputSourceSwitch.spoon` configuration.
Avoid forcing one input source across an entire IDE unless that behavior is
clearly desirable.

### Hyper key

A Hyper namespace (`cmd+ctrl+alt+shift`, often mapped from Caps Lock to F18 by
Karabiner) is common in public dotfiles. In this setup it should be limited to
system automation such as reload, input source, microphone, caffeine, or audio
output. Do not duplicate AeroSpace window and workspace bindings.

### Audio and microphone

Use `hs.audiodevice.watcher` when a dock, monitor, headset, or DAC requires a
preferred-device policy. `MicMute.spoon` or `PushToTalk.spoon` are reasonable
when meeting controls need a visible state or momentary behavior. Keep
machine-specific device names in private chezmoi data or `hs.settings`.

### URL routing

`URLDispatcher.spoon` can route selected domains or source applications to
Chrome while leaving Safari as the general browser. Keep private company
domains out of this public repository.

### Caffeine

For a simple shortcut, call `hs.caffeinate.toggle("displayIdle")` directly.
Use `Caffeine.spoon` only when a persistent menu-bar indicator is useful.

For terminal-driven long-running work, keep the distinction explicit:

- `caffeinate -i` prevents system idle sleep while allowing the display to sleep.
- `caffeinate -d` prevents display sleep; it does not imply the `-i` assertion.
- `caffeinate -di` prevents both system idle sleep and display sleep.
- `pmset displaysleepnow` turns the display off immediately without requesting
  system sleep.

A useful pattern for unattended CLI agents, builds, or downloads is:

```sh
caffeinate -i &
pmset displaysleepnow
```

This keeps the Mac awake for the background work while turning the display off.

### Wi-Fi automation

Use `hs.wifi.watcher` only for a concrete work/home action such as selecting an
audio device, toggling a VPN, or running a Shortcut. SSIDs are private location
data and must not be committed here.

## Recommendations

Suggested adoption order:

1. Add filtered configuration auto-reload.
2. Choose either Raycast or Hammerspoon as the only floating-window manager.
3. Add a small Korean/English input-source module.
4. Add audio, microphone, Wi-Fi, or URL automation only for an observed need.
5. Introduce a Hyper key only if it replaces scattered shortcuts rather than
   adding another namespace to memorize.

Avoid adding these without a specific unmet need:

- `AppLauncher`, `Commander`, or `Seal`: Raycast already owns launching.
- `ClipboardTool` or `TextClipboardHistory`: Raycast provides clipboard history.
- `PaperWM`, `MiroWindowsManager`, `WinWin`, or `WindowGrid`: they overlap with
  AeroSpace and the existing Rectangle-compatible module.
- `SpoonInstall` auto-update: runtime installation would mutate this symlinked
  Git working tree. Pin any selected Spoon through the repository/chezmoi flow.
- `HSKeybindings`, `ModalMgr`, or `RecursiveBinder` solely for a global shortcut
  sheet: they cannot automatically discover both AeroSpace and Hammerspoon
  bindings without duplicated metadata or rebinding.

## Follow-up improvements

- Replace the fragile TOML parsing in `modules/aerospace-reflow.sh` with
  `aerospace run-callback --for-every-window on-window-detected` if preserving
  the moved-window count is not required.
- If a shortcut sheet is still needed, render a display-only Hammerspoon canvas
  from Hammerspoon binding descriptions and AeroSpace's effective JSON config.
  Keep action ownership in the existing tools.
