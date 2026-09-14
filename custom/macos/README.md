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
- Ctrl+Option+Shift+F must use one exact iTerm2 key mapping that sends the hex
  codes `0x1b 0x5b 0x31 0x30 0x32 0x3a 0x37 0x30 0x3b 0x38 0x75`. This is the
  CSI-u encoding of Ctrl+Alt+Shift+F and keeps the transfer chooser available
  in both Codex and Claude without enabling report-all keyboard mode. Do not
  solve this chord by globally enabling report-all: that captures standalone
  Right Option and breaks Fluid voice input.

iTerm2 owns those translations. They are documented rather than installed
automatically because overwriting a profile's keyboard map could damage other
terminal shortcuts.

## Manual synchronization

Pull the personal branch and rerun the installer:

```sh
git pull --ff-only origin personal-windows
./custom/macos/Install-HerdrCustomization.sh
```

Use `--apply-config` only when the tracked key map changed and you have reviewed
the diff. Runtime state remains local to each computer.
