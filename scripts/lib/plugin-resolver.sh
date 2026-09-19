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
  image_family="${E2_IMAGE_FAMILY:-unknown}"
  while IFS= read -r allowed; do
    case "$allowed" in
      "$image") return 0 ;;
      compatible-enigma2)
        [ "$image_family" != unknown ] && [ "$image_family" != "legacy-unknown" ] && return 0
        ;;
      oe-alliance-family)
        case "$image_family:$image" in
          oe-alliance:*|*:openatv|*:openvix|*:openhdf|*:opendroid|*:openeight|*:openld) return 0 ;;
        esac
        ;;
      dreamos-family)
        case "$image_family" in dreamos|dreambox-deb) return 0;; esac
        ;;
      openpli-family)
        [ "$image_family" = openpli ] && return 0
        ;;
      generic-enigma2)
        [ "$image_family" = generic-enigma2 ] && return 0
        ;;
      *)
        case "$allowed:$image_family" in
          "$image_family:$image_family") return 0 ;;
        esac
        ;;
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
    dpkg) dpkg-query -s "$pkg" 2>/dev/null ;;
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
    all|noarch|"$receiver_arch") printf 'true\n'; return 0 ;;
    ""|unknown) printf 'unknown\n'; return 0 ;;
  esac

  # opkg exposes the architectures actually accepted by the installed image.
  # Do not compare a package's OE machine architecture directly with uname -m:
  # e.g. VU+ ARM receivers can report armv7l while OpenATV feeds use a tuned
  # architecture such as cortexa15hf-neon-vfpv4.
  if [ "$E2_PKG" = opkg ] && command -v opkg >/dev/null 2>&1; then
    if opkg print-architecture 2>/dev/null |
      awk -v wanted="$native_arch" '
        $1 == "arch" && $2 == wanted { found=1 }
        END { exit(found ? 0 : 1) }
      '
    then
      printf 'true\n'
      return 0
    fi
  fi

  case "$E2_PKG:$native_arch:$receiver_arch" in
    apt:all:*|ipkg:all:*) printf 'true\n' ;;
    *) printf 'false\n' ;;
  esac
}

plugin_native_candidate() {
  pkg="$1"
  case "$E2_PKG" in
    opkg)
      opkg list "$pkg" 2>/dev/null |
        awk -v p="$pkg" '$1 == p && $3 != "" {print $3; exit}'
      ;;
    apt) apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2; exit}' ;;
    ipkg)
      ipkg list 2>/dev/null |
        awk -v p="$pkg" '$1 == p && $3 != "" {print $3; exit}'
      ;;
    dpkg) printf '' ;;
  esac
}

plugin_native_installed_version() {
  pkg="$1"
  case "$E2_PKG" in
    opkg) opkg status "$pkg" 2>/dev/null | sed -n 's/^Version:[[:space:]]*//p' | head -1 ;;
    apt) dpkg-query -W -f='%{Version}' "$pkg" 2>/dev/null ;;
    ipkg) ipkg status "$pkg" 2>/dev/null | sed -n 's/^Version:[[:space:]]*//p' | head -1 ;;
    dpkg) dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null ;;
  esac
}

plugin_dep_clean() {
  printf '%s' "$1" | sed 's/[<>=].*$//; s/([^)]*)//g'
}

plugin_dependency_status() {
  deps="$1"
  [ -n "$deps" ] || { printf 'none'; return 0; }
  unresolved=""
  # Dependencies are comma-separated groups; a group may contain alternatives
  # separated by "|". At least one alternative must be installed or available.
  old_ifs="$IFS"
  IFS=","
  set -- $deps
  IFS="$old_ifs"
  for group in "$@"; do
    group="$(printf "%s" "$group" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$group" ] || continue
    resolved=false
    old_ifs="$IFS"
    IFS="|"
    set -- $group
    IFS="$old_ifs"
    for dep in "$@"; do
      dep="$(plugin_dep_clean "$dep")"
      dep="$(printf "%s" "$dep" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      [ -n "$dep" ] || continue
      installed=false
      case "$E2_PKG" in
        opkg) opkg status "$dep" 2>/dev/null | grep -q '^Status:.*installed' && installed=true ;;
        apt) dpkg-query -W -f='${Status}' "$dep" 2>/dev/null | grep -q 'install ok installed' && installed=true ;;
        ipkg) ipkg status "$dep" 2>/dev/null | grep -q '^Status:.*installed' && installed=true ;;
        dpkg) dpkg-query -W -f='${Status}' "$dep" 2>/dev/null | grep -q 'install ok installed' && installed=true ;;
      esac
      if [ "$installed" = true ]; then
        resolved=true
        break
      fi
      candidate="$(plugin_native_candidate "$dep")"
      if [ -n "$candidate" ] && [ "$candidate" != "(none)" ]; then
        resolved=true
        break
      fi
    done
    [ "$resolved" = true ] || unresolved="$unresolved missing:$group"
  done
  [ -n "$unresolved" ] && printf "%s" "$unresolved" || printf "resolvable"
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

  if ! plugin_refresh_sources >/dev/null 2>&1; then
    candidate=""
  fi
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
  [ -z "$dep_status" ] || [ "$dep_status" = none ] || [ "$dep_status" = resolvable ] || deps_ok=false
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


plugin_catalog_bool() {
  id="$1"; field="$2"
  value="$(plugin_catalog_field "$id" "$field")"
  [ "$value" = true ] && printf 'true' || printf 'false'
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

  printf '{
'
  printf '  "plugin_id":"%s",
' "$(plugin_json_escape "$id")"
  printf '  "name":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" name)")"
  printf '  "display_name":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" display_name)")"
  printf '  "category":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" category)")"
  printf '  "subcategory":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" subcategory)")"
  printf '  "author":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" author)")"
  printf '  "source_type":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" source_type)")"
  printf '  "repository":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" repository)")"
  printf '  "package":"%s",
' "$(plugin_json_escape "$pkg")"
  printf '  "images":"%s",
' "$(plugin_json_escape "$images")"
  printf '  "architectures":"%s",
' "$(plugin_json_escape "$architectures")"
  printf '  "dependencies":"%s",
' "$(plugin_json_escape "$dependencies")"
  printf '  "conflicts":"%s",
' "$(plugin_json_escape "$conflicts")"
  printf '  "installable":%s,
' "$(plugin_catalog_bool "$id" installable)"
  printf '  "updatable":%s,
' "$(plugin_catalog_bool "$id" updatable)"
  printf '  "removable":%s,
' "$(plugin_catalog_bool "$id" removable)"
  printf '  "requires_gui_restart":%s,
' "$(plugin_catalog_bool "$id" requires_gui_restart)"
  printf '  "requires_reboot":%s,
' "$(plugin_catalog_bool "$id" requires_reboot)"
  printf '  "compatibility_confidence":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" compatibility_confidence)")"
  printf '  "status":"%s",
' "$(plugin_json_escape "$(plugin_catalog_field "$id" status)")"
  printf '  "installed_version":"%s",
' "$(plugin_json_escape "$installed")"
  printf '  "candidate_version":"%s"
' "$(plugin_json_escape "$candidate")"
  printf '}
'
}

plugin_remove_preview() {
  id="$1"
  plugin_validate_package "$id" || return 2
  plugin_package_manager || return 1
  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || { error "plugin catalog unavailable"; return 1; }

  pkg="$(plugin_catalog_field "$id" package_name)"
  case "$pkg" in
    ""|unknown|"image/feed dependent")
      error "No authoritative package mapping for plugin: $id"
      return 3
      ;;
  esac

  removable="$(plugin_catalog_bool "$id" removable)"
  installed="$(plugin_native_installed_version "$pkg")"
  native_arch="$(plugin_native_field "$pkg" Architecture)"
  image_ok=false
  arch_ok=false
  native_arch_ok=unknown
  removable_ok=false

  plugin_catalog_match_image "$id" "$E2_IMAGE" && image_ok=true
  plugin_catalog_match_arch "$id" "$E2_ARCH" && arch_ok=true
  native_arch_ok="$(plugin_native_arch_compatibility "$native_arch" "$E2_ARCH")"
  [ "$removable" = true ] && removable_ok=true

  status=blocked
  risk=high
  action=blocked
  reason=blocked
  if [ "$removable_ok" = true ] && [ -n "$installed" ] && [ "$image_ok" = true ] && [ "$arch_ok" = true ] && [ "$native_arch_ok" = true ]; then
    status=supported
    action=remove
    reason=ready
  elif [ "$removable_ok" != true ]; then
    reason=plugin_not_declared_removable
  elif [ -z "$installed" ]; then
    reason=plugin_not_installed
  elif [ "$image_ok" = false ] || [ "$arch_ok" = false ] || [ "$native_arch_ok" != true ]; then
    reason=compatibility_not_verified
  fi

  cat <<EOF
{
  "plugin":"$(plugin_json_escape "$id")",
  "package":"$(plugin_json_escape "$pkg")",
  "installed_version":"$(plugin_json_escape "$installed")",
  "receiver_image":"$(plugin_json_escape "$E2_IMAGE")",
  "receiver_architecture":"$(plugin_json_escape "$E2_ARCH")",
  "package_architecture":"$(plugin_json_escape "$native_arch")",
  "package_manager":"$(plugin_json_escape "$E2_PKG")",
  "removable":$removable,
  "compatibility":{"image":$image_ok,"architecture":$arch_ok,"package_architecture":$native_arch_ok},
  "status":"$status",
  "risk":"$risk",
  "action":"$action",
  "reason":"$reason",
  "requires_gui_restart":$(plugin_catalog_bool "$id" requires_gui_restart),
  "requires_reboot":$(plugin_catalog_bool "$id" requires_reboot)
}
EOF
  [ "$status" = supported ]
}

plugin_remove_id() {
  id="$1"
  plugin_validate_package "$id" || return 2
  plugin_package_manager || return 1
  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || { error "plugin catalog unavailable"; return 1; }

  pkg="$(plugin_catalog_field "$id" package_name)"
  case "$pkg" in
    ""|unknown|"image/feed dependent")
      error "No authoritative package mapping for plugin: $id"
      return 3
      ;;
  esac

  installed="$(plugin_native_installed_version "$pkg")"
  [ -n "$installed" ] || { error "Plugin is not installed: $id"; return 4; }
  [ "$(plugin_catalog_bool "$id" removable)" = true ] || { error "Plugin is not declared removable: $id"; return 5; }

  preview_output="$(plugin_remove_preview "$id" 2>&1)"
  rc=$?
  printf '%s\n' "$preview_output"
  [ "$rc" -eq 0 ] || { error "Plugin removal blocked by preflight policy"; return "$rc"; }

  resolved="$(plugin_resolve "$id")" || return $?
  plugin_remove "$resolved" || return 1

  verified="$(plugin_native_installed_version "$resolved")"
  [ -z "$verified" ] || { error "Post-remove verification failed: $resolved"; return 1; }
  audit "plugin-remove-id id=$id package=$resolved verified=true installed_before=$installed installed_after=removed"
}

plugin_update_id() {
  id="$1"
  plugin_validate_package "$id" || return 2
  plugin_package_manager || return 1
  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || { error "plugin catalog unavailable"; return 1; }

  pkg="$(plugin_catalog_field "$id" package_name)"
  case "$pkg" in
    ""|unknown|"image/feed dependent")
      error "No authoritative package mapping for plugin: $id"
      return 3
      ;;
  esac

  installed="$(plugin_native_installed_version "$pkg")"
  [ -n "$installed" ] || { error "Plugin is not installed: $id"; return 4; }

  preview_file="/tmp/e2panel-plugin-update-preview.$"
  if plugin_preview "$id" >"$preview_file" 2>&1; then
    rc=0
  else
    rc=$?
  fi
  cat "$preview_file"
  rm -f "$preview_file"
  [ "$rc" -eq 0 ] || { error "Plugin update blocked by preflight policy"; return "$rc"; }

  resolved="$(plugin_resolve "$id")" || return $?
  plugin_update "$resolved" || return 1
  verified="$(plugin_native_installed_version "$resolved")"
  [ -n "$verified" ] || { error "Post-update verification failed: $resolved"; return 1; }
  audit "plugin-update-id id=$id package=$resolved verified=true installed_before=$installed installed_after=$verified"
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
