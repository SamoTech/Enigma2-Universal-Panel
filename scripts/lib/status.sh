#!/bin/sh
print_status() {
  detect_all
  select_adapter
  printf 'panel_version=%s\n' "$PANEL_VERSION"
  printf 'hostname=%s\n' "$(hostname 2>/dev/null || echo unknown)"
  printf 'device_family=%s\n' "$E2_DEVICE_FAMILY"
  printf 'vendor=%s\n' "$E2_VENDOR"
  printf 'model=%s\n' "$E2_MODEL"
  printf 'machine=%s\n' "$E2_MACHINE"
  printf 'chipset=%s\n' "$E2_CHIPSET"
  printf 'image=%s\n' "$E2_IMAGE"
  printf 'image_family=%s\n' "$E2_IMAGE_FAMILY"
  printf 'image_version=%s\n' "$E2_IMAGE_VERSION"
  printf 'adapter=%s\n' "$ADAPTER"
  printf 'architecture=%s\n' "$E2_ARCH"
  printf 'architecture_family=%s\n' "$E2_ARCH_FAMILY"
  printf 'package_manager=%s\n' "$E2_PKG"
  printf 'package_family=%s\n' "$E2_PACKAGE_FAMILY"
  printf 'python_binary=%s\n' "$E2_PYTHON_BIN"
  printf 'python_major=%s\n' "$E2_PYTHON_MAJOR"
  printf 'python_version=%s\n' "$E2_PYTHON_VERSION"
  printf 'enigma2_binary=%s\n' "$E2_BIN"
  printf 'enigma2_version=%s\n' "$E2_VERSION"
  printf 'network=%s\n' "$E2_NETWORK"
  printf 'available_storage_kb=%s\n' "$E2_STORAGE_AVAILABLE"
}

print_capabilities() {
  detect_all
  printf 'system.status=1\n'
  printf 'system.diagnose=1\n'
  capability native_gui && printf 'panel.native_gui=1\n'
  capability enigma2 && printf 'system.restart_enigma2=1\n'
  capability enigma2 && printf 'system.restart_gui=1\n'
  capability package_inventory && printf 'package.inventory=1\n'
  capability package_manager && printf 'package.install=1\npackage.remove=1\npackage.update=1\n'
  capability storage && printf 'backup.create=1\nbackup.restore=1\n'
  capability network && printf 'diagnostics.network=1\n'
}
