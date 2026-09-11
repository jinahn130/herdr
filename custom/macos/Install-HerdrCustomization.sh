#!/bin/sh
set -eu

apply_config=false

case "${1:-}" in
  "") ;;
  --apply-config) apply_config=true ;;
  *)
    printf '%s\n' "usage: $0 [--apply-config]" >&2
    exit 2
    ;;
esac

if [ "$(uname -s)" != "Darwin" ]; then
  printf '%s\n' "This installer is intentionally macOS-only." >&2
  exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_dir="$script_dir/bin"
target_bin="$HOME/.local/bin"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}/herdr"
config_path="$config_root/config.toml"

mkdir -p "$target_bin"

for helper in "$source_dir"/*; do
  [ -f "$helper" ] || continue
  install -m 0755 "$helper" "$target_bin/$(basename "$helper")"
done

printf '%s\n' "Installed macOS workflow helpers in $target_bin"

if [ "$apply_config" = true ]; then
  mkdir -p "$config_root"
  if [ -f "$config_path" ]; then
    stamp=$(date +%Y%m%d-%H%M%S)
    backup_path="$config_path.before-macos-custom-$stamp"
    cp -p "$config_path" "$backup_path"
    printf '%s\n' "Backed up the existing config to $backup_path"
  fi

  install -m 0600 "$script_dir/config.macos.toml" "$config_path"
  printf '%s\n' "Installed the macOS config at $config_path"

  if command -v herdr >/dev/null 2>&1; then
    herdr config check
    if herdr status server --json >/dev/null 2>&1; then
      herdr server reload-config >/dev/null
      printf '%s\n' "Reloaded the running Herdr server configuration."
    fi
  fi
else
  printf '%s\n' "The existing Herdr config was not changed."
  printf '%s\n' "After reviewing config.macos.toml, rerun with --apply-config."
fi
