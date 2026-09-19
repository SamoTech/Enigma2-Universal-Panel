#!/bin/sh
set -eu

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

command -v awk >/dev/null 2>&1 || fail "awk unavailable"
command -v mktemp >/dev/null 2>&1 || fail "mktemp unavailable"

PANEL_VERSION="1.10.0"
PANEL_ROOT="/tmp/e2panel-updater-test-root"
. scripts/lib/update.sh

fixture="$(mktemp -d /tmp/e2panel-updater-test.XXXXXX)"
trap 'rm -rf "$fixture"' EXIT HUP INT TERM

write_fixture() {
  version="$1"
  cat >"$fixture/install.sh" <<EOF
#!/bin/sh
VERSION=$version
exit 0
EOF
  cat >"$fixture/version.py" <<EOF
PANEL_VERSION = "$version"
EOF
}

_update_fetch() {
  url="$1"
  out="$2"
  case "$url" in
    "$PANEL_UPDATE_INSTALLER_URL") cp "$fixture/install.sh" "$out" ;;
    "$PANEL_UPDATE_VERSION_URL") cp "$fixture/version.py" "$out" ;;
    *) return 1 ;;
  esac
}

assert_line() {
  output="$1"
  expected="$2"
  printf '%s\n' "$output" | grep -Fqx "$expected" || fail "expected '$expected' in output: $output"
}

write_fixture "1.10.0"
output="$(panel_update_check)"
assert_line "$output" "status=current"
assert_line "$output" "current_version=1.10.0"
assert_line "$output" "latest_version=1.10.0"

output="$(panel_update)"
assert_line "$output" "status=refreshed"
assert_line "$output" "previous_version=1.10.0"
assert_line "$output" "target_version=1.10.0"

write_fixture "1.11.0"
output="$(panel_update_check)"
assert_line "$output" "status=available"
assert_line "$output" "current_version=1.10.0"
assert_line "$output" "latest_version=1.11.0"

output="$(panel_update)"
assert_line "$output" "status=updated"
assert_line "$output" "previous_version=1.10.0"
assert_line "$output" "target_version=1.11.0"

write_fixture "1.9.0"
if panel_update >/tmp/e2panel-updater-blocked.out 2>&1; then
  fail "downgrade was accepted"
fi
grep -Fqx "status=blocked" /tmp/e2panel-updater-blocked.out || fail "downgrade block status missing"
grep -Fq "reason=remote_release_is_not_newer" /tmp/e2panel-updater-blocked.out || fail "downgrade block reason missing"
rm -f /tmp/e2panel-updater-blocked.out

sh -n scripts/lib/update.sh
sh -n install.sh
sh -n scripts/lib/plugins.sh
sh -n scripts/lib/plugin-resolver.sh
grep -q "verify_deployed_file" install.sh || fail "installer payload verification missing"
grep -q "Package installation postcondition failed" scripts/lib/plugins.sh || fail "Store install postcondition missing"
grep -q 'plugin_refresh_sources >/dev/null 2>&1' scripts/lib/plugin-resolver.sh || fail "Store preview refresh guard missing"
pass "self-updater, installer payload verification and Store installation guards pass syntax/policy checks"
