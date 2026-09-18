#!/bin/sh
diagnose() {
  detect_all
  select_adapter
  printf '%s\n' '=== Enigma2 Universal Panel Diagnostics ==='
  print_status
  printf '%s\n' '--- network ---'
  if has ip; then ip addr 2>/dev/null | sed -n '1,80p'; fi
  printf '%s\n' '--- routes ---'
  if has ip; then ip route 2>/dev/null; fi
  printf '%s\n' '--- package manager ---'
  case "$E2_PKG" in
    opkg) opkg --version 2>/dev/null | head -1 ;;
    apt) apt-get --version 2>/dev/null | head -1 ;;
    *) printf '%s\n' none ;;
  esac
}
