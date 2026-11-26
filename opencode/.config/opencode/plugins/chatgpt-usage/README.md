# ChatGPT usage

Global OpenCode plugin that shows the remaining weekly ChatGPT Work/Codex
allowance and its reset day in the home and prompt footers.

Example:

```text
24% left ↻Mon
```

The server part owns one shared `codex app-server` process and polls it every
60 seconds. Plugin instances for additional OpenCode locations share that
monitor, while each TUI receives updates over plugin RPC.

## Requirements

Install the Codex CLI and sign in with the same ChatGPT account used by
OpenCode:

```sh
codex login
```

The plugin also checks common MacPorts, Homebrew, and user-local install
locations. For a custom location, set `CODEX_BIN` to the executable's absolute
path in the environment that starts the OpenCode service.

Until Codex is installed and authenticated, the footer reads:

```text
ChatGPT usage unavailable
```

Use `/usage-refresh` or **Refresh ChatGPT usage** in the command palette to
refresh immediately. A trailing `!` means the refresh failed and the footer is
showing the last successful reading. If Codex reports a revoked token, the
plugin reconnects once to pick up the current credentials. If your Codex login
is no longer valid, run `codex login` again.
