#!/bin/zsh
set -euo pipefail
APPDIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$HOME/Library/Logs/pharaoh-launcher.log"
exec >> "$LOG" 2>&1
echo "[$(date)] Launching Pharaoh from $APPDIR"

WINE="/Applications/Game Porting Toolkit.app/Contents/Resources/wine/bin/wine64"
BOTTLE="/tmp/pharaoh-bottle"
EXE="$BOTTLE/drive_c/Program Files/Sierra/Pharaoh/Pharaoh.exe"

if [ ! -x "$WINE" ]; then
  osascript -e 'display alert "GPTK not installed" message "Install via: brew install --cask gcenx/wine/game-porting-toolkit"'
  exit 1
fi

if [ ! -d "$BOTTLE" ]; then
  osascript -e 'display alert "Pharaoh bottle missing" message "Bottle /tmp/pharaoh-bottle not found. See https://github.com/matthiasSchedel/pharaoh-whisky-m1 for setup."'
  exit 1
fi

if [ ! -f "$EXE" ]; then
  osascript -e "display alert \"Pharaoh not installed\" message \"Game files missing at $EXE.\""
  exit 1
fi

if [ ! -d /Volumes/Pharaoh ]; then
  ISO=$(find "$HOME" /tmp -name pharaoh.iso 2>/dev/null | head -1 || true)
  if [ -n "$ISO" ]; then hdiutil attach "$ISO" -quiet || true; fi
fi

export WINEPREFIX="$BOTTLE"
cd "$(dirname "$EXE")"
exec "$WINE" "$EXE"
