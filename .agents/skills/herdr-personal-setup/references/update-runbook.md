# Upgrade and recovery runbook

Use this for Herdr, Codex CLI, Claude Code, and integration updates.

## 1. Snapshot before touching anything

Run the personal audit and save a private temporary copy of:

```bash
herdr --version
codex --version
claude --version
herdr status server --json
herdr agent list
herdr integration status
herdr config check
git status --short
git branch --show-current
git log -1 --oneline
```

For every live agent preserve pane ID, workspace/tab IDs, name, kind, state,
provider session ID, PID, and cwd. Do not commit that inventory because it may
contain private project and session identifiers.

Back up the installed Herdr binary with a versioned timestamped name. Preserve
the config and helpers independently of the binary.

## 2. Classify the update

- A Codex/Claude CLI update can change terminal rendering, OSC titles, prompt
  frames, session creation timing, or local transcript storage without changing
  Herdr itself.
- A Herdr update can change CLI syntax, config schema, integration versions,
  detection manifests, protocol versions, or source-patch context.
- An integration update changes agent state/session reporting and must be
  installed separately from copying the Herdr binary.
- iTerm2 changes can alter emitted key sequences while Herdr config remains
  correct.

Do not fix one layer by blindly resetting another.

## 3. Update the fork carefully

Keep `herdrdev/herdr` as `upstream` and the personal fork as `origin`. Fetch
first, inspect the branch and dirty tree, then rebase or merge only with the
user's current branch policy. Never discard local edits.

Conflict-review the files listed in `customization-map.md`. In particular,
re-check `NO_COLOR`, done acknowledgement, both Claude manifests, and their
tests. Personal helpers under `~/.local/bin` and the live config are not updated
by Git directly and must be audited separately. The portable macOS source lives
under `custom/macos/`; install it explicitly after reviewing changes.

## 4. Build and validate before installation

Use the repository's declared toolchain and normal checks. At minimum:

```bash
cargo fmt --check
cargo test detect::manifest::tests
herdr config check
```

Use broader repository checks when source changes are not confined to a
manifest. For lifecycle detection, test captured terminal states for working,
idle, blocked, and done; do not accept a visual watch as the only regression
test.

## 5. Install without losing agents

Prefer Herdr's supported live handoff on macOS when replacing the custom
binary. Do not stop the server first. Re-check the installed path and version,
server compatibility, stale-binary flag, and exact agent inventory afterward.
Run the replacement server from the permanent `~/.local/bin/herdr` path, not a
temporary versioned build path that will be deleted. Personal custom commands
also pin `HERDR_BIN_PATH` to that permanent path so a stale live-server
executable name cannot break every helper at once.

Run the installed binary's integration status. Install only integrations for
providers actually used, then verify they report `current`. A binary update and
an integration update are separate operations.

Windows does not use Unix live handoff; follow `custom/windows/HANDOFF.md` and
preserve the complete ConPTY package.

## 6. Regression matrix

Test on disposable or settled panes:

- attach/reconnect without losing agents
- fresh Codex and Claude launch
- exact same-provider fork
- rename immediately after a fork and again after the first prompt
- move pane to existing and new tabs, then rename/delete it
- delete a stored context and a never-started fork safely
- last-prompt popup open, toggle-close, and Escape-close
- agent/workspace/tab navigation bindings
- mouse scroll, keyboard scroll/read mode, and pane resize/reflow
- Catppuccin chrome plus Codex ANSI color output
- per-pane done acknowledgement in a multi-pane tab
- Claude working-to-idle transition without done/idle cycling

When a shortcut fails, test the terminal-emitted sequence before changing the
Herdr key table.

## 7. Recovery rule

If a new binary or integration regresses behavior, keep the live server and
PTYs intact when protocol compatibility allows. Restore the last known binary
or manifest through supported handoff/install mechanisms, then re-run the audit.
Never mass-restart the agent fleet as a shortcut.
