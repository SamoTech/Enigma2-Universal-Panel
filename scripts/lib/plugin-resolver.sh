#!/bin/sh
# Plugin/package resolution. Never guesses native package names.
plugin_resolve() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  id="$1"
  catalog="$PANEL_ROOT/plugins/catalog.json"
  [ -r "$catalog" ] || { error "plugin catalog unavailable"; return 1; }

  # Exact package_name mappings are trusted only when catalog metadata supplies one.
  pkg="$(sed -n '/"id": "'"$id"'"/,/^[[:space:]]*},/p' "$catalog" 2>/dev/null | sed -n 's/.*"package_name": *"\([^"]*\)".*/\1/p' | head -1)"
  case "$pkg" in
    ""|unknown|"image/feed dependent")
      info "No authoritative package mapping for plugin: $id"
      info "Search the receiver feed instead; do not guess a package name."
      plugin_list "$id"
      return 3
      ;;
    *)
      printf '%s\n' "$pkg"
      ;;
  esac
}
plugin_resolve_install() {
  resolved="$(plugin_resolve "$1")" || return $?
  [ -n "$resolved" ] || return 1
  plugin_info "$resolved" || return 1
  plugin_install "$resolved"
}
