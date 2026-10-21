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

## Shared agent skills

The `agents` package manages `~/.agents/skills/` and `~/.agents/.skill-lock.json`.
It includes each skill's supporting scripts, references, and agent metadata.

```sh
stow --no-folding --simulate --verbose --target="$HOME" agents
stow --no-folding --verbose --target="$HOME" agents
```

Back up and move conflicting existing files aside before applying, just as with
OpenCode. New skills installed directly into `~/.agents/skills` are not
automatically tracked: move them into `agents/.agents/skills/`, then rerun Stow.
Review the lockfile too; installers may replace symlinks with regular files.

## Kitty

The `kitty` package manages `kitty.conf`, `current-theme.conf`,
`quick-access-terminal.conf`, and the custom macOS icon `kitty.app.png` under
`~/.config/kitty/`. Backup files (`*.bak`) stay local.

```sh
stow --no-folding --simulate --verbose --target="$HOME" kitty
stow --no-folding --verbose --target="$HOME" kitty
```

Back up and move conflicting existing files aside before applying. The config
is preserved as-is, including the JetBrains Mono font choice and macOS keybindings;
install the font separately on another desktop. Kitty is optional on a headless
VPS: omit `kitty` from the commands below if you do not use it there.

## Sync

Edit the installed configuration normally: the symlinks point into this repo.
Review changes, then commit and push explicitly. On another machine:

```sh
git pull --ff-only
stow --no-folding --verbose --target="$HOME" opencode agents kitty
```

Pulling updates existing linked files; rerunning Stow creates links for new ones.
Before pulling a change that removes managed files, unstow the old package first
to avoid dangling links, then pull and stow again.

## Unlink

```sh
stow --no-folding --delete --target="$HOME" opencode agents kitty
```

This removes managed symlinks, not repository files or unrelated configuration.
