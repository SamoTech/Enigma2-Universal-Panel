#!/bin/sh
action_restart_enigma2() {
  require_capability enigma2 || return 1
  audit "restart-enigma2 requested"
  if has systemctl; then
    if systemctl restart enigma2 2>/dev/null; then
      audit "restart-enigma2 result=success method=systemctl"
      return 0
    fi
  fi
  if has init; then
    init 4 2>/dev/null
    sleep 2
    if init 3 2>/dev/null; then
      audit "restart-enigma2 result=success method=init"
      return 0
    fi
  fi
  audit "restart-enigma2 result=failed"
  error "No supported Enigma2 restart method detected"
  return 1
}
action_restart_gui() { action_restart_enigma2; }
action_reboot() {
  require_root || return 1
  warn "Reboot requested by controlled action"
  sync
  reboot
}
action_package_update() {
  require_capability package_manager || return 1
  case "$E2_PKG" in
    opkg) opkg update ;;
    apt) apt-get update ;;
    ipkg) ipkg update 2>/dev/null ;;
  esac
}
action_package_install() {
  require_capability package_manager || return 1
  pkg="$1"
  [ -n "$pkg" ] || { error "package name required"; return 2; }
  plugin_validate_package "$pkg" || return 2
  plugin_install "$pkg"
}
action_package_remove() {
  require_capability package_manager || return 1
  pkg="$1"
  [ -n "$pkg" ] || return 2
  plugin_validate_package "$pkg" || return 2
  plugin_remove "$pkg"
}
action_plugin_install() {
  require_capability package_manager || return 1
  plugin_install "$1"
}
action_plugin_update() {
  require_capability package_manager || return 1
  plugin_update "$1"
}
action_plugin_remove() {
  require_capability package_manager || return 1
  plugin_remove "$1"
}
