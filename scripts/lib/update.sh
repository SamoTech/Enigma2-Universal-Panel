#!/bin/sh
PANEL_UPDATE_INSTALLER_URL="https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh"
PANEL_UPDATE_TIMEOUT="${E2PANEL_FETCH_TIMEOUT:-30}"
PANEL_UPDATE_RETRIES="${E2PANEL_FETCH_RETRIES:-3}"

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

  same_version=0
  if [ "$version" = "$PANEL_VERSION" ]; then
    same_version=1
  fi

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
