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
mkdir -p "$HOME/.config/opencode"
stow --simulate --verbose --target="$HOME" opencode
stow --verbose --target="$HOME" opencode
```

If an existing file conflicts, compare it with the repository copy, back it up
outside `~/.config`, and move it out of the way before applying. Do not use
`--adopt` to resolve conflicts blindly: it changes repository files.

Use `--no-folding` for Kitty, tmux, Git, and Fish to keep application directories
real and link individual files. OpenCode and shared agent skills use directory
links for their skills. Zed uses a directory link for its themes. Follow the
commands for each package.

Both `opencode.jsonc` (server/model configuration) and `cli.json` (terminal
preferences, including `/settings`) are managed. Create `~/.config/opencode/`
first to keep that directory real. Do not use `--no-folding` for this package:
Stow must link `skills/` as a whole directory.

OpenCode-specific skills live in
`opencode/.config/opencode/skills/<skill-id>/SKILL.md`. The installed
`~/.config/opencode/skills/` link points to that directory. New skills installed
there appear in this repository automatically. Review all skill files before
you commit them. Shared skills stay in the separate `agents` package.

To migrate an existing local `~/.config/opencode/skills/` directory, compare its
contents with the repository. Copy any skills you want to keep into the
repository, then back up and move the local directory outside `~/.config`.
Run the OpenCode Stow commands above and check the link:

```sh
test -L "$HOME/.config/opencode/skills"
```

### Add an MCP server

Use `--global` to save an MCP server in the shared OpenCode config:

```sh
opencode mcp add context7 --global --url https://mcp.context7.com/mcp
opencode mcp list
git diff -- opencode/.config/opencode/opencode.jsonc
```

Without `--global`, the command writes to the project config. That file can be
outside this repository. OpenCode V2 stores server entries under `mcp.servers`.
See the [OpenCode MCP guide](https://dev.opencode.ai/v2/docs/mcp-servers/).

### Check the config links

If settings do not appear in Git, check both links:

```sh
ls -l "$HOME/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/cli.json"
stow --simulate --verbose --target="$HOME" opencode
```

Both files must be links to this repository. If either file is a regular file,
compare it with the repository copy. Copy the settings you want to keep into
the repository, back up the local file outside `~/.config`, and move it out of
the way. Then run Stow again. Stow will report a conflict until that file is
removed. Keep the parent directory real so local data stays outside Git.

Keep credentials, `service.json`, dependency files, caches, and session data local.
Never add secrets to Git. Authenticate separately on each machine.

## Shared agent skills

The `agents` package manages `~/.agents/skills/` and `~/.agents/.skill-lock.json`.
Keep `~/.agents/` real, link `skills/` as a whole directory, and link the lockfile
individually. This leaves each `SKILL.md` as a regular file inside its source
skill directory, using the folder symlink support documented by Codex. Supporting
scripts, references, and agent metadata travel with the skills.

```sh
mkdir -p "$HOME/.agents"
stow --simulate --verbose --target="$HOME" agents
stow --verbose --target="$HOME" agents
```

Creating `~/.agents/` first prevents Stow from linking the entire application
directory. Do not use `--no-folding` when installing or syncing `agents`: it
would unfold `skills/` into individual file links. New skills installed directly
into `~/.agents/skills/` now appear in this repository automatically; review,
commit, and push them explicitly. Pulling adds new skills without rerunning Stow.
Review the lockfile too; installers may replace its symlink with a regular file.
Never put secrets or machine-local data inside the shared skills directory.

### Migrate an existing per-file installation

From this repository, remove only Stow-managed links, recreate the real parent,
then preview and apply directory folding:

```sh
stow --no-folding --delete --verbose --target="$HOME" agents
find "$HOME/.agents/skills" -depth -type d -empty -delete
```

Unstowing leaves unmanaged files alone. The `find` command removes only empty
directories left by the per-file installation, never files or nonempty
directories. If a real `~/.agents/skills/` directory remains, stop before applying:
compare and preserve its local skills in the repository, then back up and move
that directory aside. Likewise, back up and move any conflicting regular
lockfile aside. Once the skills path is clear:

```sh
mkdir -p "$HOME/.agents"
stow --simulate --verbose --target="$HOME" agents
stow --verbose --target="$HOME" agents
```

Verify the final layout:

```sh
test -L "$HOME/.agents/skills"
test -f "$HOME/.agents/skills/code-review/SKILL.md"
test ! -L "$HOME/.agents/skills/code-review/SKILL.md"
```

After changing the link layout, run `opencode reload` to refresh OpenCode's skill
discovery. Restart Codex or its ACP session if it does not discover the skills
immediately.

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

## Fish

The `fish` package manages `config.fish`, shared `conf.d` snippets, and the seven
shared functions under `~/.config/fish/`. All directories remain real; Stow links
individual files so shared and per-machine configuration can coexist.

```sh
stow --no-folding --simulate --verbose --target="$HOME" fish
stow --no-folding --verbose --target="$HOME" fish
```

Back up and move conflicting shared files aside before applying. Keep these local:

- `conf.d/99-*.fish`, including this machine's `99-local.fish`
- Optional `conf.d/00-local.fish` for early PATH setup
- `fish_variables` (universal variables), completions, and generated state

Git and Stow both exclude these paths. Local snippets are automatically loaded
by Fish before `config.fish`; do not source them manually. Each machine keeps
its own snippet. `docs/fish-local.fish.example` is a starting point, not a managed
file: copy it to `~/.config/fish/conf.d/99-local.fish` only if that file does not
already exist, or merge the example into the existing local file.

`10-interactive-tools.fish` initializes fzf and zoxide only in interactive shells
and when each tool is available. `fzf --fish` installs its own keybindings; do not
also source a package-specific fzf script or add a duplicate
`functions/fish_user_key_bindings.fish` just to call `fzf_key_bindings`.
The duplicate keybinding file is excluded too; back up or remove an old local
copy on another machine if it contains only that redundant setup. Use a recent
fzf with `--fish` support (0.48.0 or newer).

Tools must be on PATH before `10-interactive-tools.fish` executes. If a machine
needs explicit PATH setup, put it in the optional local `00-local.fish`, not in
the later `99-local.fish`. Neither local snippet is required on a fresh install.

Install optional tools separately: fzf and zoxide for interactive integration;
eza for the listing abbreviations; llm, npm, yazi, Docker Compose, and yq v4 for
the corresponding helpers. `unquarantine` is macOS-specific. These helpers are
preserved as-is and only run when invoked. History, secrets, and downloaded tools
are not synced.

Edit existing linked files normally. Add new shared files in
`fish/.config/fish/` and rerun Stow on each machine; files created directly in
the live directory are not automatically imported. Open a new Fish shell to
load startup changes; sourcing `config.fish` alone does not reload `conf.d`.

## Sync

Edit the installed configuration normally: the symlinks point into this repo.
Review changes, then commit and push explicitly. On another machine:

```sh
git pull --ff-only
stow --no-folding --verbose --target="$HOME" kitty tmux git fish
mkdir -p "$HOME/.config/opencode"
stow --verbose --target="$HOME" opencode
mkdir -p "$HOME/.agents"
stow --verbose --target="$HOME" agents
mkdir -p "$HOME/.config/zed"
stow --verbose --target="$HOME" zed
```

Pulling updates existing linked files; rerunning Stow creates links for new ones.
Before pulling a change that removes managed files, unstow the old package first
to avoid dangling links, then pull and stow again.

## Unlink

```sh
stow --no-folding --delete --target="$HOME" opencode agents kitty tmux zed git fish
```

This removes managed symlinks, not repository files or unrelated configuration.
