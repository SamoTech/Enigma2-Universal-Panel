#!/bin/sh
# Plugin/package resolution and preflight policy.
# Preview is read-only; installation is allowed only after all required checks pass.

plugin_catalog_block() {
  id="$1"
  awk -v wanted="$id" '
    /"id"[[:space:]]*:/ {
      line=$0
      if (line ~ /"id"[[:space:]]*:[[:space:]]*"/) {
        split(line,a,"\"")
        current=a[4]
      }
    }
    current == wanted { print }
    current == wanted && /"requires_gui_restart"[[:space:]]*:/ { found=1 }
    current == wanted && found && /^[[:space:]]*},[[:space:]]*$/ { exit }
  ' "$PANEL_ROOT/plugins/catalog.json"
}

plugin_catalog_field() {
  id="$1"; field="$2"
  value="$(plugin_catalog_block "$id" | sed -n 's/.*"'$field'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$value" ] && { printf '%s\n' "$value"; return 0; }
  plugin_catalog_block "$id" | sed -n 's/.*"'$field'"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p' | head -1
}

plugin_catalog_list() {
  id="$1"; field="$2"
  plugin_catalog_block "$id" | awk -v f="$field" '
    index($0, "\"" f "\"") && index($0, "[") { inlist=1; next }
    inlist && index($0, "]") { exit }
    inlist {
      while (match($0, /"[^"]+"/)) {
        v=substr($0, RSTART+1, RLENGTH-2)
        print v
        $0=substr($0, RSTART+RLENGTH)
      }
    }
  '
}

plugin_json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

plugin_catalog_match_image() {
  id="$1"; image="$2"
  while IFS= read -r allowed; do
    case "$allowed" in
      "$image"|compatible-enigma2) return 0 ;;
      oe-alliance-family)
        case "$image" in openatv|openvix|openpli|openhdf|opendroid|openeight|openld) return 0;; esac ;;
    esac
  done <<EOF
$(plugin_catalog_list "$id" images)
EOF
  return 1
}

plugin_catalog_match_arch() {
  id="$1"; arch="$2"
  while IFS= read -r allowed; do
    case "$allowed" in all|"$arch") return 0;; esac
  done <<EOF
$(plugin_catalog_list "$id" architectures)
EOF
  return 1
}

plugin_native_metadata() {
  pkg="$1"
  case "$E2_PKG" in
    opkg) opkg info "$pkg" 2>/dev/null ;;
    apt) apt-cache show "$pkg" 2>/dev/null ;;
    ipkg) ipkg info "$pkg" 2>/dev/null ;;
  esac
}

plugin_native_field() {
  pkg="$1"; field="$2"
  plugin_native_metadata "$pkg" | sed -n 's/^'"$field"'[[:space:]]*:[[:space:]]*//p' | head -1
}

plugin_native_arch_compatibility() {
  native_arch="$1"
  receiver_arch="$2"
  case "$native_arch" in
    all|"$receiver_arch") printf 'true\n' ;;
    ""|unknown) printf 'unknown\n' ;;
    *) printf 'false\n' ;;
  esac
}

plugin_native_candidate() {
  pkg="$1"
  case "$E2_PKG" in
    opkg) opkg list 2>/dev/null | awk -v p="$pkg" '$1 == p {print $3; exit}' ;;
    apt) apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2; exit}' ;;
    ipkg) ipkg list 2>/dev/null | awk -v p="$pkg" '$1 == p {print $3; exit}' ;;
  esac
}

plugin_native_installed_version() {
  pkg="$1"
  case "$E2_PKG" in
    opkg) opkg status "$pkg" 2>/dev/null | sed -n 's/^Version:[[:space:]]*//p' | head -1 ;;
    apt) dpkg-query -W -f='%{Version}' "$pkg" 2>/dev/null ;;
    ipkg) ipkg status "$pkg" 2>/dev/null | sed -n 's/^Version:[[:space:]]*//p' | head -1 ;;
  esac
}

plugin_dep_clean() {
  printf '%s' "$1" | sed 's/[<>=].*$//; s/([^)]*)//g'
}

plugin_dependency_status() {
  deps="$1"
  [ -n "$deps" ] || { printf 'none'; return 0; }
  for dep in $(printf '%s' "$deps" | tr ',|' '  '); do
    dep="$(plugin_dep_clean "$dep")"
    [ -n "$dep" ] || continue
    case "$E2_PKG" in
      opkg) opkg status "$dep" 2>/dev/null | grep -q '^Status:.*installed' || printf 'missing:%s ' "$dep" ;;
      apt) dpkg-query -W -f='%{Status}' "$dep" 2>/dev/null | grep -q 'install ok installed' || printf 'missing:%s ' "$dep" ;;
      ipkg) ipkg status "$dep" 2>/dev/null | grep -q '^Status:.*installed' || printf 'missing:%s ' "$dep" ;;
    esac
  done
}

plugin_conflict_status() {
  conflicts="$1"
  [ -n "$conflicts" ] || { printf 'none'; return 0; }
  for conflict in $(printf '%s' "$conflicts" | tr ',|' '  '); do
    conflict="$(plugin_dep_clean "$conflict")"
    [ -n "$conflict" ] || continue
    plugin_installed "$conflict" 2>/dev/null && printf 'installed:%s ' "$conflict"
  done
}

plugin_resolve() {
  plugin_validate_package "$1" || return 2
  plugin_package_manager || return 1
  id="$1"
  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || { error "plugin catalog unavailable"; return 1; }
  pkg="$(plugin_catalog_field "$id" package_name)"
  case "$pkg" in
    ""|unknown|"image/feed dependent")
      info "No authoritative package mapping for plugin: $id"
      info "Search the receiver feed instead; do not guess a package name."
      plugin_list "$id"
      return 3 ;;
    *) printf '%s\n' "$pkg" ;;
  esac
}

plugin_preview() {
  id="$1"
  plugin_validate_package "$id" || return 2
  plugin_package_manager || return 1
  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || { error "plugin catalog unavailable"; return 1; }

  pkg="$(plugin_catalog_field "$id" package_name)"
  [ -n "$pkg" ] || { error "unknown plugin ID: $id"; return 3; }
  case "$pkg" in unknown|"image/feed dependent") error "No authoritative package mapping for plugin: $id"; return 3;; esac

  installed="$(plugin_native_installed_version "$pkg")"
  candidate="$(plugin_native_candidate "$pkg")"
  native_arch="$(plugin_native_field "$pkg" Architecture)"
  deps="$(plugin_native_field "$pkg" Depends)"
  conflicts="$(plugin_native_field "$pkg" Conflicts)"

  image_ok=false; arch_ok=false; native_arch_ok=unknown; candidate_ok=false; deps_ok=true; conflicts_ok=true
  plugin_catalog_match_image "$id" "$E2_IMAGE" && image_ok=true
  plugin_catalog_match_arch "$id" "$E2_ARCH" && arch_ok=true
  native_arch_ok="$(plugin_native_arch_compatibility "$native_arch" "$E2_ARCH")"
  [ -n "$candidate" ] && [ "$candidate" != "(none)" ] && candidate_ok=true

  dep_status="$(plugin_dependency_status "$deps")"
  [ -z "$dep_status" ] || [ "$dep_status" = none ] || deps_ok=false
  conflict_status="$(plugin_conflict_status "$conflicts")"
  [ -z "$conflict_status" ] || [ "$conflict_status" = none ] || conflicts_ok=false

  status=unknown; risk=unknown; action=blocked
  if [ "$image_ok" = true ] && [ "$arch_ok" = true ] && [ "$native_arch_ok" = true ] && [ "$candidate_ok" = true ] && [ "$deps_ok" = true ] && [ "$conflicts_ok" = true ]; then
    status=supported; risk=normal
    if [ -n "$installed" ]; then action=update_or_reinstall; else action=install; fi
  elif [ "$image_ok" = false ] || [ "$arch_ok" = false ] || [ "$native_arch_ok" = false ]; then
    status=unsupported; risk=high
  elif [ "$candidate_ok" = false ] || [ "$native_arch_ok" = unknown ]; then
    status=unknown
  else
    status=partial; risk=high
  fi

  cat <<EOF
{
  "plugin":"$(plugin_json_escape "$id")",
  "package":"$(plugin_json_escape "$pkg")",
  "installed_version":"$(plugin_json_escape "$installed")",
  "candidate_version":"$(plugin_json_escape "$candidate")",
  "receiver_image":"$(plugin_json_escape "$E2_IMAGE")",
  "receiver_architecture":"$(plugin_json_escape "$E2_ARCH")",
  "package_architecture":"$(plugin_json_escape "$native_arch")",
  "package_manager":"$(plugin_json_escape "$E2_PKG")",
  "source":"$(plugin_json_escape "$(plugin_feed_urls 2>/dev/null | head -1)")",
  "dependencies":"$(plugin_json_escape "$deps")",
  "dependency_status":"$(plugin_json_escape "$dep_status")",
  "conflicts":"$(plugin_json_escape "$conflicts")",
  "conflict_status":"$(plugin_json_escape "$conflict_status")",
  "compatibility":{"image":$image_ok,"architecture":$arch_ok,"package_architecture":$native_arch_ok},
  "status":"$status",
  "risk":"$risk",
  "action":"$action",
  "requires_gui_restart":$(plugin_catalog_field "$id" requires_gui_restart | grep -q '^true$' && printf true || printf false),
  "requires_reboot":$(plugin_catalog_field "$id" requires_reboot | grep -q '^true$' && printf true || printf false)
}
EOF
  [ "$status" = supported ]
}


plugin_info_id() {
  id="$1"
  plugin_validate_package "$id" || return 2
  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || { error "plugin catalog unavailable"; return 1; }

  block="$(plugin_catalog_block "$id")"
  [ -n "$block" ] || { error "unknown plugin ID: $id"; return 3; }

  pkg="$(plugin_catalog_field "$id" package_name)"
  installed=""
  candidate=""
  if [ -n "$pkg" ] && [ "$pkg" != unknown ] && [ "$pkg" != "image/feed dependent" ]; then
    plugin_package_manager || return 1
    installed="$(plugin_native_installed_version "$pkg")"
    candidate="$(plugin_native_candidate "$pkg")"
  fi

  images="$(plugin_catalog_list "$id" images | paste -sd ',' -)"
  architectures="$(plugin_catalog_list "$id" architectures | paste -sd ',' -)"
  dependencies="$(plugin_catalog_list "$id" dependencies | paste -sd ',' -)"
  conflicts="$(plugin_catalog_list "$id" conflicts | paste -sd ',' -)"

  printf '{\n'
  printf '  "plugin_id":"%s",\n' "$(plugin_json_escape "$id")"
  printf '  "name":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" name)")"
  printf '  "display_name":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" display_name)")"
  printf '  "category":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" category)")"
  printf '  "subcategory":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" subcategory)")"
  printf '  "author":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" author)")"
  printf '  "source_type":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" source_type)")"
  printf '  "repository":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" repository)")"
  printf '  "package":"%s",\n' "$(plugin_json_escape "$pkg")"
  printf '  "images":"%s",\n' "$(plugin_json_escape "$images")"
  printf '  "architectures":"%s",\n' "$(plugin_json_escape "$architectures")"
  printf '  "dependencies":"%s",\n' "$(plugin_json_escape "$dependencies")"
  printf '  "conflicts":"%s",\n' "$(plugin_json_escape "$conflicts")"
  printf '  "installable":%s,\n' "$(plugin_catalog_field "$id" installable | grep -q '^true
  id="$1"
  preview_file="/tmp/e2panel-plugin-preview.$$"
  if plugin_preview "$id" >"$preview_file" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  cat "$preview_file"
  rm -f "$preview_file"
  [ "$rc" -eq 0 ] || { error "Plugin install blocked by preflight policy"; return "$rc"; }

  resolved="$(plugin_resolve "$id")" || return $?
  plugin_install "$resolved" || return 1
  plugin_installed "$resolved" || { error "Post-install verification failed: $resolved"; return 1; }
  audit "plugin-install-id id=$id package=$resolved verified=true"
}
 && printf true || printf false)"
  printf '  "updatable":%s,\n' "$(plugin_catalog_field "$id" updatable | grep -q '^true
  id="$1"
  preview_file="/tmp/e2panel-plugin-preview.$$"
  if plugin_preview "$id" >"$preview_file" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  cat "$preview_file"
  rm -f "$preview_file"
  [ "$rc" -eq 0 ] || { error "Plugin install blocked by preflight policy"; return "$rc"; }

  resolved="$(plugin_resolve "$id")" || return $?
  plugin_install "$resolved" || return 1
  plugin_installed "$resolved" || { error "Post-install verification failed: $resolved"; return 1; }
  audit "plugin-install-id id=$id package=$resolved verified=true"
}
 && printf true || printf false)"
  printf '  "removable":%s,\n' "$(plugin_catalog_field "$id" removable | grep -q '^true
  id="$1"
  preview_file="/tmp/e2panel-plugin-preview.$$"
  if plugin_preview "$id" >"$preview_file" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  cat "$preview_file"
  rm -f "$preview_file"
  [ "$rc" -eq 0 ] || { error "Plugin install blocked by preflight policy"; return "$rc"; }

  resolved="$(plugin_resolve "$id")" || return $?
  plugin_install "$resolved" || return 1
  plugin_installed "$resolved" || { error "Post-install verification failed: $resolved"; return 1; }
  audit "plugin-install-id id=$id package=$resolved verified=true"
}
 && printf true || printf false)"
  printf '  "requires_gui_restart":%s,\n' "$(plugin_catalog_field "$id" requires_gui_restart | grep -q '^true
  id="$1"
  preview_file="/tmp/e2panel-plugin-preview.$$"
  if plugin_preview "$id" >"$preview_file" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  cat "$preview_file"
  rm -f "$preview_file"
  [ "$rc" -eq 0 ] || { error "Plugin install blocked by preflight policy"; return "$rc"; }

  resolved="$(plugin_resolve "$id")" || return $?
  plugin_install "$resolved" || return 1
  plugin_installed "$resolved" || { error "Post-install verification failed: $resolved"; return 1; }
  audit "plugin-install-id id=$id package=$resolved verified=true"
}
 && printf true || printf false)"
  printf '  "requires_reboot":%s,\n' "$(plugin_catalog_field "$id" requires_reboot | grep -q '^true
  id="$1"
  preview_file="/tmp/e2panel-plugin-preview.$$"
  if plugin_preview "$id" >"$preview_file" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  cat "$preview_file"
  rm -f "$preview_file"
  [ "$rc" -eq 0 ] || { error "Plugin install blocked by preflight policy"; return "$rc"; }

  resolved="$(plugin_resolve "$id")" || return $?
  plugin_install "$resolved" || return 1
  plugin_installed "$resolved" || { error "Post-install verification failed: $resolved"; return 1; }
  audit "plugin-install-id id=$id package=$resolved verified=true"
}
 && printf true || printf false)"
  printf '  "compatibility_confidence":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" compatibility_confidence)")"
  printf '  "status":"%s",\n' "$(plugin_json_escape "$(plugin_catalog_field "$id" status)")"
  printf '  "installed_version":"%s",\n' "$(plugin_json_escape "$installed")"
  printf '  "candidate_version":"%s"\n' "$(plugin_json_escape "$candidate")"
  printf '}\n'
}

plugin_resolve_install() {
  id="$1"
  preview_file="/tmp/e2panel-plugin-preview.$$"
  if plugin_preview "$id" >"$preview_file" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  cat "$preview_file"
  rm -f "$preview_file"
  [ "$rc" -eq 0 ] || { error "Plugin install blocked by preflight policy"; return "$rc"; }

  resolved="$(plugin_resolve "$id")" || return $?
  plugin_install "$resolved" || return 1
  plugin_installed "$resolved" || { error "Post-install verification failed: $resolved"; return 1; }
  audit "plugin-install-id id=$id package=$resolved verified=true"
}
