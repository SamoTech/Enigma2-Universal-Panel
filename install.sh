#!/bin/sh
# Enigma2 Universal Panel installer v1.0.0
set -e
REPO="https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/reconstruction/universal-management-layer"
DEST="/usr/lib/enigma2-universal-panel"
BIN="/usr/local/bin/e2panel"

[ "$(id -u)" = 0 ] || { echo "Run as root."; exit 1; }
command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || { echo "wget or curl is required."; exit 1; }

mkdir -p "$DEST/scripts/lib" "$DEST/config" "$DEST/plugins" "$DEST/docs"

fetch() {
  url="$REPO/$1"
  out="$DEST/$1"
  mkdir -p "$(dirname "$out")"
  if command -v wget >/dev/null 2>&1; then wget -q -O "$out" "$url"; else curl -fsSL "$url" -o "$out"; fi
}

fetch panel.sh
fetch scripts/lib/common.sh
fetch scripts/lib/detect.sh
fetch scripts/lib/compat.sh
fetch scripts/lib/actions.sh
fetch scripts/lib/status.sh
fetch scripts/lib/diagnose.sh
fetch config/capabilities.json
fetch config/adapters.json
fetch config/receivers.json
fetch plugins/catalog.json

chmod 755 "$DEST/panel.sh" "$DEST/scripts/lib/"*.sh
ln -sf "$DEST/panel.sh" "$BIN"

echo "Enigma2 Universal Panel 1.0.0 installed."
"$BIN" status
