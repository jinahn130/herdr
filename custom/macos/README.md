# macOS Herdr workflow controls

This directory is the portable source for Jin's macOS workflow controls. It
contains no Herdr state, Codex or Claude contexts, credentials, project paths,
or transcripts.

## Install or update

From the repository root:

```sh
./custom/macos/Install-HerdrCustomization.sh
```

That updates only the helper commands under `~/.local/bin`. On a new Mac, or
after reviewing the tracked config template, install the complete key map:

```sh
./custom/macos/Install-HerdrCustomization.sh --apply-config
```

The installer backs up an existing config before replacing it, validates the
new config, and live-reloads a running compatible Herdr server. It does not
restart or replace any agent.

Required command-line tools are `herdr`, `jq`, `rg`, `sqlite3`, `python3`, and
`zsh`; `codex` and `claude` are required for their respective agent actions.

## Guaranteed long-running agents

Install the optional sleep guard once:

```sh
./custom/macos/Install-HerdrSleepGuard.sh
```

The user launch agent checks Herdr every 15 seconds without touching its panes.
Whenever a Codex or Claude agent reports `working`, it holds a macOS
`caffeinate -i` assertion and keeps it for ten minutes after the final working
state. Screen savers, screen locking, and display sleep still work. Idle system
sleep is prevented, including on battery; closing the laptop lid, power loss, and network
failure remain outside its control.

## iTerm2 input contract

Herdr runs inside iTerm2 on macOS:

- Left Option sends `Esc+` and is used for Herdr shortcuts.
- Right Option remains normal and is reserved for Fluid voice input.
- Cmd+L sends `Esc`, then Control-A, which Herdr receives as
  `Ctrl+Option+A` for rename.
- Cmd+. sends `Esc`, then `l`, which Herdr receives as Option+L for prompt
  history.
- Cmd+Shift+1 through Cmd+Shift+9 use the existing CSI-u translations for tab
  selection.
- Ctrl+Option+Shift+F and Cmd+Option+Shift+F use exact iTerm2 key mappings that
  send CSI-u `102:70;8u` and `102:70;12u`, respectively. They keep the transfer
  chooser available in both Codex and Claude without enabling report-all
  keyboard mode. Do not solve these chords by globally enabling report-all:
  that captures standalone Right Option and breaks Fluid voice input.

iTerm2 owns those translations. They are documented rather than installed
automatically because overwriting a profile's keyboard map could damage other
terminal shortcuts.

To install only the two transfer chords in the Default and Codex Cheatsheet
profiles, quit iTerm2 (leave the Herdr server running), then run from another
terminal:

```sh
./custom/macos/Install-iTermTransferKey.sh
```

The opt-in installer preserves every other mapping and both Option settings,
creates a private preference backup, and refuses to edit while iTerm2 is
running. Use `--check` for a read-only check while iTerm2 is open. Reopen iTerm2
and run `h` afterward; the existing agent PTYs remain intact.

## Manual synchronization

Pull the personal branch and rerun the installer:

```sh
git pull --ff-only origin personal-windows
./custom/macos/Install-HerdrCustomization.sh
```

Use `--apply-config` only when the tracked key map changed and you have reviewed
the diff. Runtime state remains local to each computer.
