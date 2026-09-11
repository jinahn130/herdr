---
name: herdr-personal-setup
description: Maintain Jin's customized Herdr setup across upstream Herdr, Codex CLI, Claude Code, iTerm2, and Windows updates. Use when changing or repairing Jin's Herdr hotkeys, helper commands, agent lifecycle detection, colors, scrollback, pane behavior, model launchers, Windows mappings, or when upgrading Herdr/Codex/Claude without losing customizations or live agents.
---

# Jin's Herdr setup

Use this skill only for Jin's personal Herdr fork and installed setup. Herdr's
installed binary remains the authority for current CLI syntax; read the main
`herdr` skill as well for safe control of live panes and agents.

## Start with a read-only audit

Run:

```bash
.agents/skills/herdr-personal-setup/scripts/audit.sh
```

Do not repair anything until the audit distinguishes these layers:

1. upstream or forked Herdr source
2. `~/.config/herdr/config.toml`
3. helper commands under `~/.local/bin`
4. iTerm2 key translation and shell initialization
5. Codex/Claude CLI behavior and Herdr integrations

Never assume an upstream update replaced every layer. Never replace the config
or helper directory wholesale to fix one binding.

## Route by task

- Read `references/hotkey-contract.md` before changing a shortcut or diagnosing
  a key that does nothing.
- Read `references/customization-map.md` before changing source patches, helper
  scripts, rendering, per-pane done acknowledgement, agent launch behavior, or
  Windows support.
- Read `references/update-runbook.md` before upgrading Herdr, Codex, Claude, or
  an integration, and before replacing the installed Herdr binary.
- On the corporate Windows computer, read `custom/windows/AGENT-HANDOFF.md`
  from the repository root before installing, validating, or porting controls.

## Non-negotiable safety rules

- Preserve all live pane PTYs and resumable agent contexts. Record the exact
  agent inventory before any binary or server action.
- Do not stop the Herdr server or restart the agent fleet merely to refresh the
  client, theme, or key configuration.
- Preserve `~/.config/herdr/config.toml` and every helper it references.
- Keep the right Option key available for Fluid voice input. Personal Herdr
  shortcuts use the left Option key on macOS.
- Keep Codex launches in full-access mode with `--no-alt-screen`; keep Claude
  launches in skip-permissions mode because that is the user's established
  workflow.
- Do not print full process environments. Inspect only named, safe variables.
- Treat the dirty worktree as user-owned. Do not discard or overwrite local
  source changes while rebasing or updating.
- Prefer upstream configuration and integration hooks when they cover the
  desired behavior. Keep machine-specific orchestration in helpers and config.

## Definition of done

After a change, validate only the affected layer plus these baselines:

```bash
herdr config check
herdr status server --json
herdr integration status
```

Confirm the live agent count and exact pane/session identities match the
pre-change inventory. For key changes, test the terminal-emitted sequence as
well as the Herdr mapping. For detection changes, add captured-screen tests and
run the focused manifest test set before installing a new manifest or binary.
