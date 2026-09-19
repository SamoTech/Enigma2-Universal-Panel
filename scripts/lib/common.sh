#!/bin/sh
PANEL_VERSION="1.8.0"
PANEL_ROOT="${PANEL_ROOT:-/usr/lib/enigma2-universal-panel}"
PANEL_ETC="${PANEL_ETC:-/etc/enigma2-universal-panel}"
PANEL_LOG="${PANEL_LOG:-/var/log/enigma2-universal-panel.log}"

log() { printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)" "$1" "$2" | tee -a "$PANEL_LOG" >/dev/null; }
info() { log INFO "$1"; }
warn() { log WARN "$1"; }
error() { log ERROR "$1"; }
audit() { log AUDIT "$1"; }
audit_history() {
  [ -r "$PANEL_LOG" ] || { printf 'No audit records available.\n'; return 0; }
  records="$(grep ' \[AUDIT\] ' "$PANEL_LOG" 2>/dev/null | tail -n 20)"
  [ -n "$records" ] || { printf 'No audit records available.\n'; return 0; }
  printf '%s\n' "$records"
}
has() { command -v "$1" >/dev/null 2>&1; }
require_root() { [ "$(id -u 2>/dev/null)" = "0" ] || { error "root privileges required"; return 1; }; }
