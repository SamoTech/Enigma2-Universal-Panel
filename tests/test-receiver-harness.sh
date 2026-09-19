#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
fail(){ printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass(){ printf 'PASS: %s\n' "$1"; }

for f in "$ROOT/panel.sh" "$ROOT/scripts/lib/"*.sh "$ROOT/install.sh"; do
  sh -n "$f" || fail "syntax: $f"
done
pass "all shell scripts parse"

python3 - "$ROOT" <<'PY'
import json, pathlib, sys
root=pathlib.Path(sys.argv[1])
for p in root.rglob("*.json"):
    json.loads(p.read_text())
print("PASS: all repository JSON files parse")
PY

if find "$ROOT" -type f \( -name '*.ipk' -o -name '*.deb' \) -print -quit | grep -q .; then
  fail "binary package found"
fi
pass "no binary packages hosted"

grep -q '"arbitrary_url_installation": false' "$ROOT/plugins/catalog.json" || fail "URL policy"
grep -q 'Arbitrary external feed registration is disabled by policy' "$ROOT/scripts/lib/plugins.sh" || fail "feed guard"
grep -q 'plugin-preview' "$ROOT/panel.sh" || fail "preview command"
pass "security policy gates"

TMP="$(mktemp -d)"
BIN="$TMP/bin"
STATE="$TMP/state"
mkdir -p "$BIN" "$STATE"
trap 'rm -rf "$TMP"' EXIT

cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
set -eu
STATE="${MOCK_STATE:?}"
case "${1:-}" in
  list-installed) cat "$STATE/installed" ;;
  status)
    pkg="$2"
    grep -q "^$pkg " "$STATE/installed" || exit 1
    v="$(awk -v p="$pkg" '$1==p{print $2;exit}' "$STATE/installed")"
    printf 'Package: %s\nVersion: %s\nStatus: install ok installed\n' "$pkg" "$v"
    ;;
  info)
    [ "$2" = "enigma2-plugin-extensions-openwebif" ] || exit 1
    printf 'Package: enigma2-plugin-extensions-openwebif\nVersion: 2.0\nArchitecture: all\nDepends: python3\nConflicts: old-openwebif\n'
    ;;
  list) printf '%s\n' 'enigma2-plugin-extensions-openwebif - 2.0' 'python3 - 3.12' ;;
  update) exit 0 ;;
  install)
    [ "$2" = "enigma2-plugin-extensions-openwebif" ] || exit 1
    grep -q "^$2 " "$STATE/installed" || printf '%s 2.0\n' "$2" >>"$STATE/installed"
    ;;
  remove)
    [ "$2" = "enigma2-plugin-extensions-openwebif" ] || exit 1
    grep -v "^$2 " "$STATE/installed" >"$STATE/installed.next"
    mv "$STATE/installed.next" "$STATE/installed"
    ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$BIN/opkg"

cat >"$BIN/uname" <<'EOF'
#!/bin/sh
printf '%s\n' x86_64
EOF
cat >"$BIN/df" <<'EOF'
#!/bin/sh
printf '%s\n' 'Filesystem 1K-blocks Used Available Use% Mounted on' '/dev/mock 100000 1000 99000 1% /'
EOF
cat >"$BIN/ip" <<'EOF'
#!/bin/sh
printf '%s\n' 'default via 192.0.2.1 dev eth0'
EOF

(
  export PATH="$BIN:$PATH"
  export MOCK_STATE="$STATE"
  export PANEL_ROOT="$ROOT"
  export PANEL_ETC="$TMP/etc"
  export PANEL_LOG="$TMP/panel.log"
  export E2_IMAGE=openatv E2_ARCH=x86_64 E2_PKG=opkg E2_NETWORK=online
  printf 'python3 - 3.12\n' >"$STATE/installed"

  . "$ROOT/scripts/lib/common.sh"
  . "$ROOT/scripts/lib/detect.sh"
  . "$ROOT/scripts/lib/plugins.sh"
  . "$ROOT/scripts/lib/plugin-resolver.sh"
  . "$ROOT/scripts/lib/telemetry.sh"

  require_root() { return 0; }

  detect_all() {
    E2_ARCH=x86_64
    E2_ARCH_FAMILY=x86_64
    E2_PKG=opkg
    E2_IMAGE=openatv
    E2_BIN=/usr/bin/enigma2
    E2_VERSION=mock
    E2_STORAGE_AVAILABLE=99000
    E2_NETWORK=online
  }

  [ "$(plugin_native_arch_compatibility all x86_64)" = true ] || fail "architecture all compatibility"
  [ "$(plugin_native_arch_compatibility x86_64 x86_64)" = true ] || fail "exact architecture compatibility"
  [ "$(plugin_native_arch_compatibility armhf x86_64)" = false ] || fail "mismatched architecture rejection"
  [ "$(plugin_native_arch_compatibility unknown x86_64)" = unknown ] || fail "unknown architecture fail-closed state"
  pass "native package architecture policy"

  plugin_package_state >"$TMP/state.json"
  python3 - "$TMP/state.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
assert d["package_manager"] == "opkg"
installed = next(x for x in d["installed_packages"] if x["name"] == "python3")
assert installed["version"] == "3.12"
assert installed["architecture"] == "all"
assert any(x["name"] == "enigma2-plugin-extensions-openwebif" and x["version"] == "2.0" for x in d["available_packages"])
for feed in d["feeds"]:
    assert set(("id","uri","enabled","source","evidence")) <= set(feed)
PY
  pass "mock receiver package-state"

  telemetry_output="$TMP/telemetry.txt"
  print_telemetry >"$telemetry_output"
  grep -q '^load_1=' "$telemetry_output"
  grep -q '^load_5=' "$telemetry_output"
  grep -q '^load_15=' "$telemetry_output"
  grep -q '^ram_total_mb=' "$telemetry_output"
  grep -q '^ram_available_mb=' "$telemetry_output"
  grep -q '^root_total_kb=' "$telemetry_output"
  grep -q '^root_available_kb=' "$telemetry_output"
  grep -q '^python_version=' "$telemetry_output"
  pass "mock receiver telemetry output"

  community_catalog_output="$TMP/community.json"
  community_catalog >"$community_catalog_output"
  python3 - "$community_catalog_output" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
assert d["schema_version"] == 1
assert d["policy"]["repository_hosts_binaries"] is False
assert d["policy"]["arbitrary_urls"] is False
assert d["policy"]["arbitrary_shell"] is False
assert len(d["entries"]) >= 8
assert any(x["id"] == "ajpanel" and x["source_status"] == "verified" for x in d["entries"])
assert any(x["id"] == "aio-panel" and x["execution_status"] == "blocked_unverified_source" for x in d["entries"])
PY
  pass "community installer registry"

  if ! plugin_preview openwebif >"$TMP/preview.json" 2>&1; then
    cat "$TMP/preview.json" >&2
    fail "mock receiver plugin preflight returned blocked"
  fi
  python3 - "$TMP/preview.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
assert d["status"] == "supported"
assert d["candidate_version"] == "2.0"
assert d["compatibility"]["image"] is True
assert d["compatibility"]["architecture"] is True
assert d["compatibility"]["package_architecture"] is True
PY
  pass "mock receiver plugin preflight"

  plugin_resolve_install openwebif >"$TMP/install.log"
  grep -q '^enigma2-plugin-extensions-openwebif 2.0$' "$STATE/installed"
  pass "mock receiver install and postcondition"

  if ! plugin_remove_preview openwebif >"$TMP/remove-preview.json" 2>&1; then
    cat "$TMP/remove-preview.json" >&2
    fail "mock receiver plugin remove preflight returned blocked"
  fi
  python3 - "$TMP/remove-preview.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
assert d["status"] == "supported"
assert d["action"] == "remove"
assert d["removable"] is True
assert d["installed_version"] == "2.0"
assert d["compatibility"]["image"] is True
assert d["compatibility"]["architecture"] is True
assert d["compatibility"]["package_architecture"] is True
PY
  pass "mock receiver plugin remove preflight"

  plugin_remove_id openwebif >"$TMP/remove.log"
  if grep -q '^enigma2-plugin-extensions-openwebif ' "$STATE/installed"; then
    fail "mock receiver remove postcondition"
  fi
  grep -q 'plugin-remove-id id=openwebif package=enigma2-plugin-extensions-openwebif verified=true installed_before=2.0 installed_after=removed' "$PANEL_LOG" ||
    fail "remove audit record missing"
  pass "mock receiver remove and postcondition/audit"

  if plugin_resolve_install openairplay >/dev/null 2>&1; then exit 1; fi
  pass "unknown package mapping blocked"

  if plugin_source_add_external https://attacker.invalid/feed >/dev/null 2>&1; then exit 1; fi
  pass "arbitrary feed blocked"
)

printf 'Mock receiver harness completed. No real receiver was contacted.\n'
