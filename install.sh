#!/bin/sh
# Enigma2 Universal Panel installer v1.1.0
set -e
REPO="https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main"
DEST="/usr/lib/enigma2-universal-panel"
BIN="/usr/local/bin/e2panel"

[ "$(id -u)" = 0 ] || { echo "Run as root."; exit 1; }
command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || { echo "wget or curl is required."; exit 1; }
mkdir -p "$DEST/scripts/lib" "$DEST/config" "$DEST/plugins" "$DEST/docs/discovery" "$DEST/docs/api" "$DEST/channels" "$DEST/settings"

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
fetch scripts/lib/plugins.sh
fetch scripts/lib/status.sh
fetch scripts/lib/diagnose.sh
fetch config/capabilities.json
fetch config/actions.json
fetch config/settings.json
fetch config/adapters.json
fetch config/receivers.json
fetch config/compatibility.json
fetch config/plugin-sources.json
fetch plugins/catalog.json
fetch plugins/compatibility.json
fetch plugins/sources.json
fetch channels/schema.json
fetch channels/capabilities.json
fetch settings/schema.json
fetch settings/categories.json
fetch docs/discovery/PLUGIN_INSTALLATION.md

chmod 755 "$DEST/panel.sh" "$DEST/scripts/lib/"*.sh
ln -sf "$DEST/panel.sh" "$BIN"
echo "Enigma2 Universal Panel 1.2.0 installed."
"$BIN" status
