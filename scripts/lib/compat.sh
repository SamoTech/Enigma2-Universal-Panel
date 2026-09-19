#!/bin/sh
select_adapter() {
  image_family="${E2_IMAGE_FAMILY:-unknown}"
  image_id="${E2_IMAGE:-unknown}"
  case "$image_family:$image_id" in
    dreamos:*) ADAPTER=dreamos ;;
    dreambox-deb:*) ADAPTER=dreambox-deb ;;
    oe-alliance:openatv) ADAPTER=openatv ;;
    oe-alliance:openvix) ADAPTER=openvix ;;
    oe-alliance:openhdf) ADAPTER=openhdf ;;
    oe-alliance:opendroid) ADAPTER=opendroid ;;
    oe-alliance:openeight) ADAPTER=openeight ;;
    oe-alliance:openld) ADAPTER=openld ;;
    openpli:*) ADAPTER=openpli ;;
    oe-alliance:*) ADAPTER=oe-alliance ;;
    vti:*) ADAPTER=vti ;;
    community-enigma2:*) ADAPTER=community-enigma2 ;;
    generic-enigma2:*) ADAPTER=generic-enigma2 ;;
    *) ADAPTER=generic-enigma2 ;;
  esac
}

capability() {
  case "$1" in
    package_manager)
      case "$E2_PKG" in opkg|apt|ipkg) return 0;; *) return 1;; esac
      ;;
    package_inventory)
      case "$E2_PKG" in opkg|apt|ipkg|dpkg) return 0;; *) return 1;; esac
      ;;
    enigma2)
      [ "$E2_BIN" != unknown ]
      ;;
    native_gui)
      case "$E2_PYTHON_MAJOR" in 2|3) [ "$E2_BIN" != unknown ];; *) return 1;; esac
      ;;
    storage)
      [ "$E2_STORAGE_AVAILABLE" != unknown ]
      ;;
    network)
      [ "$E2_NETWORK" = online ]
      ;;
    *)
      return 1
      ;;
  esac
}

require_capability() {
  capability "$1" || { error "missing capability: $1"; return 1; }
}
