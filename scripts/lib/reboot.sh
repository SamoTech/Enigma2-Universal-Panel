#!/bin/sh
# Persistent reboot intent and post-boot verification for metadata-required reboots.

_reboot_state_file() {
  printf '%s\n' "${PANEL_ETC:-/etc/enigma2-universal-panel}/pending-reboot"
}

_reboot_boot_id() {
  if [ -n "${E2_TEST_BOOT_ID:-}" ]; then
    printf '%s\n' "$E2_TEST_BOOT_ID"
    return 0
  fi
  if [ -r /proc/sys/kernel/random/boot_id ]; then
    tr -d '[:space:]' </proc/sys/kernel/random/boot_id
    return 0
  fi
  if [ -r /proc/uptime ]; then
    # Uptime is not a reboot identity, so do not use it for verification.
    return 1
  fi
  return 1
}

_reboot_valid_plugin_id() {
  value="$1"
  case "$value" in
    ''|*[!a-z0-9._-]*) return 1 ;;
    *) return 0 ;;
  esac
}

_reboot_write_pending() {
  id="$1"
  pkg="$2"
  expected="$3"
  before_boot_id="$4"
  state_file="$(_reboot_state_file)"

  mkdir -p "${PANEL_ETC:-/etc/enigma2-universal-panel}" 2>/dev/null || return 1
  umask 077
  tmp_file="$state_file.tmp.$$"
  {
    printf 'schema_version=1\n'
    printf 'plugin_id=%s\n' "$id"
    printf 'package=%s\n' "$pkg"
    printf 'expected_version=%s\n' "$expected"
    printf 'previous_boot_id=%s\n' "$before_boot_id"
    printf 'requested_at=%s\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf unknown)"
  } >"$tmp_file" || {
    rm -f "$tmp_file"
    return 1
  }
  mv "$tmp_file" "$state_file"
}

reboot_pending() {
  [ -r "$(_reboot_state_file)" ]
}

reboot_status() {
  state_file="$(_reboot_state_file)"
  if ! reboot_pending; then
    printf '{\n  "status":"none"\n}\n'
    return 0
  fi

  plugin_id="$(sed -n 's/^plugin_id=//p' "$state_file" | head -1)"
  package="$(sed -n 's/^package=//p' "$state_file" | head -1)"
  expected_version="$(sed -n 's/^expected_version=//p' "$state_file" | head -1)"
  previous_boot_id="$(sed -n 's/^previous_boot_id=//p' "$state_file" | head -1)"

  current_boot_id="$(_reboot_boot_id 2>/dev/null || true)"
  verified=false
  boot_changed=false
  package_ok=false

  [ -n "${current_boot_id:-}" ] && [ -n "${previous_boot_id:-}" ] &&
    [ "$current_boot_id" != "$previous_boot_id" ] && boot_changed=true

  if [ -n "${package:-}" ] && command -v plugin_native_installed_version >/dev/null 2>&1; then
    installed_now="$(plugin_native_installed_version "$package" 2>/dev/null || true)"
    [ -n "$installed_now" ] && [ "$installed_now" = "${expected_version:-}" ] && package_ok=true
  else
    installed_now=""
  fi

  if [ "$boot_changed" = true ] && [ "$package_ok" = true ]; then
    verified=true
    audit "reboot-verify plugin=${plugin_id:-unknown} package=${package:-unknown} expected=${expected_version:-unknown} verified=true"
    rm -f "$state_file"
  fi

  printf '{\n'
  printf '  "status":"%s",\n' "$( [ "$verified" = true ] && printf verified || printf pending )"
  printf '  "plugin_id":"%s",\n' "$(plugin_json_escape "${plugin_id:-unknown}")"
  printf '  "package":"%s",\n' "$(plugin_json_escape "${package:-unknown}")"
  printf '  "expected_version":"%s",\n' "$(plugin_json_escape "${expected_version:-unknown}")"
  printf '  "previous_boot_id":"%s",\n' "$(plugin_json_escape "${previous_boot_id:-unknown}")"
  printf '  "current_boot_id":"%s",\n' "$(plugin_json_escape "${current_boot_id:-unknown}")"
  printf '  "boot_changed":%s,\n' "$boot_changed"
  printf '  "package_verified":%s\n' "$package_ok"
  printf '}\n'
}

action_reboot_for_plugin() {
  require_root || return 1
  id="$1"
  _reboot_valid_plugin_id "$id" || {
    error "invalid plugin id for reboot request"
    return 2
  }

  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || {
    error "plugin catalog unavailable"
    return 1
  }

  requires_reboot="$(plugin_catalog_field "$id" requires_reboot)"
  [ "$requires_reboot" = true ] || {
    error "Reboot is not declared as required by verified plugin metadata: $id"
    return 3
  }

  pkg="$(plugin_catalog_field "$id" package_name)"
  case "$pkg" in
    ''|unknown|"image/feed dependent")
      error "No authoritative package mapping for reboot verification: $id"
      return 3
      ;;
  esac

  plugin_package_manager || return 1
  expected="$(plugin_native_installed_version "$pkg" 2>/dev/null || true)"
  [ -n "$expected" ] && [ "$expected" != "(none)" ] || {
    error "Required reboot package state is not installed/verified: $pkg"
    return 4
  }

  before_boot_id="$(_reboot_boot_id 2>/dev/null || true)"
  [ -n "$before_boot_id" ] || {
    error "No reboot identity source available; reboot verification is unavailable"
    return 5
  }

  [ ! -r "$(_reboot_state_file)" ] || {
    error "A previous reboot verification is still pending"
    return 6
  }

  _reboot_write_pending "$id" "$pkg" "$expected" "$before_boot_id" || {
    error "Could not persist reboot verification intent"
    return 1
  }

  sync
  audit "reboot-requested plugin=$id package=$pkg expected=$expected"
  if reboot; then
    # Normally unreachable because reboot terminates the session. A test/runtime
    # returning here means the reboot request was accepted but must be verified.
    return 0
  fi

  audit "reboot-requested plugin=$id package=$pkg expected=$expected result=failed"
  rm -f "$(_reboot_state_file)"
  error "Reboot command failed"
  return 1
}
