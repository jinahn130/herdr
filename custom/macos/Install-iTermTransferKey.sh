#!/bin/sh
# Add only the exact transfer chord; never replace a profile's keyboard map.
set -eu

[ "$(uname -s)" = Darwin ] || { echo 'macOS only.' >&2; exit 1; }
case "${1:-}" in
  --check) check_only=true ;;
  '') check_only=false ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

if [ "$check_only" = false ] && pgrep -x iTerm2 >/dev/null; then
  echo 'Quit iTerm2 first so its cached preferences cannot overwrite this change. Leave the Herdr server running.' >&2
  exit 1
fi

task_dir=$(mktemp -d)
chmod 700 "$task_dir"
task_plist="$task_dir/iterm.plist"
defaults export com.googlecode.iterm2 "$task_plist" >/dev/null
chmod 600 "$task_plist"
buddy=/usr/libexec/PlistBuddy
hex='0x1b 0x5b 0x31 0x30 0x32 0x3a 0x37 0x30 0x3b 0x38 0x75'
index=0
matched=0
while name=$($buddy -c "Print :'New Bookmarks':$index:Name" "$task_plist" 2>/dev/null); do
  case "$name" in
    Default|'Codex Cheatsheet')
      matched=$((matched + 1))
      base=":'New Bookmarks':$index:'Keyboard Map'"
      if [ "$check_only" = false ]; then
        $buddy -c "Add $base dict" "$task_plist" 2>/dev/null || true
      fi
      for key in '0x66-0xe0000' '0x46-0xe0000' '*-0xe0000-0x3'; do
        path="$base:'$key'"
        if [ "$check_only" = true ]; then
          value=$($buddy -c "Print $path:Text" "$task_plist" 2>/dev/null || true)
          if [ "$value" = "$hex" ]; then
            echo "$name: $key configured"
          else
            echo "$name: $key missing exact transfer translation"
          fi
        else
          $buddy -c "Add $path dict" "$task_plist" 2>/dev/null || true
          $buddy -c "Add $path:Action integer 11" "$task_plist" 2>/dev/null || $buddy -c "Set $path:Action 11" "$task_plist"
          $buddy -c "Add $path:Text string $hex" "$task_plist" 2>/dev/null || $buddy -c "Set $path:Text $hex" "$task_plist"
        fi
      done
      ;;
  esac
  index=$((index + 1))
done
[ "$matched" -gt 0 ] || { echo 'No intended iTerm2 profiles found.' >&2; exit 1; }

if [ "$check_only" = false ]; then
  backup_dir="$HOME/.config/herdr/iterm-key-backups"
  mkdir -p "$backup_dir"
  chmod 700 "$backup_dir"
  backup="$backup_dir/iterm-before-transfer-$(date +%Y%m%d-%H%M%S).plist"
  defaults export com.googlecode.iterm2 "$backup" >/dev/null
  chmod 600 "$backup"
  defaults import com.googlecode.iterm2 "$task_plist" >/dev/null
  echo "Installed exact Ctrl+Option+Shift+F translation in $matched profiles. Other mappings and both Option settings were preserved."
  echo "Private preference backup: $backup"
fi
