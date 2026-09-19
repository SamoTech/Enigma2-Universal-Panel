#!/bin/sh
# Controlled community installer execution. Only explicitly admitted entries may execute.
community_registry() { printf '%s/plugins/community-admitted.json\n' "$PANEL_ROOT"; }
community_python() { has python3 && command -v python3 && return 0; has python && command -v python && return 0; return 1; }
community_field() {
  id="$1"; field="$2"; py="$(community_python)" || return 1
  "$py" - "$(community_registry)" "$id" "$field" <<'PY'
import json, sys
path, wanted_id, field = sys.argv[1:4]
with open(path, encoding="utf-8") as fh: data = json.load(fh)
for entry in data.get("entries") or []:
    if entry.get("id") == wanted_id:
        value = entry.get(field, "")
        if isinstance(value, list): print("\n".join(str(x) for x in value))
        elif value is not None: print(str(value))
        break
PY
}
community_admitted() {
  id="$1"; [ -r "$(community_registry)" ] || { error "community admission registry unavailable"; return 1; }
  [ "$(community_field "$id" execution_status)" = "community_confirmed" ] || { error "Community installer is not admitted: $id"; return 1; }
}
community_image_supported() {
  id="$1"; image="$E2_IMAGE"
  community_field "$id" supported_images | grep -Fxq "$image"
}
community_arch_supported() {
  id="$1"; arch="$E2_ARCH"
  community_field "$id" supported_architectures | grep -Fxq "$arch"
}
community_source_url() {
  id="$1"; repo="$(community_field "$id" repository)"; ref="$(community_field "$id" source_ref)"; path="$(community_field "$id" installer_path)"
  case "$repo:$ref:$path" in https://github.com/*:*:*) ;; *) error "Community source is not an admitted HTTPS GitHub source: $id"; return 1;; esac
  repo_path="$(printf '%s' "$repo" | sed 's#^https://github.com/##')"
  printf 'https://raw.githubusercontent.com/%s/%s/%s\n' "$repo_path" "$ref" "$path"
}
community_blob_sha1() {
  file="$1"; py="$(community_python)" || { error "Python runtime required for source verification"; return 1; }
  "$py" - "$file" <<'PY'
import hashlib, sys
data = open(sys.argv[1], "rb").read()
print(hashlib.sha1(("blob %d\0" % len(data)).encode("ascii") + data).hexdigest())
PY
}
community_contains_unsafe_transport() {
  grep -Eiq -- '--no-check-certificate|-k([[:space:]]|$)|curl[[:space:]].*--insecure|curl[[:space:]].*[[:space:]]-k([[:space:]]|$)|wget[[:space:]].*--no-check-certificate' "$1"
}
community_preview() {
  id="$1"; community_admitted "$id" || return 3; require_capability package_manager || return 1
  community_image_supported "$id" || { error "Community plugin is not admitted for receiver image: $E2_IMAGE"; return 3; }
  community_arch_supported "$id" || { error "Community plugin is not admitted for receiver architecture: $E2_ARCH"; return 3; }
  url="$(community_source_url "$id")" || return 3; expected="$(community_field "$id" installer_blob_sha)"
  [ -n "$expected" ] || { error "Pinned installer hash is missing: $id"; return 3; }
  printf '{\n'
  printf '  "plugin":"%s",\n' "$(plugin_json_escape "$id")"
  printf '  "name":"%s",\n' "$(plugin_json_escape "$(community_field "$id" name)")"
  printf '  "source_url":"%s",\n' "$(plugin_json_escape "$url")"
  printf '  "source_ref":"%s",\n' "$(plugin_json_escape "$(community_field "$id" source_ref)")"
  printf '  "installer_blob_sha":"%s",\n' "$(plugin_json_escape "$expected")"
  printf '  "receiver_image":"%s",\n' "$(plugin_json_escape "$E2_IMAGE")"
  printf '  "receiver_architecture":"%s",\n' "$(plugin_json_escape "$E2_ARCH")"
  printf '  "status":"supported",\n  "action":"install",\n'
  printf '  "requires_gui_restart":%s,\n' "$(community_field "$id" requires_gui_restart)"
  printf '  "requires_reboot":%s\n' "$(community_field "$id" requires_reboot)"
  printf '}\n'
}
community_install() {
  id="$1"; community_admitted "$id" || return 3; require_root || return 1; require_capability package_manager || return 1
  community_image_supported "$id" || { error "Community plugin is not admitted for receiver image: $E2_IMAGE"; return 3; }
  community_arch_supported "$id" || { error "Community plugin is not admitted for receiver architecture: $E2_ARCH"; return 3; }
  url="$(community_source_url "$id")" || return 3; expected="$(community_field "$id" installer_blob_sha)"
  [ -n "$expected" ] || { error "Pinned installer hash is missing: $id"; return 3; }
  tmp="/tmp/e2panel-community-installer.$$"
  if has wget; then wget -q -T 30 -O "$tmp" "$url" || { error "Unable to download admitted community installer"; rm -f "$tmp"; return 1; }
  elif has curl; then curl -fsSL --connect-timeout 30 --max-time 120 -o "$tmp" "$url" || { error "Unable to download admitted community installer"; rm -f "$tmp"; return 1; }
  else error "No HTTPS downloader available"; return 1; fi
  actual="$(community_blob_sha1 "$tmp")"
  [ "$actual" = "$expected" ] || { error "Community installer source hash mismatch: expected=$expected actual=$actual"; rm -f "$tmp"; return 1; }
  community_contains_unsafe_transport "$tmp" && { error "Community installer rejected: insecure transport option detected"; rm -f "$tmp"; return 1; }
  sh -n "$tmp" || { error "Community installer shell syntax validation failed"; rm -f "$tmp"; return 1; }
  community_preview "$id" || { rm -f "$tmp"; return 1; }
  audit "community-install requested id=$id source_ref=$(community_field "$id" source_ref) installer_blob_sha=$expected"
  SKIP_REBOOT=1 /bin/sh "$tmp"; rc=$?; rm -f "$tmp"
  [ "$rc" -eq 0 ] || { error "Community installer failed: id=$id returncode=$rc"; return "$rc"; }
  audit "community-install result=success id=$id"
  printf 'status=installed\nplugin=%s\ninstaller_source=%s\ninstaller_blob_sha=%s\nrequires_gui_restart=%s\nrequires_reboot=%s\n' "$id" "$url" "$expected" "$(community_field "$id" requires_gui_restart)" "$(community_field "$id" requires_reboot)"
}
