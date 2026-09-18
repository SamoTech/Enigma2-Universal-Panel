#!/bin/sh
select_adapter() {
  case "$E2_IMAGE" in
    openatv) ADAPTER=openatv ;;
    openvix) ADAPTER=openvix ;;
    openpli) ADAPTER=openpli ;;
    dreamos) ADAPTER=dreamos ;;
    *) ADAPTER=generic-enigma2 ;;
  esac
}
capability() {
  case "$1" in
    package_manager) [ "$E2_PKG" != none ] ;;
    enigma2) [ "$E2_BIN" != unknown ] ;;
    storage) [ "$E2_STORAGE_AVAILABLE" != unknown ] ;;
    network) [ "$E2_NETWORK" = online ] ;;
    *) return 1 ;;
  esac
}
require_capability() {
  capability "$1" || { error "missing capability: $1"; return 1; }
}
