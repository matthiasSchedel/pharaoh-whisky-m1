#!/usr/bin/env bash
set -euo pipefail

PHARAOH_DIR="${PHARAOH_DIR:-${WINEPREFIX:-}/drive_c/Program Files/Sierra/Pharaoh}"
DDRAW_INI="${DDRAW_INI:-$PHARAOH_DIR/ddraw.ini}"

if [[ -z "${WINEPREFIX:-}" && "${PHARAOH_DIR#/drive_c}" != "$PHARAOH_DIR" ]]; then
  echo "Set PHARAOH_DIR or WINEPREFIX so the script can find Pharaoh/ddraw.ini." >&2
  exit 2
fi

if [[ ! -f "$DDRAW_INI" ]]; then
  echo "Missing ddraw.ini: $DDRAW_INI" >&2
  echo "Run scripts/prepare-pharaoh-whisky.sh first, or set DDRAW_INI=/path/to/ddraw.ini." >&2
  exit 1
fi

set_ini_key() {
  local key="$1"
  local value="$2"

  if grep -qiE "^[[:space:]]*$key[[:space:]]*=" "$DDRAW_INI"; then
    perl -0pi -e "s/^[ \\t]*\\Q$key\\E[ \\t]*=.*/$key=$value/mi" "$DDRAW_INI"
  else
    printf '%s=%s\n' "$key" "$value" >> "$DDRAW_INI"
  fi
}

set_ini_key renderer opengl
set_ini_key windowed false
set_ini_key border false
set_ini_key maintas true
set_ini_key boxing true
set_ini_key width 0
set_ini_key height 0

echo "Configured cnc-ddraw fullscreen scaling in: $DDRAW_INI"
