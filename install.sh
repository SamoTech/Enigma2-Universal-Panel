#!/bin/sh
# Enigma2 Universal Panel — one-line receiver installation:
# wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh
# Alternative:
# curl -fsSL https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh
#
# Optional command-line modes:
# wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh -s -- --check
# wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh -s -- --restart-gui
#
# The installer runs on the Enigma2 receiver as root and installs the native
# Enigma2 plugin plus its receiver-side runtime. No browser or PC is required.
# Enigma2 Universal Panel installer v1.10.0
set -eu
umask 022

REPO="https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main"
DEST="/usr/lib/enigma2-universal-panel"
BIN="/usr/local/bin/e2panel"
VERSION="1.10.0"
FETCH_TIMEOUT="${E2PANEL_FETCH_TIMEOUT:-30}"
FETCH_RETRIES="${E2PANEL_FETCH_RETRIES:-3}"
MIN_FREE_KB="${E2PANEL_MIN_FREE_KB:-4096}"
RESTART_GUI=0
CHECK_ONLY=0

fail() {
  echo "Enigma2 Universal Panel installer: $*" >&2
  exit 1
}

info() {
  echo "[e2panel] $*"
}

usage() {
  cat <<EOF
Enigma2 Universal Panel installer v$VERSION

Usage:
  install.sh [--check] [--restart-gui]

Options:
  --check        Download and validate the release, but do not install it.
  --restart-gui  Restart Enigma2 after a successful installation.
  --no-restart   Explicitly keep the default no-restart behavior.
  --help         Show this help.

One-line install:
  wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh

One-line validation:
  wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh -s -- --check

One-line install + GUI restart:
  wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh -s -- --restart-gui
EOF
}

case "${1:-}" in
  "") ;;
  --check) CHECK_ONLY=1 ;;
  --restart-gui) RESTART_GUI=1 ;;
  --no-restart) RESTART_GUI=0 ;;
  --help|-h) usage; exit 0 ;;
  *) usage; fail "Unknown option: $1" ;;
esac

[ "$(id -u)" = 0 ] || fail "Run this installer as root."
command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 || fail "wget or curl is required."

PLUGIN_ROOT=""
for candidate in \
  /usr/lib/enigma2/python/Plugins/Extensions \
  /usr/lib/enigma2/python2.7/Plugins/Extensions \
  /usr/lib/enigma2/python3/Plugins/Extensions
do
  if [ -d "$candidate" ]; then
    PLUGIN_ROOT="$candidate"
    break
  fi
done
[ -n "$PLUGIN_ROOT" ] || fail "Supported Enigma2 plugin path not found."

PYTHON_BIN=""
for candidate in python3 python python2
do
  if command -v "$candidate" >/dev/null 2>&1; then
    PYTHON_BIN="$candidate"
    break
  fi
done
[ -n "$PYTHON_BIN" ] || fail "No Python interpreter found."

PYTHON_VERSION="$("$PYTHON_BIN" -c 'import sys; print(sys.version.split()[0])' 2>/dev/null || echo unknown)"
PYTHON_MAJOR="$("$PYTHON_BIN" -c 'import sys; print(sys.version_info[0])' 2>/dev/null || echo unknown)"
info "Python: $PYTHON_BIN v$PYTHON_VERSION (major $PYTHON_MAJOR)"
info "Plugin root: $PLUGIN_ROOT"

AVAILABLE_KB="$(df -k /tmp 2>/dev/null | awk 'NR==2 {print $4}' | tr -cd '0-9')"
if [ -n "$AVAILABLE_KB" ] && [ "$AVAILABLE_KB" -lt "$MIN_FREE_KB" ] 2>/dev/null; then
  fail "/tmp has only ${AVAILABLE_KB}KB free; need at least ${MIN_FREE_KB}KB."
fi
[ -n "$AVAILABLE_KB" ] && info "/tmp free: ${AVAILABLE_KB}KB" || info "/tmp free-space check unavailable"

case "$FETCH_TIMEOUT" in
  ''|*[!0-9]*|0) fail "E2PANEL_FETCH_TIMEOUT must be a positive integer." ;;
esac
case "$FETCH_RETRIES" in
  ''|*[!0-9]*|0) fail "E2PANEL_FETCH_RETRIES must be a positive integer." ;;
esac
case "$MIN_FREE_KB" in
  ''|*[!0-9]*) fail "E2PANEL_MIN_FREE_KB must be an integer." ;;
esac

STAGE="$(mktemp -d /tmp/e2panel-install.XXXXXX)" || fail "Unable to create staging directory."
RUNTIME_STAGE="$STAGE/runtime"
PLUGIN_STAGE="$STAGE/plugin"
mkdir -p "$RUNTIME_STAGE" "$PLUGIN_STAGE"

cleanup() {
  rm -rf "$STAGE" "${DEST}.e2panel-next.${PPID:-0}.$$" "${PLUGIN_ROOT}/.e2panel-next.${PPID:-0}.$$" 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

fetch() {
  rel="$1"
  src="$REPO/$rel"
  out="$RUNTIME_STAGE/$rel"
  case "$rel" in
    Plugins/Extensions/Enigma2UniversalPanel/*)
      out="$PLUGIN_STAGE/${rel#Plugins/Extensions/Enigma2UniversalPanel/}"
      ;;
  esac
  mkdir -p "$(dirname "$out")"

  attempt=1
  while [ "$attempt" -le "$FETCH_RETRIES" ]; do
    if command -v wget >/dev/null 2>&1; then
      if wget -q -T "$FETCH_TIMEOUT" -O "$out" "$src"; then
        return 0
      fi
      rm -f "$out"
    fi
    if command -v curl >/dev/null 2>&1; then
      if curl -fsSL --connect-timeout "$FETCH_TIMEOUT" --max-time "$FETCH_TIMEOUT" -o "$out" "$src"; then
        return 0
      fi
      rm -f "$out"
    fi
    [ "$attempt" -lt "$FETCH_RETRIES" ] && sleep 1
    attempt=$((attempt + 1))
  done
  fail "Unable to download $rel"
}

RUNTIME_FILES="
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
scripts/lib/library.sh
scripts/lib/community.sh
scripts/lib/validation.sh
scripts/lib/update.sh
config/capabilities.json
config/actions.json
config/settings.json
config/adapters.json
config/receivers.json
config/compatibility.json
config/plugin-sources.json
plugins/catalog.json
plugins/community.json
plugins/community-admitted.json
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

PLUGIN_FILES="
Plugins/Extensions/Enigma2UniversalPanel/__init__.py
Plugins/Extensions/Enigma2UniversalPanel/plugin.py
Plugins/Extensions/Enigma2UniversalPanel/actions.py
Plugins/Extensions/Enigma2UniversalPanel/audit_history.py
Plugins/Extensions/Enigma2UniversalPanel/debug.py
Plugins/Extensions/Enigma2UniversalPanel/screens.py
"

info "Starting installer v$VERSION"
info "Source: $REPO"

for rel in $RUNTIME_FILES; do
  fetch "$rel"
done
for rel in $PLUGIN_FILES; do
  fetch "$rel"
done

info "Validating downloaded release..."

for rel in $RUNTIME_FILES; do
  file="$RUNTIME_STAGE/$rel"
  [ -s "$file" ] || fail "Downloaded runtime file is missing or empty: $rel"
  case "$rel" in
    *.sh) sh -n "$file" || fail "Shell syntax check failed: $rel" ;;
  esac
done

for rel in $PLUGIN_FILES; do
  file="$PLUGIN_STAGE/${rel#Plugins/Extensions/Enigma2UniversalPanel/}"
  [ -s "$file" ] || fail "Downloaded plugin file is missing or empty: $rel"
  "$PYTHON_BIN" -m py_compile "$file" 2>/dev/null || fail "Python syntax check failed: $rel"
done

for rel in $RUNTIME_FILES; do
  case "$rel" in
    *.json)
      file="$RUNTIME_STAGE/$rel"
      "$PYTHON_BIN" - "$file" <<'PY' || fail "JSON validation failed: $rel"
import json, sys
with open(sys.argv[1], "r") as handle:
    json.load(handle)
PY
      ;;
  esac
done

[ "$CHECK_ONLY" = 0 ] || {
  info "Validation-only mode completed successfully."
  exit 0
}

DEPLOY_RUNTIME="$(dirname "$DEST")/.e2panel-next.${PPID:-0}.$$"
DEPLOY_PLUGIN="$PLUGIN_ROOT/.e2panel-next.${PPID:-0}.$$"
STAMP="$(date +%Y%m%d%H%M%S 2>/dev/null || echo "$$")"
BACKUP_DEST="${DEST}.previous-${STAMP}-$$"
BACKUP_PLUGIN="${PLUGIN_ROOT}/Enigma2UniversalPanel.previous-${STAMP}-$$"
BACKUP_BIN="${BIN}.previous-${STAMP}-$$"

mkdir -p "$DEPLOY_RUNTIME" "$DEPLOY_PLUGIN"

cp -R "$RUNTIME_STAGE/." "$DEPLOY_RUNTIME/" || fail "Unable to prepare runtime deployment."
cp -R "$PLUGIN_STAGE/." "$DEPLOY_PLUGIN/" || fail "Unable to prepare plugin deployment."

chmod 755 "$DEPLOY_RUNTIME/panel.sh" "$DEPLOY_RUNTIME/scripts/lib/"*.sh
chmod 644 "$DEPLOY_PLUGIN/"*.py

rollback() {
  info "Rolling back incomplete installation..."
  rm -rf "$DEST" "$PLUGIN_ROOT/Enigma2UniversalPanel" "$DEPLOY_RUNTIME" "$DEPLOY_PLUGIN"
  if [ -e "$BACKUP_DEST" ] || [ -L "$BACKUP_DEST" ]; then mv "$BACKUP_DEST" "$DEST" || true; fi
  if [ -e "$BACKUP_PLUGIN" ] || [ -L "$BACKUP_PLUGIN" ]; then mv "$BACKUP_PLUGIN" "$PLUGIN_ROOT/Enigma2UniversalPanel" || true; fi
  if [ -e "$BACKUP_BIN" ] || [ -L "$BACKUP_BIN" ]; then mv "$BACKUP_BIN" "$BIN" || true; else rm -f "$BIN"; fi
}

[ -e "$DEST" ] || [ -L "$DEST" ] || true
if [ -e "$DEST" ] || [ -L "$DEST" ]; then mv "$DEST" "$BACKUP_DEST" || fail "Unable to preserve existing runtime."
fi
if [ -e "$PLUGIN_ROOT/Enigma2UniversalPanel" ] || [ -L "$PLUGIN_ROOT/Enigma2UniversalPanel" ]; then
  mv "$PLUGIN_ROOT/Enigma2UniversalPanel" "$BACKUP_PLUGIN" || {
    rollback
    fail "Unable to preserve existing plugin."
  }
fi
if [ -e "$BIN" ] || [ -L "$BIN" ]; then mv "$BIN" "$BACKUP_BIN" || {
  rollback
  fail "Unable to preserve existing command link."
}
fi

if ! mv "$DEPLOY_RUNTIME" "$DEST"; then
  rollback
  fail "Runtime deployment failed."
fi
if ! mv "$DEPLOY_PLUGIN" "$PLUGIN_ROOT/Enigma2UniversalPanel"; then
  rollback
  fail "Plugin deployment failed."
fi
mkdir -p "$(dirname "$BIN")" || {
  rollback
  fail "Unable to create command directory: $(dirname "$BIN")"
}
if ! ln -s "$DEST/panel.sh" "$BIN"; then
  rollback
  fail "Unable to create e2panel command link."
fi

[ -x "$DEST/panel.sh" ] || { rollback; fail "Installed runtime is not executable."; }
sh -n "$DEST/panel.sh" || { rollback; fail "Installed runtime syntax check failed."; }
"$PYTHON_BIN" -m py_compile "$PLUGIN_ROOT/Enigma2UniversalPanel/plugin.py" || {
  rollback
  fail "Installed plugin syntax verification failed."
}

info "Installation files deployed."
if "$BIN" status >/dev/null 2>&1; then
  info "Runtime status verification passed."
else
  rollback
  fail "Post-install runtime status check failed."
fi

rm -rf "$BACKUP_DEST" "$BACKUP_PLUGIN" "$BACKUP_BIN"

if [ "$RESTART_GUI" = 1 ]; then
  info "Restarting Enigma2 GUI..."
  if "$BIN" restart-gui; then
    info "Enigma2 GUI restart initiated."
  else
    fail "Installation succeeded, but GUI restart could not be initiated."
  fi
else
  info "GUI restart not requested. Restart later from Enigma2 or with: $BIN restart-gui"
fi

info "Enigma2 Universal Panel v$VERSION installed successfully."
info "Open: Menu → Plugins → Enigma2 Universal Panel"
