# Windows Herdr customization handoff

For an AI agent performing the actual corporate-Windows installation and
validation, begin with `AGENT-HANDOFF.md`. This document remains the detailed
platform reference.

This directory is a Windows-only port of the high-frequency Herdr workflow used
on macOS. Nothing here activates on macOS. The installer refuses to run unless
`OS=Windows_NT`, and Herdr only reads the template after it is copied to
`%APPDATA%\herdr\config.toml`.

## Intended keyboard model

The Windows keyboard is laid out as `Fn, Ctrl, Windows, Alt, Space, Alt, PrtSc,
Ctrl`. Do not use the Windows key for Herdr: Windows reserves important chords
such as Win+L, Win+D, and Win+1..9.

Use the **left Alt** key for these bindings. On non-US keyboard layouts, right
Alt may be reported as AltGr (Ctrl+Alt), so test the numbered agent, workspace,
and tab bindings before relying on them.

| Purpose | Windows key | macOS equivalent |
| --- | --- | --- |
| Rename focused agent | Alt+R or Ctrl+L | Option shortcut or Cmd+L |
| Fork current context right | Alt+F | Option+F |
| Move current pane to a chosen tab | Alt+T | Option+T |
| Show sent-prompt history | Ctrl+. | Cmd+. |
| Select agent 1-9 | Alt+1..9 | Option+1..9 |
| Select workspace 1-9 | Alt+Shift+1..9 | Option+Shift+1..9 |
| Select tab 1-9 | Ctrl+Alt+1..9 | Cmd+Shift+1..9 |
| Previous/next tab | Alt+- / Alt++ | Option+- / Option++ |

Alt+R replaces the default direct resize shortcut on Windows. Resize mode is
still available as Ctrl+Alt+R or `prefix`, then `r`. Ctrl+L intentionally stops
being terminal clear-screen because it is the requested duplicate rename key.
Alt+, and Alt+. remain untouched because Codex uses them to change reasoning
effort.

## Installation on the Windows computer

1. Install native Herdr in PowerShell:

   ```powershell
   powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"
   ```

2. Clone the public fork, check out the customization branch, and enter the
   checkout:

   ```powershell
   git clone https://github.com/jinahn130/herdr.git
   cd herdr
   git checkout personal-windows
   ```

3. Install the helper scripts without changing any existing Herdr config:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\custom\windows\Install-HerdrCustomization.ps1
   ```

4. Review `custom\windows\config.windows.toml`. On a fresh setup, install it:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\custom\windows\Install-HerdrCustomization.ps1 -ApplyConfig
   herdr server reload-config
   ```

   `-ApplyConfig` creates a timestamped backup before replacing an existing
   `%APPDATA%\herdr\config.toml`.

5. Launch Herdr from the repository you want to manage. Codex and Claude must
   already be installed and authenticated on that computer.

The official installer is sufficient for the Windows key mappings and helper
scripts. The fork's source-level `done_acknowledgement = "pane"` and inherited
`NO_COLOR` protections require a Windows binary built from this fork; an
official Herdr release does not contain those local changes. Until that custom
binary is installed, remove `done_acknowledgement = "pane"` if `herdr config
check` reports it as unknown.

For a complete custom Windows package, enable Actions in the fork and run the
repository's **Build Artifacts (Manual)** workflow on the `personal-windows` branch for
`x86_64-pc-windows-msvc`. Download the resulting Windows ZIP artifact and keep
its directory intact. A future agent building locally should follow the same
workflow and `scripts\package_windows_conpty.ps1`; do not copy only
`target\release\herdr.exe`, because the Windows package includes an app-local
ConPTY runtime.

## Terminology and operating model

- **Session**: the persistent Herdr server state. Closing Windows Terminal does
  not stop it; run `herdr` again to reconnect.
- **Workspace / space**: one project checkout, including a Git worktree.
- **Tab**: a layout page inside a workspace.
- **Pane**: one terminal rectangle inside a tab.
- **Agent**: Codex or Claude running inside a pane. An agent context is the
  model's resumable conversation and is separate from the pane.
- **Worktree**: a second physical checkout of the same Git repository on a
  different branch. The separate directory is required so both branches can be
  open and edited at the same time.

Use multiple panes in one workspace when agents should see the same files and
branch immediately. Use a worktree when changes need isolation; commit in the
worktree, then merge or cherry-pick that branch into the main checkout.

## What is implemented

- Alt+R and Ctrl+L rename the Herdr agent label. The existing value is editable;
  Escape cancels. A rename requested during a fresh fork waits for Herdr's
  launch registration to finish.
- Alt+F forks the exact focused Codex or Claude context into a right-hand pane.
  Codex starts with `--no-alt-screen` and full-access mode. Claude starts with
  its skip-permissions flag. Its small progress popup closes automatically on
  success and keeps an actionable error visible on failure.
- Alt+T shows tabs 1-9, moves the focused pane to one, or creates a named tab.
  It re-reports a known agent session after the move so context-sensitive
  lifecycle commands keep working.
- Ctrl+. shows the ten newest prompts for the focused Codex or Claude session.
- The config keeps per-pane done acknowledgement, Catppuccin chrome, pane
  scrollbars, and a large scrollback budget.

This fork also carries two source-level customizations that apply after building
the fork: completed panes can remain marked done until that individual pane is
focused, and pane/server launch boundaries remove an inherited `NO_COLOR` so
Codex can emit its normal colored terminal UI.

## Important platform facts

- Use native PowerShell/Windows Terminal, not WSL, for this port.
- Herdr custom command strings run through `cmd.exe /d /c`; each mapping
  therefore invokes `powershell.exe` explicitly and uses `%APPDATA%` paths.
- Native Windows Herdr uses ConPTY. Its release ZIP must keep `herdr.exe` beside
  the app-local ConPTY runtime; do not copy only the executable.
- Windows can attach remotely to Linux, macOS, or Windows hosts. A Windows host
  must already have a compatible Herdr package with remote-host support on
  `PATH`; remote attach does not install or update it.
- Windows updates do not support Unix-style live handoff. Existing compatible
  servers and panes can remain alive, but a server restart is needed before
  server-side changes in a new binary take effect.

## Validation checklist for the next agent

Run this on the actual corporate Windows computer; the PowerShell helpers cannot
be fully exercised from macOS.

1. Confirm `herdr --version`, `codex --version`, and `claude --version` as
   applicable.
2. Run `herdr server reload-config` and inspect diagnostics. No custom key may
   be reported as invalid or conflicting.
3. Create a disposable project and start one Codex pane. Send one harmless
   prompt so Codex registers a real session ID.
4. Verify Alt+R and Ctrl+L both rename. Verify Escape cancels without changing
   the label.
5. Verify Alt+F creates a right pane with the same conversation history and that
   the original pane stays intact.
6. Verify Alt+T can move that pane to an existing tab and to a newly named tab.
7. Verify Ctrl+. shows multiline prompts and closes with Enter or Escape.
8. Close Windows Terminal, reopen it, run `herdr`, and confirm all panes and
   agent processes survived.
9. If building this fork, run `just check` on a supported development host and
   the repository's Windows CI before trusting a Windows artifact.

When validating against an official binary rather than a custom build, remove
the fork-only `ui.done_acknowledgement` line before step 2 if that version
reports the setting as unknown. Do not ignore other config diagnostics.

## Known gaps / next work

- Renaming currently changes the Herdr label only. The macOS setup also syncs a
  Codex saved-chat title through a local helper; that helper depends on Codex's
  local SQLite layout and has not been ported safely to Windows.
- Prompt history is a readable popup, not the richer curses selector used on
  macOS. It intentionally avoids Unix-only `curses`, `pbcopy`, `jq`, `rg`, and
  shell assumptions.
- Fresh-agent launch, delete-agent-plus-context, backlog tagging, worktree fork,
  directional rearrange, and fast-mode helpers remain future ports. Do not copy
  the macOS scripts verbatim; they contain Unix process and filesystem logic.
- Corporate endpoint policy may block PowerShell execution or GitHub downloads.
  Do not weaken corporate policy. Use an approved execution policy, signed
  script path, or internal distribution method supplied by the administrator.

## Upgrade-safe workflow

Keep `herdrdev/herdr` as the `upstream` remote and this fork as `origin`. Put
personal Windows helpers under `custom/windows/`; upstream normally does not
touch that directory. To update:

```powershell
git fetch upstream
git checkout personal-windows
git rebase upstream/master
```

Resolve source conflicts carefully, rerun validation, and reinstall the helper
scripts. Never replace `%APPDATA%\herdr\config.toml` during an update without
keeping its backup.

Git is the manual synchronization mechanism; this setup intentionally has no
automatic GitHub Actions deployment. After pulling a workflow update, rerun
`Install-HerdrCustomization.ps1` to refresh helpers. Add `-ApplyConfig` only
when the tracked Windows key map changed and its diff has been reviewed.
