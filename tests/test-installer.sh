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

grep -q 'installer v1.10.0' "$INSTALL" || fail "installer version missing"
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
grep -q 'scripts/lib/community.sh' "$INSTALL" || fail "community installer runtime file missing"
grep -q 'plugins/community-admitted.json' "$INSTALL" || fail "community admission registry missing"
grep -q 'Plugins/Extensions/Enigma2UniversalPanel/debug.py' "$INSTALL" || fail "native UI debug logger missing"
grep -q 'scripts/lib/validation.sh' "$INSTALL" || fail "receiver validation runtime file missing"
grep -q 'scripts/lib/update.sh' "$INSTALL" || fail "panel self-update runtime file missing"
grep -q 'Plugins/Extensions/Enigma2UniversalPanel/version.py' "$INSTALL" || fail "centralized plugin version file missing"

UPDATE="$ROOT/scripts/lib/update.sh"
sh -n "$UPDATE" || fail "panel self-update shell syntax"
grep -q 'status=refreshed' "$UPDATE" || fail "same-version panel refresh status missing"
grep -q 'same_version=1' "$UPDATE" || fail "same-version refresh path missing"
grep -q 'panel_update_check()' "$UPDATE" || fail "non-destructive update check missing"
grep -q 'PANEL_UPDATE_VERSION_URL=' "$UPDATE" || fail "official version metadata endpoint missing"
grep -q '_panel_extract_panel_version()' "$UPDATE" || fail "panel version metadata parser missing"
grep -q '_panel_validate_version()' "$UPDATE" || fail "strict version validation helper missing"
if grep -q 'sed -n.*VERSION=' "$UPDATE"; then
  fail "strict sed VERSION parser still present"
fi

VERSION_TEST_DIR="$(mktemp -d /tmp/e2panel-version-test.XXXXXX)" || fail "unable to create updater version test directory"
trap 'rm -rf "$VERSION_TEST_DIR"' EXIT HUP INT TERM
cat >"$VERSION_TEST_DIR/install.sh" <<'EOF'
#!/bin/sh
  VERSION = "1.10.0" # release version
EOF
cat >"$VERSION_TEST_DIR/version.py" <<'EOF'
PANEL_VERSION = "1.10.0" # native plugin version
EOF
. "$UPDATE"
[ "$(_panel_extract_installer_version "$VERSION_TEST_DIR/install.sh")" = "1.10.0" ] || fail "installer version extraction failed"
[ "$(_panel_extract_panel_version "$VERSION_TEST_DIR/version.py")" = "1.10.0" ] || fail "panel metadata version extraction failed"
_panel_validate_version "1.10.0" || fail "valid dotted version rejected"
if _panel_validate_version "1.10"; then fail "incomplete version accepted"; fi
if _panel_validate_version "1.10.0x"; then fail "non-numeric version accepted"; fi
pass "BusyBox-safe updater version extraction and validation"

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
