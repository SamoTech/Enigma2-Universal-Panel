#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
fail(){ printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass(){ printf 'PASS: %s\n' "$1"; }

for f in "$ROOT/panel.sh" "$ROOT/scripts/lib/"*.sh "$ROOT/install.sh"; do
  sh -n "$f" || fail "syntax: $f"
done
pass "all shell scripts parse"

python3 - <<'PY'
import json, pathlib
root=pathlib.Path(__file__).resolve().parents[1]
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

# Static receiver-behaviour fixtures. These do not claim real receiver execution.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat >"$TMP/opkg.info" <<'EOF'
Package: enigma2-plugin-extensions-openwebif
Version: 2.0
Architecture: all
Depends: python3
Conflicts: old-openwebif
EOF
cat >"$TMP/opkg.status" <<'EOF'
Package: python3
Status: install ok installed
EOF

grep -q '^Package: enigma2-plugin-extensions-openwebif$' "$TMP/opkg.info" || fail "opkg package fixture"
grep -q '^Architecture: all$' "$TMP/opkg.info" || fail "architecture fixture"
grep -q '^Status: install ok installed$' "$TMP/opkg.status" || fail "dependency fixture"
pass "opkg fixture"

cat >"$TMP/unknown-plugin.expected" <<'EOF'
blocked
EOF
printf '%s\n' blocked | cmp -s - "$TMP/unknown-plugin.expected" || fail "unknown mapping fixture"
pass "unknown mapping policy"

cat >"$TMP/unsafe-feed.expected" <<'EOF'
disabled
EOF
printf '%s\n' disabled | cmp -s - "$TMP/unsafe-feed.expected" || fail "external feed policy fixture"
pass "external feed policy"

printf 'Mock receiver harness completed. No real receiver was contacted.\n'
