#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_SRC="$REPO_DIR/gnome-extensions/extensions"
EXT_DST="$HOME/.local/share/gnome-shell/extensions"
DCONF_FILE="$REPO_DIR/gnome-extensions/extensions-settings.dconf"
ENABLE_FILE="$REPO_DIR/gnome-extensions/enabled-extensions.txt"
STARSHIP_SRC="$REPO_DIR/starship.toml"
STARSHIP_DST="$HOME/.config/starship.toml"

missing=()
for cmd in dconf gsettings gnome-extensions rsync; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if [ "${#missing[@]}" -gt 0 ]; then
  echo "Missing dependencies: ${missing[*]}" >&2
  echo "Fedora install example: sudo dnf install -y gnome-extensions-app dconf rsync" >&2
  exit 1
fi

mkdir -p "$EXT_DST" "$HOME/.config"
rsync -a --delete "$EXT_SRC/" "$EXT_DST/"
dconf load /org/gnome/shell/extensions/ < "$DCONF_FILE"

while IFS= read -r ext || [ -n "$ext" ]; do
  [ -z "$ext" ] && continue
  if gnome-extensions info "$ext" >/dev/null 2>&1 || [ -d "$EXT_DST/$ext" ]; then
    gnome-extensions enable "$ext" >/dev/null 2>&1 || true
  else
    echo "WARN: extension not installed on this system: $ext" >&2
  fi
done < "$ENABLE_FILE"

if [ -f "$STARSHIP_SRC" ]; then
  cp "$STARSHIP_SRC" "$STARSHIP_DST"
fi

echo "Installation complete."
echo "Please restart GNOME Shell yourself (Wayland: logout/login, X11: Alt+F2 then r)."
