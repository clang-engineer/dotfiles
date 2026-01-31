# Scripts

## One-shot setup (recommended)

```sh
./scripts/setup.sh
```

Options:

```sh
./scripts/setup.sh --force
./scripts/setup.sh --vim classic
```

## Run a single step

```sh
./scripts/tasks/01-link-dotfiles.sh
./scripts/tasks/02-oh-my-zsh.sh
./scripts/tasks/03-zsh-plugins.sh
./scripts/tasks/04-tpm.sh
./scripts/tasks/05-nvim.sh
```

## Optional helpers

Run only when needed:

```sh
./scripts/opt/add-ssh-config.sh
./scripts/opt/generate-ssh-key.sh
./scripts/opt/setup-git-includeif.sh
./scripts/opt/setup-github-account.sh
./scripts/opt/setup-java-versions.sh
```
