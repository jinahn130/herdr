#!/bin/sh
set -u

config_path="${HERDR_CONFIG_PATH:-$HOME/.config/herdr/config.toml}"
helper_root="${HERDR_HELPER_ROOT:-$HOME/.local/bin}"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../../../.." && pwd -P)
portable_mac_root="$repo_root/custom/macos"
failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

printf '%s\n' "JIN HERDR PERSONAL SETUP AUDIT"
printf '%s\n' "repo: $repo_root"

if command -v herdr >/dev/null 2>&1; then
  pass "herdr found at $(command -v herdr) ($(herdr --version 2>/dev/null || printf unknown))"
else
  fail "herdr is not on PATH"
fi

if [ -f "$config_path" ]; then
  pass "config exists at $config_path"
else
  fail "config is missing at $config_path"
fi

if command -v herdr >/dev/null 2>&1; then
  if herdr config check >/dev/null 2>&1; then
    pass "herdr config check"
  else
    fail "herdr config check"
  fi

  if server_json=$(herdr status server --json 2>/dev/null) &&
    printf '%s' "$server_json" | jq -e '.running == true and .compatible == true' >/dev/null 2>&1; then
    server_version=$(printf '%s' "$server_json" | jq -r '.version // "unknown"')
    pass "compatible Herdr server is running ($server_version)"
  else
    warn "Herdr server is not running or not compatible"
  fi

  integration_status=$(herdr integration status 2>/dev/null || true)
  for provider in codex claude; do
    if printf '%s\n' "$integration_status" | grep -Eq "^${provider}: current "; then
      pass "$provider integration is current"
    else
      warn "$provider integration is not reported current"
    fi
  done

  if agent_json=$(herdr agent list 2>/dev/null); then
    agent_count=$(printf '%s' "$agent_json" | jq -r '.result.agents | length' 2>/dev/null || printf '?')
    codex_count=$(printf '%s' "$agent_json" | jq -r '[.result.agents[] | select(.agent == "codex")] | length' 2>/dev/null || printf '?')
    claude_count=$(printf '%s' "$agent_json" | jq -r '[.result.agents[] | select(.agent == "claude")] | length' 2>/dev/null || printf '?')
    pass "live agent inventory readable: $agent_count total ($codex_count Codex, $claude_count Claude)"
  else
    warn "live agent inventory is unavailable"
  fi
fi

if [ -f "$config_path" ]; then
  for expected in \
    'key = "cmd+l"' \
    'key = "cmd+period"' \
    'key = "alt+f"' \
    'key = "ctrl+alt+shift+f"' \
    'done_acknowledgement = "pane"' \
    'name = "catppuccin"'; do
    if grep -Fq "$expected" "$config_path"; then
      pass "config contains $expected"
    else
      warn "config does not contain $expected"
    fi
  done

  commands_file=$(mktemp "${TMPDIR:-/tmp}/herdr-personal-audit-commands.XXXXXX")
  sed -n 's/^command = "\([^\"]*\)"$/\1/p' "$config_path" >"$commands_file"
  while IFS= read -r configured_command; do
      case "$configured_command" in
        "env HERDR_BIN_PATH="*)
          pinned_binary=${configured_command#env HERDR_BIN_PATH=}
          pinned_binary=${pinned_binary%% *}
          helper=${configured_command#* }
          helper=${helper#* }
          helper=${helper%% *}
          if [ ! -x "$pinned_binary" ]; then
            printf 'FAIL  configured HERDR_BIN_PATH is missing/not executable: %s\n' "$pinned_binary"
            failures=$((failures + 1))
          fi
          ;;
        *) helper=${configured_command%% *} ;;
      esac
      if [ -x "$helper" ]; then
        printf 'PASS  configured helper is executable: %s\n' "$helper"
      else
        printf 'FAIL  configured helper is missing/not executable: %s\n' "$helper"
        failures=$((failures + 1))
      fi
  done <"$commands_file"
  rm -f "$commands_file"
fi

for helper in \
  herdr-add-codex herdr-add-claude herdr-fork-agent \
  herdr-fork-codex-to-claude herdr-move-pane-next-tab herdr-rename-agent \
  herdr-delete-codex-context herdr-toggle-last-prompt herdr-resolve-agent-session; do
  if [ -x "$helper_root/$helper" ]; then
    pass "$helper is installed"
  else
    fail "$helper is missing from $helper_root"
  fi
done

if [ -x "$portable_mac_root/Install-HerdrCustomization.sh" ] &&
  [ -f "$portable_mac_root/config.macos.toml" ]; then
  pass "portable macOS installer and config are present"
else
  fail "portable macOS installer or config is missing"
fi

if grep -R -E -n '/Users/jinseongahn|Documents/repo' "$portable_mac_root" >/dev/null 2>&1; then
  fail "portable macOS controls contain a machine-specific path"
else
  pass "portable macOS controls contain no Jin-specific absolute paths"
fi

portable_helper_failure=false
for portable_helper in "$portable_mac_root/bin"/*; do
  [ -e "$portable_helper" ] || continue
  if [ ! -x "$portable_helper" ]; then
    portable_helper_failure=true
    fail "portable helper is not executable: $portable_helper"
  fi
done
[ "$portable_helper_failure" = false ] && pass "portable macOS helpers are executable"

if grep -Fq 'cmd.env_remove("NO_COLOR")' "$repo_root/src/pane.rs" &&
  grep -Fq '.env_remove("NO_COLOR")' "$repo_root/src/server/handoff.rs"; then
  pass "source keeps both NO_COLOR protections"
else
  warn "one or both NO_COLOR source protections are absent"
fi

if cmp -s "$repo_root/src/detect/manifests/claude.toml" \
  "$repo_root/distribution/agent-detection/claude.toml"; then
  pass "Claude source and distribution manifests match"
else
  fail "Claude source and distribution manifests differ"
fi

if git -C "$repo_root" diff --quiet && git -C "$repo_root" diff --cached --quiet; then
  pass "Herdr worktree is clean"
else
  warn "Herdr worktree has local changes; preserve them before any update"
  git -C "$repo_root" status --short
fi

printf '\nSUMMARY  %d failure(s), %d warning(s)\n' "$failures" "$warnings"
[ "$failures" -eq 0 ]
