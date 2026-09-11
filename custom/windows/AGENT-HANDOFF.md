# Handoff for the Windows setup agent

## Objective

Install and validate Jin's Herdr workflow controls on the corporate Windows
computer. Synchronize controls and behavior only. Do not copy or synchronize
Herdr state, Codex/Claude contexts, credentials, transcripts, worktrees, or
project data from the Mac.

The public source is `https://github.com/jinahn130/herdr.git`. The personal
workflow branch is `personal-windows`. The macOS implementation under
`custom/macos/` is the behavioral reference; `custom/windows/` is the native
PowerShell implementation.

## Safety and platform constraints

- Work in native PowerShell and Windows Terminal, not WSL.
- Use the left Alt key. Do not bind the Windows key or assume right Alt is safe;
  right Alt can be AltGr.
- Do not weaken corporate endpoint, PowerShell execution, proxy, or GitHub
  policies. If policy blocks an action, report the exact blocker.
- Back up `%APPDATA%\herdr\config.toml` before replacing it.
- Do not delete or restart running agents merely to test a key.
- Never commit `%APPDATA%`, provider state, credentials, session IDs, or
  captured private transcripts.
- Preserve the packaged ConPTY files beside `herdr.exe`; do not copy only the
  executable out of a Windows artifact.

## First installation

```powershell
git clone https://github.com/jinahn130/herdr.git
Set-Location herdr
git checkout personal-windows
powershell -NoProfile -ExecutionPolicy Bypass -File .\custom\windows\Install-HerdrCustomization.ps1 -ApplyConfig
herdr config check
herdr server reload-config
```

If Herdr is not installed, follow `custom/windows/HANDOFF.md` first. Codex and
Claude must be installed and authenticated locally; their authentication is
not part of this repository.

## Required Windows behavior

| Action | Windows key | macOS reference |
| --- | --- | --- |
| Rename focused agent | Alt+R or Ctrl+L | Ctrl+Option+A or Cmd+L |
| Fork exact context right | Alt+F | Option+F |
| Move focused pane to a chosen tab | Alt+T | Option+T |
| Show prompt history | Ctrl+. | Cmd+. or Option+L |
| Agent 1-9 | Alt+1..9 | Option+1..9 |
| Workspace 1-9 | Alt+Shift+1..9 | Option+Shift+1..9 |
| Tab 1-9 | Ctrl+Alt+1..9 | Cmd+Shift+1..9 |
| Previous/next tab | Alt+- / Alt++ | Option+- / Option++ |

Do not copy Mac key strings into the Windows config. Keep the same actions and
use native Windows chords and PowerShell helpers.

## Validation sequence

1. Record `herdr --version`, `codex --version`, `claude --version`, and
   `herdr agent list` before changing anything.
2. Run the installer and `herdr config check`. Treat every diagnostic as a
   real failure until explained.
3. In a disposable repository, start one local Codex agent and send a harmless
   prompt so it has a registered session.
4. Verify Alt+R and Ctrl+L rename it; Escape must cancel without renaming.
5. Verify Alt+F creates a right pane with the same provider conversation while
   preserving the original pane.
6. Verify Alt+T moves that pane to an existing tab and can create a named tab.
7. Verify Ctrl+. opens multiline prompt history and Escape closes it.
8. Verify agent, workspace, and tab number bindings on the actual keyboard.
9. Close Windows Terminal, reopen it, run `herdr`, and verify Herdr persistence.
10. Compare the final agent inventory with the initial inventory and document
    any intentional disposable agent created during testing.

## Work still expected on Windows

The high-frequency rename, fork, move, prompt-history, and navigation controls
are implemented. The following Mac controls are not yet safely ported and can
be added on the Windows machine when needed:

- fresh Codex/Claude launchers and the Claude model chooser
- delete pane plus exact provider context
- manual BACKLOG status
- isolated worktree context fork
- directional pane layout and incremental resizing
- Codex saved-title synchronization after Herdr rename
- Codex fast-mode toggle

Port behavior from `custom/macos/bin/`, but do not translate shell syntax
literally. Use Herdr's installed Windows CLI help as the authority and implement
filesystem/process operations with strict PowerShell target validation.

## Sending fixes back

Before editing:

```powershell
git fetch origin
git checkout personal-windows
git pull --ff-only origin personal-windows
git status --short
```

Keep Windows changes under `custom/windows/` unless a cross-platform Herdr
source fix is genuinely required. Validate, commit only intended files, and
push:

```powershell
git add custom/windows
git commit -m "fix: refine portable Windows Herdr controls"
git push origin personal-windows
```

On the Mac, pull that branch and rerun the macOS installer only when macOS
files also changed. No GitHub Actions or automatic machine deployment is
required; Git is the synchronization mechanism.
