#!/bin/sh
set -eu

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
INSTALL="$ROOT/install.sh"

[ -s "$INSTALL" ] || fail "install.sh missing or empty"
sh -n "$INSTALL" || fail "install.sh shell syntax"

grep -q '^# wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh$' "$INSTALL" ||
  fail "primary one-line install command missing"
grep -q '^# curl -fsSL https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh$' "$INSTALL" ||
  fail "curl install command missing"

grep -q 'installer v1.7.0' "$INSTALL" || fail "installer version missing"
grep -q 'REPO="https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main"' "$INSTALL" ||
  fail "bootstrap source is not fixed"
if grep -q 'E2PANEL_REPO' "$INSTALL"; then
  fail "arbitrary installer repository override detected"
fi

grep -q 'wget -q -T "$FETCH_TIMEOUT"' "$INSTALL" || fail "BusyBox-compatible wget timeout missing"
grep -q 'attempt=1' "$INSTALL" || fail "portable retry loop missing"
grep -q 'STAGE="$(mktemp -d /tmp/e2panel-install' "$INSTALL" || fail "download staging missing"
grep -q 'Validating downloaded release' "$INSTALL" || fail "pre-install validation missing"
grep -q 'sh -n "$file"' "$INSTALL" || fail "shell validation missing"
grep -q 'py_compile' "$INSTALL" || fail "Python validation missing"
grep -q 'json.load' "$INSTALL" || fail "JSON validation missing"
grep -q 'scripts/lib/library.sh' "$INSTALL" || fail "plugin library runtime file missing"
grep -q 'Plugins/Extensions/Enigma2UniversalPanel/debug.py' "$INSTALL" || fail "native UI debug logger missing"
grep -q 'scripts/lib/validation.sh' "$INSTALL" || fail "receiver validation runtime file missing"
grep -q 'scripts/lib/update.sh' "$INSTALL" || fail "panel self-update runtime file missing"

grep -q 'BACKUP_DEST=' "$INSTALL" || fail "runtime backup path missing"
grep -q 'BACKUP_PLUGIN=' "$INSTALL" || fail "plugin backup path missing"
grep -q 'rollback()' "$INSTALL" || fail "rollback function missing"
grep -q 'Runtime deployment failed' "$INSTALL" || fail "runtime rollback gate missing"
grep -q 'Plugin deployment failed' "$INSTALL" || fail "plugin rollback gate missing"
grep -q 'Post-install runtime status check failed' "$INSTALL" || fail "post-install rollback gate missing"

grep -q -- '--check' "$INSTALL" || fail "check-only mode missing"
grep -q -- '--restart-gui' "$INSTALL" || fail "explicit restart mode missing"
grep -q -- '--no-restart' "$INSTALL" || fail "explicit no-restart mode missing"

if grep -q -- '--no-check-certificate' "$INSTALL"; then
  fail "TLS certificate bypass detected"
fi
if grep -q 'curl .* -k' "$INSTALL"; then
  fail "curl TLS verification bypass detected"
fi
if grep -q 'rm -rf "$DEST"' "$INSTALL" && ! grep -q 'rollback()' "$INSTALL"; then
  fail "unprotected destructive destination removal detected"
fi

PANEL="$ROOT/panel.sh"
sh -n "$PANEL" || fail "panel shell syntax"
grep -q 'scripts/lib/validation.sh' "$PANEL" || fail "panel validation runtime source missing"
grep -q 'validation-snapshot) print_validation_snapshot' "$PANEL" || fail "validation snapshot command missing"
grep -q 'physical_validation=not_claimed' "$ROOT/scripts/lib/validation.sh" || fail "physical validation boundary missing"
grep -q 'source=live_receiver_runtime' "$ROOT/scripts/lib/validation.sh" || fail "live receiver evidence marker missing"

pass "installer syntax, source lock, transport hardening, validation, rollback, CLI modes and receiver evidence snapshot"
