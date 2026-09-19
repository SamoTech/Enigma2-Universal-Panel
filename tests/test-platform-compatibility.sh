#!/bin/sh
set -eu

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$1"; }

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
BIN="$TMP/bin"
MOCK="$TMP/root"
mkdir -p "$BIN" "$MOCK/etc/enigma2" "$MOCK/proc/stb/info" "$MOCK/usr/bin" "$MOCK/tmp"
trap 'rm -rf "$TMP"' EXIT

cat >"$BIN/uname" <<'EOF'
#!/bin/sh
printf '%s\n' "${MOCK_UNAME:-aarch64}"
EOF
cat >"$BIN/python3" <<'EOF'
#!/bin/sh
case "$*" in
  *'sys.version_info[0]'*) printf '3\n' ;;
  *'sys.version.split()'*) printf '3.12.0\n' ;;
  *) exit 0 ;;
esac
EOF
cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$BIN/apt-get" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$BIN/dpkg" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$MOCK/usr/bin/enigma2" <<'EOF'
#!/bin/sh
touch "$TMP/enigma2-invoked"
printf '%s\n' 'Enigma2 mock 9.0'
EOF
chmod +x "$BIN/"* "$MOCK/usr/bin/enigma2"

PATH="$BIN:$PATH"
export PATH
export PANEL_ROOT="$ROOT"
export E2_TEST_MODE=1
export E2_TEST_ROOT="$MOCK"

. "$ROOT/scripts/lib/common.sh"
. "$ROOT/scripts/lib/detect.sh"
. "$ROOT/scripts/lib/compat.sh"
. "$ROOT/scripts/lib/compatibility.sh"

reset_root() {
  rm -f "$MOCK/etc/image-version" "$MOCK/etc/os-release" "$MOCK/etc/issue" "$MOCK/etc/hostname"
  rm -f "$MOCK/proc/stb/info/model" "$MOCK/proc/stb/info/boxtype" "$MOCK/proc/stb/info/machine" "$MOCK/proc/stb/info/chipset"
  rm -f "$BIN/opkg" "$BIN/apt-get"
  cat >"$BIN/dpkg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/dpkg"
  MOCK_UNAME=aarch64
  export MOCK_UNAME
}

profile_openatv_dreambox() {
  reset_root
  printf '%s\n' 'Dreambox DM920 UHD' >"$MOCK/proc/stb/info/model"
  printf '%s\n' 'dm920' >"$MOCK/proc/stb/info/boxtype"
  printf '%s\n' 'dreambox' >"$MOCK/etc/hostname"
  printf '%s\n' 'OpenATV 8.0' >"$MOCK/etc/issue"
  cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/opkg"
  detect_all
  select_adapter
  [ "$E2_DEVICE_FAMILY" = dreambox ] || fail "Dreambox device detection"
  [ "$E2_VENDOR" = "Dream Multimedia" ] || fail "Dream Multimedia vendor detection"
  [ "$E2_IMAGE" = openatv ] || fail "OpenATV image detection"
  [ "$E2_IMAGE_FAMILY" = oe-alliance ] || fail "OE-Alliance image family"
  [ "$E2_PACKAGE_FAMILY" = opkg ] || fail "OpenATV package backend"
  [ "$ADAPTER" = openatv ] || fail "OpenATV adapter"
  [ "$E2_ARCH_FAMILY" = arm64 ] || fail "ARM64 detection"
  [ ! -e "$TMP/enigma2-invoked" ] || fail "detection must not execute the Enigma2 binary"
  pass "Dreambox + OpenATV profile"
}

profile_vuplus_openatv_uno4kse() {
  reset_root
  printf '%s\n' 'vuuno4kse' >"$MOCK/proc/stb/info/model"
  printf '%s\n' 'vuuno4kse' >"$MOCK/proc/stb/info/boxtype"
  printf '%s\n' 'OpenATV 8.0' >"$MOCK/etc/issue"
  printf '%s\n' 'vuuno4kse' >"$MOCK/etc/hostname"
  cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/opkg"
  detect_all
  select_adapter
  [ "$E2_DEVICE_FAMILY" = vuplus ] || fail "VU+ device detection"
  [ "$E2_VENDOR" = "VU+" ] || fail "VU+ vendor detection"
  [ "$E2_MODEL" = vuuno4kse ] || fail "VU+ Uno 4K SE model detection"
  [ "$E2_MACHINE" = vuuno4kse ] || fail "VU+ Uno 4K SE machine detection"
  [ "$E2_IMAGE" = openatv ] || fail "OpenATV image detection on VU+"
  [ "$E2_IMAGE_FAMILY" = oe-alliance ] || fail "OpenATV image family on VU+"
  [ "$E2_PACKAGE_FAMILY" = opkg ] || fail "OpenATV opkg backend on VU+"
  [ "$ADAPTER" = openatv ] || fail "OpenATV adapter on VU+"
  [ "$E2_ARCH_FAMILY" = arm64 ] || fail "ARM64 detection on VU+"
  pass "VU+ Uno 4K SE + OpenATV profile"
}

profile_generic_hostname_does_not_imply_vuplus() {
  reset_root
  printf '%s\n' 'Generic Enigma2 Receiver' >"$MOCK/proc/stb/info/model"
  printf '%s\n' 'genericbox' >"$MOCK/proc/stb/info/boxtype"
  printf '%s\n' 'my-uno-bedroom-box' >"$MOCK/etc/hostname"
  printf '%s\n' 'OpenATV 8.0' >"$MOCK/etc/issue"
  cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/opkg"
  detect_all
  [ "$E2_DEVICE_FAMILY" = generic-enigma2 ] || fail "generic device must not be inferred as VU+ from hostname"
  [ "$E2_VENDOR" = unknown ] || fail "generic vendor must remain unknown"
  pass "VU+ detection rejects generic hostname false positives"
}

profile_dreamos_dreambox() {
  reset_root
  E2_TEST_DISABLE_OPKG=1
  export E2_TEST_DISABLE_OPKG
  printf '%s\n' 'Dreambox DM920 UHD' >"$MOCK/proc/stb/info/model"
  printf '%s\n' 'dm920' >"$MOCK/proc/stb/info/boxtype"
  printf '%s\n' 'DreamOS 4.5' >"$MOCK/etc/issue"
  cat >"$BIN/apt-get" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/apt-get"
  detect_all
  select_adapter
  [ "$E2_DEVICE_FAMILY" = dreambox ] || fail "Dreambox device detection on DreamOS"
  [ "$E2_IMAGE" = dreamos ] || fail "DreamOS image detection"
  [ "$E2_IMAGE_FAMILY" = dreamos ] || fail "DreamOS image family"
  [ "$E2_PKG" = apt ] || fail "DreamOS apt backend: pkg=$E2_PKG apt_get=$(command -v apt-get 2>/dev/null || echo missing) dpkg=$(command -v dpkg 2>/dev/null || echo missing)"
  [ "$E2_PACKAGE_FAMILY" = deb ] || fail "DreamOS deb family"
  [ "$ADAPTER" = dreamos ] || fail "DreamOS adapter"
  pass "Dreambox + DreamOS profile"
}

profile_openpli_zgemma() {
  reset_root
  E2_TEST_DISABLE_OPKG=0
  export E2_TEST_DISABLE_OPKG
  printf '%s\n' 'Zgemma H9 Twin' >"$MOCK/proc/stb/info/model"
  printf '%s\n' 'h9twin' >"$MOCK/proc/stb/info/boxtype"
  printf '%s\n' 'OpenPLi 9.2' >"$MOCK/etc/issue"
  cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/opkg"
  detect_all
  select_adapter
  [ "$E2_DEVICE_FAMILY" = zgemma ] || fail "Zgemma device detection"
  [ "$E2_IMAGE" = openpli ] || fail "OpenPLi image detection"
  [ "$E2_IMAGE_FAMILY" = openpli ] || fail "OpenPLi family"
  [ "$E2_PKG" = opkg ] || fail "OpenPLi opkg backend"
  [ "$ADAPTER" = openpli ] || fail "OpenPLi adapter"
  pass "Zgemma + OpenPLi profile"
}

profile_unknown_enigma2() {
  reset_root
  E2_TEST_DISABLE_OPKG=0
  export E2_TEST_DISABLE_OPKG
  printf '%s\n' 'UnknownBox X1' >"$MOCK/proc/stb/info/model"
  printf '%s\n' 'x1' >"$MOCK/proc/stb/info/boxtype"
  : >"$MOCK/etc/issue"
  cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/opkg"
  detect_all
  select_adapter
  [ "$E2_DEVICE_FAMILY" = generic-enigma2 ] || fail "generic device fallback"
  [ "$E2_IMAGE" = generic-enigma2 ] || fail "generic image fallback"
  [ "$E2_IMAGE_FAMILY" = generic-enigma2 ] || fail "generic image family fallback"
  [ "$ADAPTER" = generic-enigma2 ] || fail "generic adapter fallback"
  pass "Unknown Enigma2 fallback"
}

profile_python2_legacy() {
  reset_root
  E2_TEST_DISABLE_PYTHON3=1
  export E2_TEST_DISABLE_PYTHON3
  rm -f "$BIN/python3"
  cat >"$BIN/python" <<'EOF'
#!/bin/sh
case "$*" in
  *'sys.version_info[0]'*) printf '2\n' ;;
  *'sys.version.split()'*) printf '2.7.18\n' ;;
  *) exit 0 ;;
esac
EOF
  chmod +x "$BIN/python"
  cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/opkg"
  detect_all
  capability native_gui || fail "Python 2 native GUI capability"
  [ "$E2_PYTHON_MAJOR" = 2 ] || fail "Python 2 detection"
  [ "$E2_PYTHON_VERSION" = 2.7.18 ] || fail "Python 2 version detection"
  pass "Legacy Python 2 runtime detection"
}

profile_image_separation() {
  reset_root
  printf '%s\n' 'Dreambox DM920 UHD' >"$MOCK/proc/stb/info/model"
  printf '%s\n' 'dm920' >"$MOCK/proc/stb/info/boxtype"
  printf '%s\n' 'Dreambox' >"$MOCK/etc/hostname"
  printf '%s\n' 'OpenATV 8.0' >"$MOCK/etc/issue"
  cat >"$BIN/opkg" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$BIN/opkg"
  detect_all
  [ "$E2_DEVICE_FAMILY" = dreambox ] || fail "device/image separation device"
  [ "$E2_IMAGE" = openatv ] || fail "device/image separation image"
  pass "Device identity is separate from image identity"
}

python3 - "$ROOT/config/compatibility.json" "$ROOT/config/adapters.json" <<'PY'
import json,sys
compat=json.load(open(sys.argv[1]))
adapters=json.load(open(sys.argv[2]))
families={x["id"] for x in adapters["adapters"]}
image_ids={x for family in compat["image_families"] for x in family["images"]}
missing=sorted(x for x in image_ids if x not in families and x not in {"openatv","openvix","openhdf","opendroid","openeight","openld","newnigma2","merlin","oozoon","dreamos","vti","egami","hdmu","pure2","openvision","generic-enigma2"})
assert not missing, "unmapped image IDs: %s" % missing
assert "generic-enigma2" in families
assert "dreamos" in families
assert "dreambox-deb" in families
print("PASS: image-family adapter coverage")
PY

profile_openatv_dreambox
profile_vuplus_openatv_uno4kse
profile_generic_hostname_does_not_imply_vuplus
profile_dreamos_dreambox
profile_openpli_zgemma
profile_unknown_enigma2
profile_python2_legacy
profile_image_separation

printf 'Platform compatibility matrix tests completed.\n'
