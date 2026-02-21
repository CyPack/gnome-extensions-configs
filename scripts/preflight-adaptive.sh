#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="$REPO_DIR/docs"
REPORT_PATH="$REPORT_DIR/preflight-report-$(date +%Y%m%d-%H%M%S).md"
REPORT_ONLY=0

usage() {
  cat <<'EOF'
Usage: bash scripts/preflight-adaptive.sh [--report-only]

Options:
  --report-only  Generate report and exit without interactive menu.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --report-only)
      REPORT_ONLY=1
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

OS_NAME="unknown"
OS_ID="unknown"
OS_VERSION="unknown"
if [ -f /etc/os-release ]; then
  OS_NAME="$(. /etc/os-release && printf '%s' "${NAME:-unknown}")"
  OS_ID="$(. /etc/os-release && printf '%s' "${ID:-unknown}")"
  OS_VERSION="$(. /etc/os-release && printf '%s' "${VERSION_ID:-unknown}")"
fi

DESKTOP_CURRENT="${XDG_CURRENT_DESKTOP:-unknown}"
DESKTOP_SESSION_NAME="${DESKTOP_SESSION:-unknown}"
SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"

IS_GNOME=0
IS_KDE=0
IS_NOBARA=0
if printf "%s %s" "$DESKTOP_CURRENT" "$DESKTOP_SESSION_NAME" | grep -Eqi 'gnome'; then
  IS_GNOME=1
fi
if printf "%s %s" "$DESKTOP_CURRENT" "$DESKTOP_SESSION_NAME" | grep -Eqi 'kde|plasma'; then
  IS_KDE=1
fi
if printf "%s %s" "$OS_NAME" "$OS_ID" | grep -Eqi 'nobara'; then
  IS_NOBARA=1
fi

WM_HINT="unknown"
if printf "%s %s" "$DESKTOP_CURRENT" "$DESKTOP_SESSION_NAME" | grep -Eqi 'sway'; then
  WM_HINT="sway"
elif printf "%s %s" "$DESKTOP_CURRENT" "$DESKTOP_SESSION_NAME" | grep -Eqi 'hypr'; then
  WM_HINT="hyprland"
elif [ "$IS_GNOME" -eq 1 ]; then
  WM_HINT="mutter (GNOME)"
elif [ "$IS_KDE" -eq 1 ]; then
  WM_HINT="kwin (KDE/Plasma)"
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

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

GNOME_REQUIRED_MISSING=()
for cmd in dconf gsettings gnome-extensions rsync; do
  check_cmd "$cmd" || GNOME_REQUIRED_MISSING+=("$cmd")
done

GNOME_RECOMMENDED_MISSING=()
for cmd in gnome-tweaks gnome-extension-manager; do
  check_cmd "$cmd" || GNOME_RECOMMENDED_MISSING+=("$cmd")
done

KDE_TOOL_STATUS="missing"
if check_cmd kpackagetool6 || check_cmd kpackagetool5; then
  KDE_TOOL_STATUS="present"
fi

NOBARA_SYNC_STATUS="missing"
if check_cmd nobara-sync; then
  NOBARA_SYNC_STATUS="present"
fi

install_hint() {
  local kind="$1"
  case "$PKG_MGR" in
    dnf)
      if [ "$kind" = "gnome-required" ]; then
        echo "sudo dnf install -y gnome-extensions-app dconf rsync"
      elif [ "$kind" = "gnome-recommended" ]; then
        echo "sudo dnf install -y gnome-tweaks gnome-extension-manager"
      else
        echo "sudo dnf install -y plasma-workspace"
      fi
      ;;
    apt)
      if [ "$kind" = "gnome-required" ]; then
        echo "sudo apt-get install -y gnome-shell-extension-prefs dconf-cli rsync"
      elif [ "$kind" = "gnome-recommended" ]; then
        echo "sudo apt-get install -y gnome-tweaks gnome-shell-extension-manager"
      else
        echo "sudo apt-get install -y kde-plasma-desktop"
      fi
      ;;
    pacman)
      if [ "$kind" = "gnome-required" ]; then
        echo "sudo pacman -S --needed gnome-shell-extensions dconf rsync"
      elif [ "$kind" = "gnome-recommended" ]; then
        echo "sudo pacman -S --needed gnome-tweaks extension-manager"
      else
        echo "sudo pacman -S --needed plasma-meta"
      fi
      ;;
    zypper)
      if [ "$kind" = "gnome-required" ]; then
        echo "sudo zypper install -y gnome-extensions dconf rsync"
      elif [ "$kind" = "gnome-recommended" ]; then
        echo "sudo zypper install -y gnome-tweaks gnome-shell-extension-manager"
      else
        echo "sudo zypper install -y patterns-kde-kde"
      fi
      ;;
    *)
      echo "Install packages manually for your distro."
      ;;
  esac
}

mkdir -p "$REPORT_DIR"
{
  echo "# Adaptive Preflight Report"
  echo
  echo "- Generated: $(date -Is)"
  echo "- OS: $OS_NAME ($OS_ID $OS_VERSION)"
  echo "- Desktop: $DESKTOP_CURRENT"
  echo "- Session: $DESKTOP_SESSION_NAME"
  echo "- Session type: $SESSION_TYPE"
  echo "- WM hint: $WM_HINT"
  echo "- Package manager: $PKG_MGR"
  echo
  echo "## Detection Flags"
  echo
  echo "- GNOME detected: $IS_GNOME"
  echo "- KDE detected: $IS_KDE"
  echo "- Nobara detected: $IS_NOBARA"
  echo
  echo "## Tool Checks"
  echo
  if [ "${#GNOME_REQUIRED_MISSING[@]}" -eq 0 ]; then
    echo "- GNOME required tools: OK"
  else
    echo "- GNOME required tools missing: ${GNOME_REQUIRED_MISSING[*]}"
    echo "- Install hint: $(install_hint gnome-required)"
  fi
  if [ "${#GNOME_RECOMMENDED_MISSING[@]}" -eq 0 ]; then
    echo "- GNOME recommended tools: OK"
  else
    echo "- GNOME recommended tools missing: ${GNOME_RECOMMENDED_MISSING[*]}"
    echo "- Install hint: $(install_hint gnome-recommended)"
  fi
  echo "- KDE packaging tool status: $KDE_TOOL_STATUS"
  echo "- Nobara sync status: $NOBARA_SYNC_STATUS"
  echo
  echo "## Recommended Next Step"
  echo
  if [ "$IS_GNOME" -eq 1 ]; then
    echo "- Run: bash scripts/install-gnome.sh --dry-run"
    echo "- Then: bash scripts/install-gnome.sh"
  else
    echo "- GNOME not detected. Start with --dry-run only or use KDE guidance in README."
  fi
  if [ "$IS_NOBARA" -eq 1 ]; then
    echo "- Nobara note: prefer Update System / nobara-sync workflow for system updates."
  fi
} > "$REPORT_PATH"

echo "Preflight report created: $REPORT_PATH"
echo "OS: $OS_NAME ($OS_ID $OS_VERSION)"
echo "Desktop/Session: $DESKTOP_CURRENT | $DESKTOP_SESSION_NAME | $SESSION_TYPE"
echo "WM hint: $WM_HINT"
echo "Package manager: $PKG_MGR"

if [ "$REPORT_ONLY" -eq 1 ] || [ ! -t 0 ]; then
  exit 0
fi

echo
echo "Select next action:"
echo "1) Run GNOME install dry-run"
echo "2) Run GNOME install (interactive confirmation)"
echo "3) Print AI CLI prompt template"
echo "4) Exit"
read -r -p "Choice [1-4]: " choice

case "${choice:-4}" in
  1)
    bash "$REPO_DIR/scripts/install-gnome.sh" --dry-run
    ;;
  2)
    bash "$REPO_DIR/scripts/install-gnome.sh"
    ;;
  3)
    cat <<EOF
Use this prompt in your AI CLI:

Role: System-aware Linux config assistant.
Environment:
- OS: $OS_NAME ($OS_ID $OS_VERSION)
- Desktop: $DESKTOP_CURRENT
- Session: $DESKTOP_SESSION_NAME ($SESSION_TYPE)
- WM hint: $WM_HINT
- Package manager: $PKG_MGR

Rules:
1) First run preflight checks and summarize risks.
2) Show backup commands before any apply step.
3) Use dry-run before apply.
4) For Nobara, prefer Update System / nobara-sync guidance.
5) Keep blur-my-shell disabled unless user explicitly opts in.
EOF
    ;;
  *)
    echo "Exit."
    ;;
esac
