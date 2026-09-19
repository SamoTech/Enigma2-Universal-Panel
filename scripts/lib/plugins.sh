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
plugin_feed_inventory() {
  case "$E2_PKG" in
    opkg)
      for f in /etc/opkg/*.conf; do
        [ -r "$f" ] || continue
        while IFS= read -r line; do
          case "$line" in
            src*) set -- $line; [ "$#" -ge 3 ] && printf '%s\t%s\n' "$1" "$3" ;;
          esac
        done < "$f"
      done ;;
    apt)
      for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
        [ -r "$f" ] || continue
        grep -E '^[[:space:]]*(deb|deb-src)[[:space:]]+' "$f" 2>/dev/null |
          while IFS= read -r line; do
            set -- $line; [ "$#" -ge 2 ] && printf '%s\t%s\n' "$1" "$2"
          done
      done ;;
    ipkg)
      [ -r /etc/ipkg.conf ] || return 0
      grep -E '^[[:space:]]*src[[:space:]]+' /etc/ipkg.conf 2>/dev/null |
        while IFS= read -r line; do
          set -- $line; [ "$#" -ge 3 ] && printf '%s\t%s\n' "$1" "$3"
        done
      ;;
  esac
}
plugin_feed_urls() {
  [ -r /proc/getFeedsUrl ] && cat /proc/getFeedsUrl
  plugin_feed_inventory | awk -F '\t' 'NF >= 2 {print $2}'
}
plugin_refresh_sources() {
  plugin_package_manager || return 1
  require_root || return 1
  case "$E2_PKG" in
    opkg) info "Refreshing configured opkg feeds"; opkg update ;;
    apt) info "Refreshing configured apt sources"; apt-get update ;;
    ipkg) info "Refreshing configured ipkg feeds"; ipkg update ;;
    dpkg) error "No configured Debian feed refresh command is available"; return 1 ;;
  esac
}
plugin_list() {
  plugin_package_manager || return 1
  pattern="$1"
  case "$E2_PKG" in
    opkg) [ -n "$pattern" ] && opkg list 2>/dev/null | grep -i -- "$pattern" || opkg list 2>/dev/null ;;
    apt) has apt-cache || { error "apt-cache is required"; return 1; }; [ -n "$pattern" ] && apt-cache search "$pattern" || apt-cache pkgnames ;;
    ipkg) [ -n "$pattern" ] && ipkg list 2>/dev/null | grep -i -- "$pattern" || ipkg list 2>/dev/null ;;
  esac
}
plugin_info() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  case "$E2_PKG" in
    opkg) opkg info "$1";;
    apt) apt-cache show "$1";;
    ipkg) ipkg info "$1";;
    dpkg) dpkg-query -s "$1";;
  esac
}
plugin_install() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  require_root || return 1
  info "Installing package from configured receiver feeds: $1"
  case "$E2_PKG" in
    opkg) opkg install "$1";;
    apt) DEBIAN_FRONTEND=noninteractive apt-get install -y "$1";;
    ipkg) ipkg install "$1";;
    dpkg) error "Debian receiver has no supported configured-feed installer"; return 1;;
  esac
}
plugin_update() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  require_root || return 1
  case "$E2_PKG" in
    opkg) opkg update || return 1; opkg install "$1" ;;
    apt) apt-get update || return 1; DEBIAN_FRONTEND=noninteractive apt-get install --only-upgrade -y "$1" ;;
    ipkg) ipkg update || return 1; ipkg install "$1" ;;
    dpkg) error "Debian receiver has no supported configured-feed updater"; return 1 ;;
  esac
}
plugin_remove() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  require_root || return 1
  info "Removing package: $1"
  case "$E2_PKG" in
    opkg) opkg remove "$1";;
    apt) DEBIAN_FRONTEND=noninteractive apt-get remove -y "$1";;
    ipkg) ipkg remove "$1";;
    dpkg) error "Debian receiver removal requires an apt-capable configured source"; return 1;;
  esac
}
plugin_installed() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  case "$E2_PKG" in
    opkg) opkg status "$1" 2>/dev/null | grep -q "^Status:.*installed" ;;
    apt) dpkg-query -W -f='%{Status}' "$1" 2>/dev/null | grep -q "install ok installed" ;;
    ipkg) ipkg status "$1" 2>/dev/null | grep -q "^Status:.*installed" ;;
    dpkg) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed" ;;
  esac
}
plugin_source_status() {
  detect_all
  info "Plugin binaries are not stored in this repository."
  info "Installation uses the receiver's configured package feeds."
  info "Detected image: $E2_IMAGE"
  info "Detected architecture: $E2_ARCH"
  info "Detected package manager: $E2_PKG"
  info "Detected network: $E2_NETWORK"
  [ -r /proc/getFeedsUrl ] && { printf 'Native feed URL: '; cat /proc/getFeedsUrl; }
  printf 'Configured feed entries:\n'
  plugin_feed_inventory | while IFS='	' read -r kind uri; do
    [ -n "$uri" ] && printf '  %s %s\n' "$kind" "$uri"
  done
}
plugin_json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g; s/\r/\\r/g; s/\n/\\n/g'
}
plugin_package_state() {
  detect_all
  feeds_file="/tmp/e2panel-feeds.$$"
  packages_file="/tmp/e2panel-packages.$$"
  available_file="/tmp/e2panel-available.$$"
  tab="	"
  trap 'rm -f "$feeds_file" "$packages_file" "$available_file" "$feeds_file.dedup"' EXIT HUP INT TERM

  : >"$feeds_file"
  if [ -r /proc/getFeedsUrl ]; then
    while IFS= read -r uri; do
      [ -n "$uri" ] && printf 'native\t%s\t/proc/getFeedsUrl\n' "$uri" >>"$feeds_file"
    done < /proc/getFeedsUrl
  fi
  plugin_feed_inventory | while IFS="$tab" read -r kind uri; do
    [ -n "$uri" ] && printf 'configured\t%s\t/etc package-manager source configuration\n' "$uri" >>"$feeds_file"
  done
  awk -F '\t' 'NF >= 2 && !seen[$2]++' "$feeds_file" >"$feeds_file.dedup"
  mv "$feeds_file.dedup" "$feeds_file"

  case "$E2_PKG" in
    opkg)
      opkg list-installed 2>/dev/null | awk -F ' - ' '{print $1"\t"$2"\tall"}' >"$packages_file"
      opkg list 2>/dev/null | awk 'NF >= 3 {print $1"\t"$3"\tunknown"}' >"$available_file"
      ;;
    apt)
      dpkg-query -W -f='%{Package}\t%{Version}\t%{Architecture}\n' 2>/dev/null >"$packages_file"
      apt-cache pkgnames 2>/dev/null | while IFS= read -r name; do
        [ -n "$name" ] && printf '%s\tunknown\tunknown\n' "$name"
      done >"$available_file"
      ;;
    ipkg)
      ipkg list_installed 2>/dev/null | awk -F ' - ' '{print $1"\t"$2"\tall"}' >"$packages_file"
      ipkg list 2>/dev/null | awk 'NF >= 3 {print $1"\t"$3"\tunknown"}' >"$available_file"
      ;;
    dpkg)
      dpkg-query -W -f='${Package}\t${Version}\t${Architecture}\n' 2>/dev/null >"$packages_file"
      : >"$available_file"
      ;;
    *)
      : >"$packages_file"
      : >"$available_file"
      ;;
  esac

  printf '{\n'
  printf '  "schema_version": 1,\n'
  printf '  "timestamp": "%s",\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
  printf '  "image": "%s",\n' "$(plugin_json_escape "$E2_IMAGE")"
  printf '  "architecture": "%s",\n' "$(plugin_json_escape "$E2_ARCH")"
  printf '  "package_manager": "%s",\n' "$(plugin_json_escape "$E2_PKG")"
  printf '  "network": "%s",\n' "$(plugin_json_escape "$E2_NETWORK")"

  printf '  "feeds": ['
  first=1
  while IFS="$tab" read -r source uri evidence; do
    [ -n "$uri" ] || continue
    [ "$first" -eq 0 ] && printf ','
    printf '\n    {"id":"%s","uri":"%s","enabled":true,"source":"%s","evidence":"%s"}' \
      "$(plugin_json_escape "$source-$uri")" "$(plugin_json_escape "$uri")" \
      "$(plugin_json_escape "$source")" "$(plugin_json_escape "$evidence")"
    first=0
  done <"$feeds_file"
  printf '\n  ],\n'

  printf '  "installed_packages": ['
  first=1
  while IFS="$tab" read -r name version arch; do
    [ -n "$name" ] || continue
    [ "$first" -eq 0 ] && printf ','
    printf '\n    {"name":"%s","version":"%s","architecture":"%s","status":"installed","source":null}' \
      "$(plugin_json_escape "$name")" "$(plugin_json_escape "$version")" "$(plugin_json_escape "$arch")"
    first=0
  done <"$packages_file"
  printf '\n  ],\n'

  printf '  "available_packages": ['
  first=1
  while IFS="$tab" read -r name version arch; do
    [ -n "$name" ] || continue
    [ "$first" -eq 0 ] && printf ','
    printf '\n    {"name":"%s","version":"%s","architecture":"%s","source":null}' \
      "$(plugin_json_escape "$name")" "$(plugin_json_escape "$version")" "$(plugin_json_escape "$arch")"
    first=0
  done <"$available_file"
  printf '\n  ],\n'
  printf '  "updates": [],\n'
  printf '  "dependencies": [],\n'
  printf '  "conflicts": []\n'
  printf '}\n'
  trap - EXIT HUP INT TERM
  rm -f "$feeds_file" "$packages_file" "$available_file"
}

plugin_source_add_external() {
  error "Arbitrary external feed registration is disabled by policy"
  return 1
}


community_catalog() {
  [ -r "$PANEL_ROOT/plugins/community.json" ] || {
    error "Community installer registry is unavailable"
    return 1
  }
  cat "$PANEL_ROOT/plugins/community.json"
}
