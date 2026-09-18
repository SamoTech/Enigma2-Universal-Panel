#!/bin/sh
# Source-driven plugin/package management.
# No plugin binaries are stored or served by this repository.

plugin_validate_package() {
  case "$1" in
    ""|*[!A-Za-z0-9._+:@%/-]*) error "invalid package identifier"; return 2 ;;
  esac
}

plugin_package_manager() {
  detect_all >/dev/null 2>&1
  [ "$E2_PKG" != none ] || { error "no supported package manager detected"; return 1; }
}

plugin_refresh_sources() {
  plugin_package_manager || return 1
  require_root || return 1
  case "$E2_PKG" in
    opkg) info "Refreshing configured opkg feeds"; opkg update ;;
    apt) info "Refreshing configured apt sources"; apt-get update ;;
    ipkg) info "Refreshing configured ipkg feeds"; ipkg update ;;
  esac
}

plugin_list() {
  plugin_package_manager || return 1
  pattern="$1"
  case "$E2_PKG" in
    opkg) if [ -n "$pattern" ]; then opkg list 2>/dev/null | grep -i -- "$pattern"; else opkg list 2>/dev/null; fi ;;
    apt) if has apt-cache; then if [ -n "$pattern" ]; then apt-cache search "$pattern"; else apt-cache pkgnames; fi; else error "apt-cache is required"; return 1; fi ;;
    ipkg) if [ -n "$pattern" ]; then ipkg list 2>/dev/null | grep -i -- "$pattern"; else ipkg list 2>/dev/null; fi ;;
  esac
}

plugin_info() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  case "$E2_PKG" in
    opkg) opkg info "$1" ;;
    apt) apt-cache show "$1" ;;
    ipkg) ipkg info "$1" ;;
  esac
}

plugin_install() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  require_root || return 1
  pkg="$1"
  info "Installing package from configured receiver feeds: $pkg"
  case "$E2_PKG" in
    opkg) opkg install "$pkg" ;;
    apt) DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" ;;
    ipkg) ipkg install "$pkg" ;;
  esac
}

plugin_update() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  require_root || return 1
  pkg="$1"
  info "Updating package from configured receiver feeds: $pkg"
  case "$E2_PKG" in
    opkg) opkg update || return 1; opkg install "$pkg" ;;
    apt) apt-get update || return 1; DEBIAN_FRONTEND=noninteractive apt-get install --only-upgrade -y "$pkg" ;;
    ipkg) ipkg update || return 1; ipkg install "$pkg" ;;
  esac
}

plugin_remove() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  require_root || return 1
  pkg="$1"
  info "Removing package: $pkg"
  case "$E2_PKG" in
    opkg) opkg remove "$pkg" ;;
    apt) DEBIAN_FRONTEND=noninteractive apt-get remove -y "$pkg" ;;
    ipkg) ipkg remove "$pkg" ;;
  esac
}

plugin_installed() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  case "$E2_PKG" in
    opkg) opkg status "$1" 2>/dev/null | grep -q "^Status:.*installed" ;;
    apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed" ;;
    ipkg) ipkg status "$1" 2>/dev/null | grep -q "^Status:.*installed" ;;
  esac
}

plugin_source_status() {
  info "Plugin binaries are not stored in this repository."
  info "Installation uses the receiver's configured package feeds."
  info "Detected image: $E2_IMAGE"
  info "Detected package manager: $E2_PKG"
  if [ -r /proc/getFeedsUrl ]; then
    printf 'Detected feed URL: '; cat /proc/getFeedsUrl
  fi
}

plugin_source_add_external() {
  error "Arbitrary external feed registration is disabled by policy"
  return 1
}
