# Customization map

## Runtime files on Jin's Mac

- Herdr binary: `~/.local/bin/herdr`
- Previous known backup: `~/.local/bin/herdr-backup-0.8.2-20260910`
- Herdr config: `~/.config/herdr/config.toml`
- Personal helper commands: `~/.local/bin/herdr-*`
- Shell aliases and workflow help: `~/.zshrc`
- Codex config and integration: `~/.codex/config.toml`,
  `~/.codex/herdr-agent-state.sh`
- Claude integration: `~/.claude/hooks/herdr-agent-state.sh`

Portable copies of the macOS workflow helpers and key map live under
`custom/macos/`. Runtime files remain authoritative for the currently attached
server; update the portable copies deliberately before committing rather than
copying state or provider data into the repository.

The config currently uses Catppuccin, mouse capture, pane scrollbars, six-line
mouse scroll, 50 MB scrollback, and `done_acknowledgement = "pane"`.

Every personal `[[keys.command]]` command pins
`HERDR_BIN_PATH=~/.local/bin/herdr`. This is deliberate: a live handoff can
leave the server running from a versioned path that is later removed, while the
stable installed path remains valid. Do not remove this pin unless Herdr itself
has gained an equivalent stale-executable fallback.

## Helper responsibilities

- `herdr-add-codex`: splits right when necessary and starts full-access Codex
  with `--no-alt-screen`.
- `herdr-add-claude`: chooses Fable, Opus, Sonnet, or Haiku and starts Claude
  with skipped permissions.
- `herdr-fork-agent`: resolves the exact Codex/Claude session, creates a pane or
  tab, forks/resumes the provider context, and re-registers Codex child IDs.
- `herdr-fork-codex-to-claude`: writes a sanitized recent-message handoff and
  starts Claude Fable in a right pane.
- `herdr-move-pane-next-tab`: chooses an existing tab or creates a named one,
  then re-reports provider session identity after the move.
- `herdr-rename-agent`: edits the current label, accepts `_` and `-`, handles a
  fork still registering, and synchronizes Codex's saved title when possible.
- `herdr-delete-codex-context`: closes the exact pane and deletes the exact
  Codex or Claude stored context; a never-started Codex fork has no stored
  context and only its verified pane is closed.
- `herdr-toggle-last-prompt`, `herdr-prompt-history`, and
  `herdr-prompt-viewer`: display recent sent prompts in a closable popup.
- `herdr-arrange-pane`, `herdr-reflow-panes`, and `herdr-size-pane`: implement
  predictable side-by-side/bottom layouts and incremental resizing.
- `herdr-toggle-backlog`: applies the manual `$backlog` sidebar tag.
- `herdr-toggle-codex-fast`: toggles Codex fast mode in an idle focused pane.
- `herdr-resolve-agent-session`: resolves a provider session from verified
  Herdr metadata and provider evidence. Lifecycle helpers depend on this.

Do not rewrite these helpers from memory. Read the installed script before
changing its behavior and keep provider-session validation strict.

## Shell conveniences

`~/.zshrc` defines:

- `h`: attach/reconnect to Herdr
- `hp [path] [label]`: create and focus a workspace
- `hhelps`: print the personal cheat sheet
- `hsame`: explain two agents in one checkout
- `hseparate`: explain isolated worktrees
- `hmerge`: explain merge and cleanup

Interactive shells unset inherited `NO_COLOR` so Herdr and agents retain ANSI
themes. iTerm2 owns its tmux control-mode launch; the shell must not auto-start
another tmux session.

## Source-level patches

These are the local behaviors most likely to need conflict review after an
upstream update:

- `src/pane.rs`: remove inherited `NO_COLOR` when starting pane commands.
- `src/server/handoff.rs`: remove inherited `NO_COLOR` across server handoff.
- UI done acknowledgement: `done_acknowledgement = "pane"` means a completed
  agent loses its done indicator only when that pane is focused, not merely
  because another pane in the same tab/window was opened.
- `src/detect/manifests/claude.toml` and
  `distribution/agent-detection/claude.toml`: Claude lifecycle detection for
  current OSC titles and `thinking ...` status text, plus delayed confirmation
  of the visible empty prompt.
- `src/detect/manifest/tests.rs`: captured-screen regression tests for the
  Claude detection cases above.

Keep both Claude manifest copies synchronized. Increment the manifest version
when changing shipped detection behavior. Install/update the Claude integration
after validating a manifest change.

## Windows source of truth

`custom/windows/` contains the Windows-only configuration, PowerShell helpers,
installer, and full handoff. The installer refuses to run on macOS. Windows
still requires validation on the actual corporate machine; do not claim the
PowerShell helpers are qualified from macOS alone.

`custom/windows/AGENT-HANDOFF.md` is the starting document for the Windows
agent. Git pull/push is the synchronization mechanism; no automatic deployment
workflow is required.

## What should remain outside source

Machine-specific absolute paths and key choices belong in config/helpers, not
generic Herdr defaults. Provider credentials, complete process environments,
Codex/Claude transcripts, and Herdr state databases must never be committed.
