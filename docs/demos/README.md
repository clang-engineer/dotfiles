# Terminal demos

Record with [VHS](https://github.com/charmbracelet/vhs) from the repository root, on a machine with the dotfiles already applied. Install VHS separately (for example, `brew install vhs`).

```sh
vhs docs/demos/themes.tape
vhs docs/demos/navigation.tape
```

Run `tinty sync` first. The themes demo previews the ranked picker without changing the active scheme. The navigation demo uses the installed Fish bindings and repository files. Use a terminal outside an existing tmux session if needed; ensure Fish startup does not auto-attach tmux during recording.

Review the generated GIFs before committing them. Do not record private paths, credentials, or personal history. The full bootstrap is intentionally not executed in a recording because it modifies the machine and can take several minutes.
