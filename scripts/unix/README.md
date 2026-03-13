# Unix (macOS/Linux) Scripts

## One-shot setup (recommended)

```sh
./scripts/setup.sh
```

Options:

```sh
./scripts/setup.sh --force
```

## Run individual modules

```sh
./home/setup.sh              # 플랫 dotfile 링킹
./claude/setup.sh            # ~/.claude 링킹
./ssh/setup.sh               # ~/.ssh 링킹
./hammerspoon/setup.sh       # ~/.hammerspoon 링킹
./nvim/setup.sh              # ~/.config/nvim + ~/.exrc.lua 링킹
```

## Install scripts

```sh
./scripts/unix/install-oh-my-zsh.sh
./scripts/unix/install-zsh-plugins.sh
./scripts/unix/install-tpm.sh
```

## Optional helpers

Run only when needed:

```sh
./scripts/unix/opt/add-ssh-config.sh
./scripts/unix/opt/generate-ssh-key.sh
./scripts/unix/opt/setup-git-includeif.sh
./scripts/unix/opt/setup-github-account.sh
./scripts/unix/opt/setup-java-versions.sh
./scripts/unix/opt/nvim-java.sh
```
