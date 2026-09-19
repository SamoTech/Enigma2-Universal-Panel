#!/bin/sh
# Enigma2 Universal Panel — one-line receiver installation:
# wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh
# Alternative:
# curl -fsSL https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh
#
# The installer runs on the Enigma2 receiver as root and installs the native
# Enigma2 plugin plus its receiver-side runtime. No browser or PC is required.
# Enigma2 Universal Panel installer v1.6.0
set -eu

REPO="${E2PANEL_REPO:-https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main}"
DEST="/usr/lib/enigma2-universal-panel"
BIN="/usr/local/bin/e2panel"
PLUGIN_ROOT="/usr/lib/enigma2/python/Plugins/Extensions"
VERSION="1.6.0"
FETCH_TIMEOUT="${E2PANEL_FETCH_TIMEOUT:-30}"
FETCH_RETRIES="${E2PANEL_FETCH_RETRIES:-3}"

fail() {
  echo "Enigma2 Universal Panel installer: $*" >&2
  exit 1
}

info() {
  echo "[e2panel] $*"
}

[ "$(id -u)" = 0 ] || fail "Run this installer as root."
command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || fail "wget or curl is required."
[ -d "$PLUGIN_ROOT" ] || fail "Supported Enigma2 plugin path not found: $PLUGIN_ROOT"

case "$FETCH_TIMEOUT" in
  ''|*[!0-9]*|0) fail "E2PANEL_FETCH_TIMEOUT must be a positive integer." ;;
esac
case "$FETCH_RETRIES" in
  ''|*[!0-9]*|0) fail "E2PANEL_FETCH_RETRIES must be a positive integer." ;;
esac

STAGE="$(mktemp -d /tmp/e2panel-install.XXXXXX)" || fail "Unable to create staging directory."
cleanup() {
  rm -rf "$STAGE"
}
trap cleanup EXIT HUP INT TERM

fetch() {
  rel="$1"
  src="$REPO/$rel"
  out="$STAGE/$rel"
  mkdir -p "$(dirname "$out")"

  if command -v wget >/dev/null 2>&1; then
    attempt=1
    while [ "$attempt" -le "$FETCH_RETRIES" ]; do
      if wget -q -T "$FETCH_TIMEOUT" -O "$out" "$src"; then
        return 0
      fi
      rm -f "$out"
      [ "$attempt" -lt "$FETCH_RETRIES" ] && sleep 1
      attempt=$((attempt + 1))
    done
  fi

  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL --connect-timeout "$FETCH_TIMEOUT" --max-time "$FETCH_TIMEOUT" --retry "$FETCH_RETRIES" --retry-delay 1 -o "$out" "$src"; then
      return 0
    fi
  fi

  rm -f "$out"
  fail "Unable to download $rel from $REPO"
}

install_file() {
  rel="$1"
  src="$STAGE/$rel"
  out="$DEST/$rel"
  [ -s "$src" ] || fail "Downloaded file is empty: $rel"
  mkdir -p "$(dirname "$out")"
  mv "$src" "$out"
}

install_plugin_file() {
  name="$1"
  src="$STAGE/plugin/$name"
  out="$PLUGIN_DEST/$name"
  [ -s "$src" ] || fail "Downloaded plugin file is empty: $name"
  mv "$src" "$out"
}

info "Starting installer v$VERSION"
info "Source: $REPO"

FILES="
panel.sh
scripts/lib/common.sh
scripts/lib/detect.sh
scripts/lib/compat.sh
scripts/lib/compatibility.sh
scripts/lib/actions.sh
scripts/lib/plugins.sh
scripts/lib/plugin-resolver.sh
scripts/lib/reboot.sh
scripts/lib/status.sh
scripts/lib/telemetry.sh
scripts/lib/diagnose.sh
config/capabilities.json
config/actions.json
config/settings.json
config/adapters.json
config/receivers.json
config/compatibility.json
config/plugin-sources.json
plugins/catalog.json
plugins/community.json
plugins/categories.json
plugins/compatibility.json
plugins/sources.json
channels/schema.json
channels/capabilities.json
settings/schema.json
settings/categories.json
packages/schema.json
docs/discovery/PLUGIN_INSTALLATION.md
docs/compatibility/PLATFORM_MATRIX.md
docs/discovery/PACKAGE_INTELLIGENCE.md
docs/native-gui/PLUGIN_PACKAGE.md
"

mkdir -p "$DEST"
for rel in $FILES; do
  fetch "$rel"
done

PLUGIN_DEST="$PLUGIN_ROOT/Enigma2UniversalPanel"
mkdir -p "$PLUGIN_DEST"

for name in __init__.py plugin.py actions.py audit_history.py screens.py; do
  fetch "Plugins/Extensions/Enigma2UniversalPanel/$name"
  mkdir -p "$STAGE/plugin"
  mv "$STAGE/Plugins/Extensions/Enigma2UniversalPanel/$name" "$STAGE/plugin/$name"
done

for rel in $FILES; do
  install_file "$rel"
done

for name in __init__.py plugin.py actions.py audit_history.py screens.py; do
  install_plugin_file "$name"
done

chmod 755 "$DEST/panel.sh" "$DEST/scripts/lib/"*.sh
chmod 644 "$PLUGIN_DEST/"*.py
ln -sf "$DEST/panel.sh" "$BIN"

info "Installation files deployed."
if "$BIN" status; then
  info "Installation completed successfully."
else
  fail "Runtime status check failed after installation."
fi
