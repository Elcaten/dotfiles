# Dotfiles

Personal configuration managed with Git and GNU Stow. Each top-level package
mirrors paths relative to the home directory.

## Install Stow

macOS (MacPorts):

```sh
sudo port install stow
```

Debian/Ubuntu:

```sh
sudo apt install stow
```

## OpenCode

From this repository, preview and then apply:

```sh
stow --no-folding --simulate --verbose --target="$HOME" opencode
stow --no-folding --verbose --target="$HOME" opencode
```

If an existing file conflicts, compare it with the repository copy, back it up
outside `~/.config`, and move it out of the way before applying. Do not use
`--adopt` to resolve conflicts blindly: it changes repository files.

Always use `--no-folding` to keep application directories real and symlink
individual files. This keeps generated files out of this repository.

Both `opencode.jsonc` (server/model configuration) and `cli.json` (terminal
preferences, including `/settings`) are managed. Future skills belong in
`opencode/.config/opencode/skills/<skill-id>/SKILL.md`. Run Stow again after
adding files.

Keep credentials, `service.json`, dependency files, caches, and session data local.
Never add secrets to Git. Authenticate separately on each machine.

## Sync

Edit the installed configuration normally: the symlinks point into this repo.
Review changes, then commit and push explicitly. On another machine:

```sh
git pull --ff-only
stow --no-folding --verbose --target="$HOME" opencode
```

Pulling updates existing linked files; rerunning Stow creates links for new ones.
Before pulling a change that removes managed files, unstow the old package first
to avoid dangling links, then pull and stow again.

## Unlink

```sh
stow --no-folding --delete --target="$HOME" opencode
```

This removes managed symlinks, not repository files or unrelated configuration.
