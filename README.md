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

Use `--no-folding` for OpenCode, agents, Kitty, tmux, and Git to keep application
directories real and symlink individual files. Zed uses a deliberate exception
for its themes directory; follow the Zed commands below.

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

## tmux

The `tmux` package manages `~/.config/tmux/tmux.conf`.

```sh
stow --no-folding --simulate --verbose --target="$HOME" tmux
stow --no-folding --verbose --target="$HOME" tmux
```

Back up and move any conflicting existing config aside before applying. The
configuration is preserved as-is and uses `tpack` to initialize plugins, including
`tmux-resurrect`. Install tmux and tpack separately on each machine; plugin
downloads and saved sessions are not managed here. A legacy `~/.tmux.conf` can
take precedence over this config, so check for it on a new machine.

Reload an existing tmux session with:

```sh
tmux source-file ~/.config/tmux/tmux.conf
```

## Zed

The `zed` package manages `settings.json`, `keymap.json`, and the entire `themes/`
directory under `~/.config/zed/`. Settings and keymap are individual symlinks;
`themes/` is a directory symlink, so adding or removing themes from either
location changes the repository directly. Commit/push/pull syncs these changes
without needing to rerun Stow for each new theme. The prompt database,
credentials, and other application state stay local.

```sh
mkdir -p "$HOME/.config/zed"
stow --simulate --verbose --target="$HOME" zed
stow --verbose --target="$HOME" zed
```

Creating the real Zed directory first prevents Stow from linking the entire
application directory. Do not use `--no-folding` for Zed: it would unfold the
themes link into individual files. If `themes/` already exists as a real
directory, preserve any themes you want to share in the repository, then back up
and move the existing directory aside so Stow can create the directory symlink.

Back up and move conflicting existing files aside before applying. Settings are
preserved as-is, including SSH host aliases, remote project paths, font choices,
and the custom `~/.local/bin/cursor-agent` command. Set up these dependencies and
authenticate separately on each machine. Review personal host/project details
before publishing this repository. Zed is optional on a headless VPS: omit `zed`
from the commands below if you do not use it there.

## Git

The `git` package manages `~/.config/.gitconfig`. The existing `~/.gitconfig`
includes this file and remains local.

```sh
stow --no-folding --simulate --verbose --target="$HOME" git
stow --no-folding --verbose --target="$HOME" git
```

Back up and move any conflicting existing file aside before applying. On a new
machine, check `git config --global --get-all include.path`. If the include is
not already present, add it without replacing other global settings:

```sh
git config --global --add include.path '~/.config/.gitconfig'
```

The shared configuration is preserved as-is, including identity, aliases, and
the `delta` pager. Install delta separately. Keep credentials out of this file;
machine-specific overrides can go in `~/.gitconfig` after the include.

## Sync

Edit the installed configuration normally: the symlinks point into this repo.
Review changes, then commit and push explicitly. On another machine:

```sh
git pull --ff-only
stow --no-folding --verbose --target="$HOME" opencode agents kitty tmux git
mkdir -p "$HOME/.config/zed"
stow --verbose --target="$HOME" zed
```

Pulling updates existing linked files; rerunning Stow creates links for new ones.
Before pulling a change that removes managed files, unstow the old package first
to avoid dangling links, then pull and stow again.

## Unlink

```sh
stow --no-folding --delete --target="$HOME" opencode agents kitty tmux zed git
```

This removes managed symlinks, not repository files or unrelated configuration.
