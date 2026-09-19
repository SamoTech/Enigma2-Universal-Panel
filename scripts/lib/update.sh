#!/bin/sh
PANEL_UPDATE_INSTALLER_URL="https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh"
PANEL_UPDATE_TIMEOUT="${E2PANEL_FETCH_TIMEOUT:-30}"
PANEL_UPDATE_RETRIES="${E2PANEL_FETCH_RETRIES:-3}"

# Compare dotted numeric versions without relying on sort -V (BusyBox compatible).
# Returns 0 when first version is newer, 1 when equal, 2 when older.
_panel_version_compare() {
  first="$1"
  second="$2"
  old_ifs="$IFS"
  IFS=.
  set -- $first
  a1="${1:-0}"; a2="${2:-0}"; a3="${3:-0}"; a4="${4:-0}"
  IFS=.
  set -- $second
  b1="${1:-0}"; b2="${2:-0}"; b3="${3:-0}"; b4="${4:-0}"
  IFS="$old_ifs"
  for pair in "$a1:$b1" "$a2:$b2" "$a3:$b3" "$a4:$b4"; do
    a="${pair%%:*}"; b="${pair#*:}"
    [ "$a" -gt "$b" ] 2>/dev/null && return 0
    [ "$a" -lt "$b" ] 2>/dev/null && return 2
  done
  return 1
}

_update_fetch() {
  url="$1"
  out="$2"
  attempt=1
  while [ "$attempt" -le "$PANEL_UPDATE_RETRIES" ]; do
    if command -v wget >/dev/null 2>&1; then
      if wget -q -T "$PANEL_UPDATE_TIMEOUT" -O "$out" "$url"; then
        return 0
      fi
      rm -f "$out"
    fi
    if command -v curl >/dev/null 2>&1; then
      if curl -fsSL --connect-timeout "$PANEL_UPDATE_TIMEOUT" --max-time "$PANEL_UPDATE_TIMEOUT" -o "$out" "$url"; then
        return 0
      fi
      rm -f "$out"
    fi
    [ "$attempt" -lt "$PANEL_UPDATE_RETRIES" ] && sleep 1
    attempt=$((attempt + 1))
  done
  return 1
}

panel_update_check() {
  tmp="$(mktemp /tmp/e2panel-self-update-check.XXXXXX)" || {
    printf 'status=failed\nreason=unable_to_create_staging_file\n'
    return 1
  }

  if ! _update_fetch "$PANEL_UPDATE_INSTALLER_URL" "$tmp"; then
    rm -f "$tmp"
    printf 'status=failed\nreason=unable_to_download_official_installer\n'
    return 1
  fi

  if ! sh -n "$tmp"; then
    rm -f "$tmp"
    printf 'status=failed\nreason=installer_syntax_validation_failed\n'
    return 1
  fi

  latest_version="$(sed -n 's/^VERSION="\\([^"]*\\)"$/\\1/p' "$tmp" | head -n 1)"
  rm -f "$tmp"
  case "$latest_version" in
    ''|*[!0-9.]*) printf 'status=failed\nreason=invalid_official_installer_version\n'; return 1 ;;
  esac

  if _panel_version_compare "$latest_version" "$PANEL_VERSION"; then
    printf 'status=available\ncurrent_version=%s\nlatest_version=%s\nupdate_available=1\n' "$PANEL_VERSION" "$latest_version"
  else
    compare_rc=$?
    if [ "$compare_rc" -eq 1 ]; then
      printf 'status=current\ncurrent_version=%s\nlatest_version=%s\nupdate_available=0\n' "$PANEL_VERSION" "$latest_version"
    else
      printf 'status=local_newer\ncurrent_version=%s\nlatest_version=%s\nupdate_available=0\n' "$PANEL_VERSION" "$latest_version"
    fi
  fi
  return 0
}

panel_update() {
  tmp="$(mktemp /tmp/e2panel-self-update.XXXXXX)" || {
    printf 'status=failed\nreason=unable_to_create_staging_file\n'
    return 1
  }

  if ! _update_fetch "$PANEL_UPDATE_INSTALLER_URL" "$tmp"; then
    rm -f "$tmp"
    printf 'status=failed\nreason=unable_to_download_official_installer\n'
    return 1
  fi

  if ! sh -n "$tmp"; then
    rm -f "$tmp"
    printf 'status=failed\nreason=installer_syntax_validation_failed\n'
    return 1
  fi

  version="$(sed -n 's/^VERSION="\([^"]*\)"$/\1/p' "$tmp" | head -n 1)"
  case "$version" in
    ''|*[!0-9.]*)
      rm -f "$tmp"
      printf 'status=failed\nreason=invalid_official_installer_version\n'
      return 1
      ;;
  esac

  if _panel_version_compare "$version" "$PANEL_VERSION"; then
    :
  else
    compare_rc=$?
    rm -f "$tmp"
    if [ "$compare_rc" -eq 1 ]; then
      printf 'status=current\ncurrent_version=%s\nlatest_version=%s\nupdate_available=0\n' "$PANEL_VERSION" "$version"
    else
      printf 'status=blocked\ncurrent_version=%s\ntarget_version=%s\nreason=remote_release_is_not_newer\n' "$PANEL_VERSION" "$version"
    fi
    return 1
  fi

  same_version=0
  [ "$version" = "$PANEL_VERSION" ] && same_version=1

  if ! sh "$tmp" --no-restart; then
    rm -f "$tmp"
    printf 'status=failed\ncurrent_version=%s\ntarget_version=%s\nreason=installer_failed\n' "$PANEL_VERSION" "$version"
    return 1
  fi

  rm -f "$tmp"
  if [ "$same_version" -eq 1 ]; then
    printf 'status=refreshed\nprevious_version=%s\ntarget_version=%s\nrestart_required=1\n' "$PANEL_VERSION" "$version"
  else
    printf 'status=updated\nprevious_version=%s\ntarget_version=%s\nrestart_required=1\n' "$PANEL_VERSION" "$version"
  fi
  return 0
}
