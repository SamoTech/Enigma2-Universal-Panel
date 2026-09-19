#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

for f in \
  "$ROOT/panel.sh" \
  "$ROOT/install.sh" \
  "$ROOT/scripts/lib/common.sh" \
  "$ROOT/scripts/lib/detect.sh" \
  "$ROOT/scripts/lib/compat.sh" \
  "$ROOT/scripts/lib/plugins.sh" \
  "$ROOT/scripts/lib/plugin-resolver.sh" \
  "$ROOT/scripts/lib/actions.sh" \
  "$ROOT/scripts/lib/community.sh"; do
  sh -n "$f" || fail "shell syntax: $f"
done
pass "shell syntax"

if command -v jq >/dev/null 2>&1; then
  find "$ROOT/config" "$ROOT/plugins" "$ROOT/packages" -type f -name '*.json' -print0 |
    xargs -0 -n1 jq empty >/dev/null || fail "invalid JSON"
else
  printf 'SKIP: jq unavailable; JSON validation delegated to CI runner\n'
fi
pass "JSON policy files"

grep -q '"hosted_in_repository": false' "$ROOT/plugins/catalog.json" || fail "plugin binary hosting policy changed"
grep -q '"mirrored_in_repository": false' "$ROOT/plugins/catalog.json" || fail "plugin mirroring policy changed"
grep -q '"arbitrary_url_installation": false' "$ROOT/plugins/catalog.json" || fail "arbitrary URL policy changed"
grep -q 'Arbitrary external feed registration is disabled by policy' "$ROOT/scripts/lib/plugins.sh" || fail "external feed guard missing"
grep -q 'Plugin install blocked by preflight policy' "$ROOT/scripts/lib/plugin-resolver.sh" || fail "preflight gate missing"
grep -q 'Post-install verification failed' "$ROOT/scripts/lib/plugin-resolver.sh" || fail "postcondition verification missing"
grep -q 'Post-remove verification failed' "$ROOT/scripts/lib/plugin-resolver.sh" || fail "remove postcondition verification missing"
grep -q 'plugin_remove_preview()' "$ROOT/scripts/lib/plugin-resolver.sh" || fail "remove preflight missing"
grep -q 'plugin-remove-id' "$ROOT/panel.sh" || fail "plugin ID remove command missing"
grep -q 'telemetry) print_telemetry' "$ROOT/panel.sh" || fail "telemetry command missing"
[ -f "$ROOT/scripts/lib/telemetry.sh" ] || fail "telemetry module missing"
[ -f "$ROOT/plugins/community.json" ] || fail "community registry missing"
[ -f "$ROOT/plugins/community-admitted.json" ] || fail "community admission registry missing"
grep -q '"health_audit"' "$ROOT/plugins/community.json" || fail "community health audit metadata missing"
grep -q '"pipe_to_shell": false' "$ROOT/plugins/community.json" || fail "community shell-pipe policy changed"
grep -q '"default_execution": "blocked_until_explicitly_admitted"' "$ROOT/plugins/community.json" || fail "community admission policy changed"
grep -q '"arbitrary_shell": false' "$ROOT/plugins/community-admitted.json" || fail "community arbitrary shell policy changed"
grep -q '"allow_admitted_insecure_transport": true' "$ROOT/plugins/community-admitted.json" || fail "admitted insecure transport policy missing"
grep -q '"installer_blob_sha_required": true' "$ROOT/plugins/community-admitted.json" || fail "community source pin policy missing"
grep -q '"tls_certificate_verification_required": true' "$ROOT/plugins/community-admitted.json" || fail "community source TLS policy missing"
grep -q '"community_confirmed"' "$ROOT/plugins/community-admitted.json" || fail "no confirmed community installer admitted"
pass "source/install policy gates"

if find "$ROOT" -type f \( -name '*.ipk' -o -name '*.deb' \) -print -quit | grep -q .; then
  fail "repository contains plugin/package binary"
fi
pass "no plugin/package binaries"

grep -q 'plugin-preview' "$ROOT/panel.sh" || fail "preview command missing"
grep -q 'community-catalog' "$ROOT/panel.sh" || fail "community catalog command missing"
grep -q 'community-install' "$ROOT/panel.sh" || fail "community install command missing"
grep -q 'community-preview' "$ROOT/panel.sh" || fail "community preview command missing"
grep -q 'plugin-install-id' "$ROOT/panel.sh" || fail "plugin ID install command missing"
pass "panel commands"

printf 'All policy tests passed.\n'
