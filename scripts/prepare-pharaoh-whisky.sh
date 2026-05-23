#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
prepare-pharaoh-whisky.sh

Prepare a Pharaoh install inside an existing Whisky / Wine prefix.

Required environment:
  WINEPREFIX       Absolute path to the target bottle / prefix.
  WINE             Absolute path to wine64 from Whisky or GPTK.
  PHARAOH_ISO      Mounted Pharaoh volume path, usually /Volumes/Pharaoh.
  CNCDDRAW_ZIP     Path to cnc-ddraw v7.1.0.0 zip.

Optional environment:
  PHARAOH_DIR      Install dir inside the prefix.
                   Default: $WINEPREFIX/drive_c/Program Files/Sierra/Pharaoh

Example:
  export WINEPREFIX="$HOME/Library/Containers/com.isaacmarovitz.Whisky/Bottles/<UUID>"
  export WINE="/Applications/Whisky.app/Contents/Resources/Libraries/Wine/bin/wine64"
  export PHARAOH_ISO="/Volumes/Pharaoh"
  export CNCDDRAW_ZIP="$HOME/Downloads/cnc-ddraw.zip"
  ./scripts/prepare-pharaoh-whisky.sh
USAGE
}

require_path() {
  local label="$1"
  local path="$2"

  if [[ -z "$path" || ! -e "$path" ]]; then
    echo "missing or invalid $label: $path" >&2
    exit 1
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

: "${WINEPREFIX:?Set WINEPREFIX to the target Whisky / Wine prefix}"
: "${WINE:?Set WINE to the wine64 binary}"
: "${PHARAOH_ISO:?Set PHARAOH_ISO to the mounted Pharaoh CD / ISO path}"
: "${CNCDDRAW_ZIP:?Set CNCDDRAW_ZIP to the cnc-ddraw zip path}"

PHARAOH_DIR="${PHARAOH_DIR:-$WINEPREFIX/drive_c/Program Files/Sierra/Pharaoh}"

require_path "WINE" "$WINE"
require_path "PHARAOH_ISO" "$PHARAOH_ISO"
require_path "CNCDDRAW_ZIP" "$CNCDDRAW_ZIP"

if ! command -v unshield >/dev/null 2>&1; then
  echo "unshield not found; install with: brew install unshield" >&2
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "unzip not found" >&2
  exit 1
fi

mkdir -p "$WINEPREFIX" "$PHARAOH_DIR"
"$WINE" wineboot --init

cab_path=""
for candidate in "$PHARAOH_ISO/Setup/data1.cab" "$PHARAOH_ISO/data1.cab"; do
  if [[ -f "$candidate" ]]; then
    cab_path="$candidate"
    break
  fi
done

if [[ -z "$cab_path" ]]; then
  echo "could not find data1.cab under $PHARAOH_ISO" >&2
  exit 1
fi

unshield -d "$PHARAOH_DIR" x "$cab_path"

for asset_dir in Audio Binks; do
  if [[ -d "$PHARAOH_ISO/$asset_dir" ]]; then
    rm -rf "$PHARAOH_DIR/$asset_dir"
    cp -R "$PHARAOH_ISO/$asset_dir" "$PHARAOH_DIR/"
  else
    echo "warning: $asset_dir not found on ISO" >&2
  fi
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

unzip -q "$CNCDDRAW_ZIP" -d "$tmp_dir/cnc-ddraw"
find "$tmp_dir/cnc-ddraw" -iname ddraw.dll -exec cp {} "$PHARAOH_DIR/ddraw.dll" \; -quit
find "$tmp_dir/cnc-ddraw" -iname ddraw.ini -exec cp {} "$PHARAOH_DIR/ddraw.ini" \; -quit

if [[ -d "$tmp_dir/cnc-ddraw/Shaders" ]]; then
  rm -rf "$PHARAOH_DIR/Shaders"
  cp -R "$tmp_dir/cnc-ddraw/Shaders" "$PHARAOH_DIR/Shaders"
fi

if [[ ! -f "$PHARAOH_DIR/ddraw.dll" || ! -f "$PHARAOH_DIR/ddraw.ini" ]]; then
  echo "cnc-ddraw zip did not contain ddraw.dll and ddraw.ini" >&2
  exit 1
fi

if grep -q '^renderer=' "$PHARAOH_DIR/ddraw.ini"; then
  perl -0pi -e 's/^renderer=.*/renderer=opengl/m' "$PHARAOH_DIR/ddraw.ini"
fi

"$WINE" reg add 'HKCU\Software\Wine\AppDefaults\Pharaoh.exe\DllOverrides' \
  /v ddraw /d native,builtin /f

echo "prepared Pharaoh at: $PHARAOH_DIR"
echo "launch from the game directory with:"
echo "  cd \"$PHARAOH_DIR\""
echo "  \"$WINE\" Pharaoh.exe"
