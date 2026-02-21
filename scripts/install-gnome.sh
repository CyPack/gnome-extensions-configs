#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_SRC="$REPO_DIR/gnome-extensions/extensions"
EXT_DST="$HOME/.local/share/gnome-shell/extensions"
DCONF_FILE="$REPO_DIR/gnome-extensions/extensions-settings.dconf"
ENABLE_FILE="$REPO_DIR/gnome-extensions/enabled-extensions.txt"
STARSHIP_SRC="$REPO_DIR/starship.toml"
STARSHIP_DST="$HOME/.config/starship.toml"

AUTO_YES=0
FORCE_NON_GNOME=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: bash scripts/install-gnome.sh [--yes] [--force-non-gnome] [--dry-run]

Options:
  --yes              Skip confirmation prompt.
  --force-non-gnome  Continue even if desktop is not GNOME.
  --dry-run          Show checks and planned actions without applying changes.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y)
      AUTO_YES=1
      ;;
    --force-non-gnome)
      FORCE_NON_GNOME=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

DESKTOP_INFO="${XDG_CURRENT_DESKTOP:-unknown} | ${DESKTOP_SESSION:-unknown}"
IS_GNOME=0
IS_KDE=0
IS_NOBARA=0

OS_NAME="unknown"
OS_ID="unknown"
if [ -f /etc/os-release ]; then
  OS_NAME="$(. /etc/os-release && printf '%s' "${NAME:-unknown}")"
  OS_ID="$(. /etc/os-release && printf '%s' "${ID:-unknown}")"
fi

PKG_MGR="unknown"
if command -v dnf >/dev/null 2>&1; then
  PKG_MGR="dnf"
elif command -v apt-get >/dev/null 2>&1; then
  PKG_MGR="apt"
elif command -v pacman >/dev/null 2>&1; then
  PKG_MGR="pacman"
elif command -v zypper >/dev/null 2>&1; then
  PKG_MGR="zypper"
fi

install_hint() {
  local kind="$1"
  case "$PKG_MGR" in
    dnf)
      if [ "$kind" = "required" ]; then
        echo "sudo dnf install -y gnome-extensions-app dconf rsync"
      else
        echo "sudo dnf install -y gnome-tweaks gnome-extension-manager"
      fi
      ;;
    apt)
      if [ "$kind" = "required" ]; then
        echo "sudo apt-get install -y gnome-shell-extension-prefs dconf-cli rsync"
      else
        echo "sudo apt-get install -y gnome-tweaks gnome-shell-extension-manager"
      fi
      ;;
    pacman)
      if [ "$kind" = "required" ]; then
        echo "sudo pacman -S --needed gnome-shell-extensions dconf rsync"
      else
        echo "sudo pacman -S --needed gnome-tweaks extension-manager"
      fi
      ;;
    zypper)
      if [ "$kind" = "required" ]; then
        echo "sudo zypper install -y gnome-extensions dconf rsync"
      else
        echo "sudo zypper install -y gnome-tweaks gnome-shell-extension-manager"
      fi
      ;;
    *)
      echo "Install required GNOME packages manually for your distro."
      ;;
  esac
}

if printf "%s" "${XDG_CURRENT_DESKTOP:-}" | grep -Eqi 'gnome'; then
  IS_GNOME=1
elif printf "%s" "${DESKTOP_SESSION:-}" | grep -Eqi 'gnome'; then
  IS_GNOME=1
fi

if printf "%s" "${XDG_CURRENT_DESKTOP:-}" | grep -Eqi 'kde|plasma'; then
  IS_KDE=1
elif printf "%s" "${DESKTOP_SESSION:-}" | grep -Eqi 'kde|plasma'; then
  IS_KDE=1
fi

if printf "%s %s" "$OS_NAME" "$OS_ID" | grep -Eqi 'nobara'; then
  IS_NOBARA=1
fi

if [ "$IS_GNOME" -ne 1 ] && [ "$FORCE_NON_GNOME" -ne 1 ]; then
  echo "Detected desktop is not GNOME: $DESKTOP_INFO" >&2
  echo "Use --force-non-gnome if you really want to continue." >&2
  exit 1
fi

missing_required=()
for cmd in dconf gsettings gnome-extensions rsync; do
  command -v "$cmd" >/dev/null 2>&1 || missing_required+=("$cmd")
done

missing_recommended=()
for cmd in gnome-tweaks gnome-extension-manager; do
  command -v "$cmd" >/dev/null 2>&1 || missing_recommended+=("$cmd")
done

echo "Desktop: $DESKTOP_INFO"
echo "OS: $OS_NAME ($OS_ID)"
echo "Package manager: $PKG_MGR"
echo "Required checks: dconf gsettings gnome-extensions rsync"
if [ "${#missing_required[@]}" -gt 0 ]; then
  echo "Missing required dependencies: ${missing_required[*]}" >&2
  echo "Install hint: $(install_hint required)" >&2
  exit 1
fi

if [ "$IS_KDE" -eq 1 ] && [ "$IS_GNOME" -ne 1 ]; then
  if command -v kpackagetool6 >/dev/null 2>&1 || command -v kpackagetool5 >/dev/null 2>&1; then
    echo "KDE tools detected (kpackagetool)."
  else
    echo "KDE desktop detected, but kpackagetool not found." >&2
  fi
  echo "This script applies GNOME configs; KDE users should follow KDE section in README."
fi

if [ "$IS_NOBARA" -eq 1 ]; then
  if command -v nobara-sync >/dev/null 2>&1; then
    echo "Nobara updater tool detected: nobara-sync"
  else
    echo "Nobara detected but nobara-sync command not found." >&2
    echo "Use Nobara's official Update System workflow before/after config changes." >&2
  fi
fi

if [ "${#missing_recommended[@]}" -gt 0 ]; then
  echo "Recommended tools missing: ${missing_recommended[*]}" >&2
  echo "Recommended install hint: $(install_hint recommended)" >&2
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo
  echo "Dry-run mode active. Planned actions:"
  echo "1) Backup current GNOME extension dconf"
  echo "2) Sync extension files to $EXT_DST"
  echo "3) Load $DCONF_FILE"
  echo "4) Enable extensions from $ENABLE_FILE"
  echo "5) Copy starship config to $STARSHIP_DST (if present)"
  exit 0
fi

if [ "$AUTO_YES" -ne 1 ]; then
  echo
  read -r -p "Apply GNOME config changes now? [y/N] " answer
  case "${answer:-}" in
    y|Y|yes|YES)
      ;;
    *)
      echo "Aborted by user."
      exit 0
      ;;
  esac
fi

backup_file="$HOME/extensions-backup-before-install-$(date +%Y%m%d-%H%M%S).dconf"
dconf dump /org/gnome/shell/extensions/ > "$backup_file" || true

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
echo "Backup created: $backup_file"
echo "Please restart GNOME Shell yourself (Wayland: logout/login, X11: Alt+F2 then r)."
