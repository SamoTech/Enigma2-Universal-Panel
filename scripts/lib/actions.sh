#!/bin/sh
_restart_enigma2_detached() {
  if has setsid; then
    setsid sh -c 'sleep 1; init 4 >/dev/null 2>&1; sleep 3; init 3 >/dev/null 2>&1' >/dev/null 2>&1 &
    return 0
  fi
  if has nohup; then
    nohup sh -c 'sleep 1; init 4 >/dev/null 2>&1; sleep 3; init 3 >/dev/null 2>&1' >/dev/null 2>&1 &
    return 0
  fi
  return 1
}

action_restart_enigma2() {
  require_capability enigma2 || return 1
  audit "restart-enigma2 requested"
  if has systemctl; then
    if systemctl restart enigma2 2>/dev/null; then
      audit "restart-enigma2 result=scheduled method=systemctl"
      return 0
    fi
  fi
  if has init; then
    if _restart_enigma2_detached; then
      audit "restart-enigma2 result=scheduled method=detached-init"
      return 0
    fi
  fi
  audit "restart-enigma2 result=failed"
  error "No supported detached Enigma2 restart method detected"
  return 1
}
action_restart_gui() { action_restart_enigma2; }
action_reboot() {
  require_root || return 1
  warn "Reboot requested by controlled action"
  audit "reboot-requested mode=manual"
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
  plugin_install "$pkg" || return 1
  plugin_installed "$pkg" || { error "Post-install verification failed: $pkg"; return 1; }
  audit "package-install package=$pkg verified=true"
}
action_package_update() {
  require_capability package_manager || return 1
  pkg="$1"
  [ -n "$pkg" ] || { error "package name required"; return 2; }
  plugin_validate_package "$pkg" || return 2
  plugin_update "$pkg" || return 1
  plugin_installed "$pkg" || { error "Post-update verification failed: $pkg"; return 1; }
  audit "package-update package=$pkg verified=true"
}
action_package_remove() {
  require_capability package_manager || return 1
  pkg="$1"
  [ -n "$pkg" ] || return 2
  plugin_validate_package "$pkg" || return 2
  plugin_remove "$pkg" || return 1
  plugin_installed "$pkg" && { error "Post-remove verification failed: $pkg"; return 1; }
  audit "package-remove package=$pkg verified=true"
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
