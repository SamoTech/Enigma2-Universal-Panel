#!/bin/sh
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
  has opkg && E2_PKG=opkg
  [ "$E2_PKG" = none ] && has apt-get && E2_PKG=apt
  [ "$E2_PKG" = none ] && has ipkg && E2_PKG=ipkg
}
detect_image() {
  E2_IMAGE=unknown
  for f in /etc/issue /etc/os-release /etc/image-version /etc/enigma2/image-version; do
    [ -r "$f" ] || continue
    txt="$(cat "$f" 2>/dev/null)"
    low="$(printf '%s' "$txt" | tr '[:upper:]' '[:lower:]')"
    case "$low" in
      *openatv*) E2_IMAGE=openatv ;;
      *openvix*) E2_IMAGE=openvix ;;
      *openpli*) E2_IMAGE=openpli ;;
      *dreamos*|*dreambox*) E2_IMAGE=dreamos ;;
    esac
    [ "$E2_IMAGE" != unknown ] && break
  done
  [ "$E2_IMAGE" = unknown ] && { has enigma2 && E2_IMAGE=enigma2; }
}
detect_enigma2() {
  E2_VERSION=unknown
  if [ -x /usr/bin/enigma2 ]; then
    E2_BIN=/usr/bin/enigma2
    E2_VERSION="$(/usr/bin/enigma2 --version 2>/dev/null | head -1)"
  elif [ -x /usr/bin/enigma2.sh ]; then
    E2_BIN=/usr/bin/enigma2.sh
  else
    E2_BIN=unknown
  fi
}
detect_storage() {
  E2_STORAGE_AVAILABLE=unknown
  df -k / >/tmp/e2panel_df.$$ 2>/dev/null && E2_STORAGE_AVAILABLE="$(awk 'NR==2 {print $4}' /tmp/e2panel_df.$$ 2>/dev/null)"
  rm -f /tmp/e2panel_df.$$ 2>/dev/null
}
detect_network() {
  E2_NETWORK=offline
  if has ip && ip route 2>/dev/null | grep -q 'default'; then E2_NETWORK=online
  elif has route && route -n 2>/dev/null | grep -q '^0.0.0.0'; then E2_NETWORK=online
  fi
}
detect_all() {
  detect_arch
  detect_package_manager
  detect_image
  detect_enigma2
  detect_storage
  detect_network
}
