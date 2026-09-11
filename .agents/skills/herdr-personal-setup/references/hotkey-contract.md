# Personal hotkey contract

This file documents the intended shortcuts. The live config at
`~/.config/herdr/config.toml` is the runtime source of truth.

## macOS operating model

- Herdr runs inside iTerm2.
- Left Option is configured as `Esc+` and is the Herdr modifier.
- Right Option is reserved for Fluid voice input. Do not map or globally
  reinterpret it for Herdr.
- A binding written as `cmd+...` in Herdr works only if iTerm2 actually emits a
  sequence Herdr recognizes. When `Cmd+L` or `Cmd+.` fails, inspect iTerm2's
  profile key mapping before editing Herdr.
- `Ctrl-B, then ...` remains the native fallback even when a direct shortcut is
  present.

## Navigation

| Action | macOS shortcut |
| --- | --- |
| Focus agent 1-9 | Left Option+1..9 |
| Focus space/workspace 1-9 | Left Option+Shift+1..9 |
| Focus tab 1-9 | Cmd+Shift+1..9 |
| Previous/next tab | Left Option+- / Left Option++ |
| Previous/next workspace | Left Option+P / Left Option+N |
| Choose destination tab for focused pane | Left Option+T |

## Agent lifecycle

| Action | macOS shortcut | Helper or Herdr action |
| --- | --- | --- |
| Fresh Codex | Left Option+A | `herdr-add-codex` |
| Fresh Claude/model chooser | Left Option+C | `herdr-add-claude` |
| Fork exact focused context right | Left Option+F | `herdr-fork-agent right` |
| Choose right/bottom fork | Ctrl+Option+F | `herdr-fork-direction` |
| Semantic Codex-to-Claude transfer | Ctrl+Option+Shift+F | `herdr-fork-codex-to-claude` |
| Fork into isolated worktree | Left Option+Shift+F | `herdr-fork-worktree-codex` |
| Resume existing Codex context | Left Option+E | `herdr-open-codex-context resume` |
| Fork existing Codex context | Left Option+Shift+E | `herdr-open-codex-context fork` |
| Delete stored context and pane | Left Option+D | `herdr-delete-codex-context` |
| Rename focused agent/chat | Ctrl+Option+A or Cmd+L | `herdr-rename-agent` |
| Toggle BACKLOG | Left Option+B | `herdr-toggle-backlog` |

`Left Option+F` is a true provider-context fork for Codex or Claude. The
Codex-to-Claude command cannot clone provider-private context; it creates a
sanitized recent-message handoff and starts Claude Fable with the filesystem as
authority.

## Reading and layout

| Action | macOS shortcut |
| --- | --- |
| Last sent prompts | Left Option+L or Cmd+. |
| Full agent history | Left Option+H |
| Scroll/read mode | Left Option+S |
| Resize mode | Left Option+R |
| Grow/shrink width | Left Option+Shift+Right / Left |
| Grow/shrink height | Left Option+Shift+Down / Up |
| Move focused pane left/right | Ctrl+Option+Shift+Left / Right |
| Stack focused pane across bottom | Ctrl+Option+Shift+Down |
| Restore side-by-side row | Ctrl+Option+Shift+Up |

The last-prompt popup must close with the same toggle or Escape. A popup that
captures literal escape characters is a helper/viewer bug, not a Codex problem.

## Key troubleshooting order

1. Confirm the focused iTerm2 profile and left/right Option behavior.
2. Confirm what bytes iTerm2 sends for the chord. Do not infer this from the
   printed key label.
3. Run `herdr config check` and inspect the live mapping.
4. Confirm the configured helper exists and is executable.
5. Invoke the helper directly with captured `HERDR_*` IDs only in a disposable
   or explicitly targeted pane.
6. Change source code only when config and helper boundaries cannot implement
   the behavior.

## Windows mapping

The Windows port lives under `custom/windows/`. Its intended high-frequency
mapping is:

| Action | Windows shortcut |
| --- | --- |
| Rename | Alt+R or Ctrl+L |
| Fork | Alt+F |
| Move pane | Alt+T |
| Last prompts | Ctrl+. |
| Agent 1-9 | Alt+1..9 |
| Workspace 1-9 | Alt+Shift+1..9 |
| Tab 1-9 | Ctrl+Alt+1..9 |

Use left Alt. Do not use the Windows key for Herdr. See
`custom/windows/HANDOFF.md` for installation, limitations, and validation.
