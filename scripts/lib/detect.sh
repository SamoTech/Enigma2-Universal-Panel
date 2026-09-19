#!/bin/sh
# Runtime-first Enigma2 platform detection.
# Device identity and image identity are intentionally separate.

_detect_path() {
  if [ "${E2_TEST_MODE:-0}" = 1 ] && [ -n "${E2_TEST_ROOT:-}" ]; then
    printf '%s%s' "$E2_TEST_ROOT" "$1"
  else
    printf '%s' "$1"
  fi
}

detect_arch() {
  E2_ARCH="$(uname -m 2>/dev/null || echo unknown)"
  case "$E2_ARCH" in
    mips*) E2_ARCH_FAMILY=mips ;;
    armv7*|armhf*) E2_ARCH_FAMILY=arm ;;
    aarch64*) E2_ARCH_FAMILY=arm64 ;;
    x86_64*) E2_ARCH_FAMILY=x86_64 ;;
    i?86*) E2_ARCH_FAMILY=x86 ;;
    *) E2_ARCH_FAMILY=unknown ;;
  esac
}

detect_package_manager() {
  E2_PKG=none
  E2_PACKAGE_FAMILY=unknown
  if [ "${E2_TEST_DISABLE_OPKG:-0}" != 1 ] && has opkg; then
    E2_PKG=opkg
    E2_PACKAGE_FAMILY=opkg
  elif has apt-get && has dpkg; then
    E2_PKG=apt
    E2_PACKAGE_FAMILY=deb
  elif has ipkg; then
    E2_PKG=ipkg
    E2_PACKAGE_FAMILY=ipkg
  elif has dpkg; then
    # Read-only package inventory remains possible, but package installation
    # must stay blocked because no configured Debian feed installer exists.
    E2_PKG=dpkg
    E2_PACKAGE_FAMILY=deb_local_only
  fi
}

detect_python() {
  E2_PYTHON_BIN=unknown
  E2_PYTHON_MAJOR=unknown
  E2_PYTHON_VERSION=unknown

  if [ "${E2_TEST_DISABLE_PYTHON3:-0}" != 1 ] && has python3; then
    E2_PYTHON_BIN="$(command -v python3)"
  elif has python; then
    E2_PYTHON_BIN="$(command -v python)"
  fi

  [ "$E2_PYTHON_BIN" != unknown ] || return 0
  E2_PYTHON_MAJOR="$("$E2_PYTHON_BIN" -c 'import sys; print(sys.version_info[0])' 2>/dev/null || echo unknown)"
  E2_PYTHON_VERSION="$("$E2_PYTHON_BIN" -c 'import sys; print(sys.version.split()[0])' 2>/dev/null || echo unknown)"
}

detect_device() {
  E2_DEVICE_FAMILY=unknown
  E2_VENDOR=unknown
  E2_MODEL=unknown
  E2_MACHINE=unknown
  E2_CHIPSET=unknown

  for f in /proc/stb/info/model /proc/stb/info/boxtype /proc/stb/info/machine /proc/stb/info/board; do
    [ -r "$(_detect_path "$f")" ] || continue
    value="$(tr '\r\n' '  ' < "$(_detect_path "$f")" 2>/dev/null | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//')"
    [ -n "$value" ] || continue
    case "$f" in
      */model) [ "$E2_MODEL" = unknown ] && E2_MODEL="$value" ;;
      */boxtype) [ "$E2_MACHINE" = unknown ] && E2_MACHINE="$value" ;;
      */machine|*/board) [ "$E2_MACHINE" = unknown ] && E2_MACHINE="$value" ;;
    esac
  done

  [ -r "$(_detect_path /proc/stb/info/chipset)" ] && E2_CHIPSET="$(tr '\r\n' '  ' < "$(_detect_path /proc/stb/info/chipset)" 2>/dev/null | sed 's/[[:space:]][[:space:]]*/ /g; s/^ //; s/ $//')"
  [ -n "$E2_CHIPSET" ] || E2_CHIPSET=unknown

  raw="$(printf '%s %s %s %s' "$E2_MODEL" "$E2_MACHINE" "$E2_CHIPSET" "$(hostname 2>/dev/null || true)")"
  low="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"

  case "$low" in
    *dreambox*|*dm500*|*dm520*|*dm525*|*dm820*|*dm900*|*dm920*|*dmone*|*dmtwo*|*"one ultra"*)
      E2_DEVICE_FAMILY=dreambox
      E2_VENDOR="Dream Multimedia"
      ;;
    *vu+*|*vuplus*|*solo*|*duo*|*uno*|*zero*)
      E2_DEVICE_FAMILY=vuplus
      E2_VENDOR="VU+"
      ;;
    *gigablue*)
      E2_DEVICE_FAMILY=gigablue
      E2_VENDOR=GigaBlue
      ;;
    *zgemma*)
      E2_DEVICE_FAMILY=zgemma
      E2_VENDOR=Zgemma
      ;;
    *octagon*|*sf8008*|*sfx6008*|*sfx6018*|*sx88*|*sx888*)
      E2_DEVICE_FAMILY=octagon
      E2_VENDOR=Octagon
      ;;
    *edision*)
      E2_DEVICE_FAMILY=edision
      E2_VENDOR=Edision
      ;;
    *mutant*)
      E2_DEVICE_FAMILY=mutant
      E2_VENDOR=Mutant
      ;;
    *amiko*)
      E2_DEVICE_FAMILY=amiko
      E2_VENDOR=Amiko
      ;;
    *formuler*)
      E2_DEVICE_FAMILY=formuler
      E2_VENDOR=Formuler
      ;;
    *ab-com*|*abcom*)
      E2_DEVICE_FAMILY=abcom
      E2_VENDOR=AB-COM
      ;;
    *axas*)
      E2_DEVICE_FAMILY=axas
      E2_VENDOR=Axas
      ;;
    *golden*interstar*)
      E2_DEVICE_FAMILY=golden-interstar
      E2_VENDOR="Golden Interstar"
      ;;
    *maxytec*)
      E2_DEVICE_FAMILY=maxytec
      E2_VENDOR=Maxytec
      ;;
    *qviart*)
      E2_DEVICE_FAMILY=qviart
      E2_VENDOR=Qviart
      ;;
    *uclan*)
      E2_DEVICE_FAMILY=uclan
      E2_VENDOR=Uclan
      ;;
    *xsarius*)
      E2_DEVICE_FAMILY=xsarius
      E2_VENDOR=Xsarius
      ;;
    *xtrend*)
      E2_DEVICE_FAMILY=xtrend
      E2_VENDOR=Xtrend
      ;;
    *sab*)
      E2_DEVICE_FAMILY=sab
      E2_VENDOR=SAB
      ;;
    *miraclebox*)
      E2_DEVICE_FAMILY=miraclebox
      E2_VENDOR=Miraclebox
      ;;
    *wetek*)
      E2_DEVICE_FAMILY=wetek
      E2_VENDOR=WeTek
      ;;
    *)
      if [ "$E2_MODEL" != unknown ] || [ "$E2_MACHINE" != unknown ]; then
        E2_DEVICE_FAMILY=generic-enigma2
        E2_VENDOR=unknown
      fi
      ;;
  esac
}

detect_image() {
  E2_IMAGE=unknown
  E2_IMAGE_FAMILY=unknown
  E2_IMAGE_VERSION=unknown

  text=""
  for f in /etc/image-version /etc/enigma2/image-version /etc/os-release /etc/issue; do
    [ -r "$(_detect_path "$f")" ] || continue
    text="$text $(cat "$(_detect_path "$f")" 2>/dev/null)"
  done
  low="$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')"

  case "$low" in
    *openatv*) E2_IMAGE=openatv; E2_IMAGE_FAMILY=oe-alliance ;;
    *openvix*|*openvix*) E2_IMAGE=openvix; E2_IMAGE_FAMILY=oe-alliance ;;
    *openhdf*) E2_IMAGE=openhdf; E2_IMAGE_FAMILY=oe-alliance ;;
    *opendroid*) E2_IMAGE=opendroid; E2_IMAGE_FAMILY=oe-alliance ;;
    *openeight*) E2_IMAGE=openeight; E2_IMAGE_FAMILY=oe-alliance ;;
    *openld*) E2_IMAGE=openld; E2_IMAGE_FAMILY=oe-alliance ;;
    *openpli*) E2_IMAGE=openpli; E2_IMAGE_FAMILY=openpli ;;
    *dreamos*|*dreambox*|*"dream multimedia"*) E2_IMAGE=dreamos; E2_IMAGE_FAMILY=dreamos ;;
    *newnigma2*) E2_IMAGE=newnigma2; E2_IMAGE_FAMILY=dreambox-deb ;;
    *merlin*) E2_IMAGE=merlin; E2_IMAGE_FAMILY=dreambox-deb ;;
    *vti*) E2_IMAGE=vti; E2_IMAGE_FAMILY=vti ;;
    *egami*) E2_IMAGE=egami; E2_IMAGE_FAMILY=community-enigma2 ;;
    *hdmu*) E2_IMAGE=hdmu; E2_IMAGE_FAMILY=community-enigma2 ;;
    *pure2*|*pure-e2*) E2_IMAGE=pure2; E2_IMAGE_FAMILY=community-enigma2 ;;
    *openvision*) E2_IMAGE=openvision; E2_IMAGE_FAMILY=community-enigma2 ;;
    *oozoon*) E2_IMAGE=oozoon; E2_IMAGE_FAMILY=dreambox-deb ;;
    *oe-alliance*|*oea*) E2_IMAGE=oe-alliance; E2_IMAGE_FAMILY=oe-alliance ;;
    *)
      if has enigma2 || [ -x "$(_detect_path /usr/bin/enigma2)" ] || [ -x "$(_detect_path /usr/bin/enigma2.sh)" ]; then
        E2_IMAGE=generic-enigma2
        E2_IMAGE_FAMILY=generic-enigma2
      fi
      ;;
  esac

  for f in /etc/image-version /etc/enigma2/image-version; do
    [ -r "$(_detect_path "$f")" ] || continue
    version="$(sed -n 's/.*[Vv]ersion[[:space:]]*[:=][[:space:]]*\([^[:space:]]*\).*/\1/p' "$(_detect_path "$f")" 2>/dev/null | head -1)"
    [ -n "$version" ] && { E2_IMAGE_VERSION="$version"; break; }
  done
}

detect_enigma2() {
  E2_VERSION=unknown
  if [ -x "$(_detect_path /usr/bin/enigma2)" ]; then
    E2_BIN="$(_detect_path /usr/bin/enigma2)"
    E2_VERSION="$("$E2_BIN" --version 2>/dev/null | head -1 || true)"
  elif [ -x "$(_detect_path /usr/bin/enigma2.sh)" ]; then
    E2_BIN="$(_detect_path /usr/bin/enigma2.sh)"
  else
    E2_BIN=unknown
  fi
}

detect_storage() {
  E2_STORAGE_AVAILABLE=unknown
  df -k "$(_detect_path /tmp)" >"$(_detect_path /tmp)/e2panel_df.$" 2>/dev/null && E2_STORAGE_AVAILABLE="$(awk 'NR==2 {print $4}' "$(_detect_path /tmp)/e2panel_df.$" 2>/dev/null)"
  rm -f "$(_detect_path /tmp)/e2panel_df.$" 2>/dev/null
  [ -n "$E2_STORAGE_AVAILABLE" ] || E2_STORAGE_AVAILABLE=unknown
}

detect_network() {
  E2_NETWORK=offline
  if has ip && ip route 2>/dev/null | grep -q 'default'; then
    E2_NETWORK=online
  elif has route && route -n 2>/dev/null | grep -q '^0.0.0.0'; then
    E2_NETWORK=online
  fi
}

detect_all() {
  detect_arch
  detect_package_manager
  detect_python
  detect_device
  detect_image
  detect_enigma2
  detect_storage
  detect_network
}
