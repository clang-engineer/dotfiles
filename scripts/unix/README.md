# Unix (macOS/Linux) Scripts

## One-shot setup (recommended)

```sh
./scripts/unix/setup.sh
```

Options:

```sh
./scripts/unix/setup.sh --force
./scripts/unix/setup.sh --vim classic
```

## Run a single step

```sh
./scripts/unix/tasks/01-link-dotfiles.sh
./scripts/unix/tasks/02-oh-my-zsh.sh
./scripts/unix/tasks/03-zsh-plugins.sh
./scripts/unix/tasks/04-tpm.sh
./scripts/unix/tasks/05-nvim.sh
```

## Claude Code

```sh
# ~/.claude/settings.json에 아래 설정 추가
# "statusLine": {
#   "type": "command",
#   "command": "bash /path/to/statusline-command.sh"
# }

# 또는 직접 복사
cp scripts/unix/statusline-command.sh ~/.claude/statusline-command.sh
```

## Optional helpers

Run only when needed:

```sh
./scripts/unix/opt/add-ssh-config.sh
./scripts/unix/opt/generate-ssh-key.sh
./scripts/unix/opt/setup-git-includeif.sh
./scripts/unix/opt/setup-github-account.sh
./scripts/unix/opt/setup-java-versions.sh
```
