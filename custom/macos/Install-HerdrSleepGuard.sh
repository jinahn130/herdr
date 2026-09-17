#!/bin/sh
set -eu

[ "$(uname -s)" = Darwin ] || { echo 'This installer is intentionally macOS-only.' >&2; exit 1; }

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target_bin="$HOME/.local/bin"
launch_agents="$HOME/Library/LaunchAgents"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}/herdr"
label="com.jin.herdr-sleep-guard"
target_plist="$launch_agents/$label.plist"
domain="gui/$(id -u)"

mkdir -p "$target_bin" "$launch_agents" "$config_root"
install -m 0755 "$script_dir/bin/herdr-sleep-guard" "$target_bin/herdr-sleep-guard"

task_dir=$(mktemp -d)
trap 'rm -rf "$task_dir"' EXIT HUP INT TERM
escaped_home=$(printf '%s' "$HOME" | sed 's/[&|]/\\&/g')
sed "s|__HOME__|$escaped_home|g" \
  "$script_dir/com.jin.herdr-sleep-guard.plist" > "$task_dir/$label.plist"
plutil -lint "$task_dir/$label.plist" >/dev/null

if [ -f "$target_plist" ]; then
  backup="$config_root/$label.before-$(date +%Y%m%d-%H%M%S).plist"
  cp -p "$target_plist" "$backup"
  printf '%s\n' "Backed up the existing launch agent to $backup"
fi

launchctl bootout "$domain/$label" >/dev/null 2>&1 || true
install -m 0644 "$task_dir/$label.plist" "$target_plist"
launchctl bootstrap "$domain" "$target_plist"
launchctl kickstart -k "$domain/$label"

printf '%s\n' 'Installed Herdr sleep guard.'
printf '%s\n' 'It prevents idle system sleep while an agent is working and for ten minutes afterward.'
