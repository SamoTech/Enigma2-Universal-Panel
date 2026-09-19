#!/bin/sh
# Universal Enigma2 compatibility report.
# Detection is runtime-first; unknown stays unknown.

compatibility_status() {
  detect_all
  select_adapter

  native_gui=blocked
  native_gui_reason="enigma2_runtime_or_python_unavailable"
  python_major="${E2_PYTHON_MAJOR:-unknown}"
  enigma2_bin="${E2_BIN:-unknown}"
  package_manager="${E2_PKG:-none}"
  case "$python_major" in
    2|3)
      [ "$enigma2_bin" != unknown ] && {
        native_gui=supported
        native_gui_reason="enigma2_runtime_and_python_detected"
      }
      ;;
  esac

  package_install=blocked
  package_install_reason="no_supported_feed_package_manager"
  case "$package_manager" in
    opkg|apt|ipkg)
      package_install=supported
      package_install_reason="receiver_package_manager_detected"
      ;;
  esac

  image_state=unknown
  image_reason="image_identity_not_detected"
  if [ "$E2_IMAGE_FAMILY" != unknown ]; then
    image_state=detected
    image_reason="image_family_detected"
  fi

  device_state=unknown
  device_reason="device_identity_not_detected"
  if [ "$E2_DEVICE_FAMILY" != unknown ]; then
    device_state=detected
    device_reason="device_family_detected"
  fi

  overall=generic-compatible
  overall_reason="native_enigma2_runtime_detected"
  image_family="${E2_IMAGE_FAMILY:-unknown}"
  package_family="${E2_PACKAGE_FAMILY:-unknown}"
  device_family="${E2_DEVICE_FAMILY:-unknown}"
  if [ "$native_gui" != supported ]; then
    overall=unsupported
    overall_reason="$native_gui_reason"
  elif [ "$image_family" = unknown ]; then
    overall=generic-compatible
    overall_reason="unknown_image_fail_closed_for_image_specific_operations"
  elif [ "$package_family" = unknown ]; then
    overall=generic-compatible
    overall_reason="package_backend_unknown"
  elif [ "$device_family" = unknown ]; then
    overall=generic-compatible
    overall_reason="device_identity_unknown_but_enigma2_runtime_is_present"
  else
    overall=image-and-device-detected
    overall_reason="runtime_device_image_and_package_backend_detected"
  fi

  printf '{
'
  printf '  "schema_version":1,
'
  printf '  "type":"receiver_compatibility",
'
  printf '  "overall":"%s",
' "$overall"
  printf '  "reason":"%s",
' "$overall_reason"
  printf '  "device":{"family":"%s","vendor":"%s","model":"%s","machine":"%s","chipset":"%s","state":"%s","reason":"%s"},
'     "${E2_DEVICE_FAMILY:-unknown}" "${E2_VENDOR:-unknown}" "${E2_MODEL:-unknown}" "${E2_MACHINE:-unknown}" "${E2_CHIPSET:-unknown}" "$device_state" "$device_reason"
  printf '  "image":{"id":"%s","family":"%s","version":"%s","state":"%s","reason":"%s"},
'     "${E2_IMAGE:-unknown}" "${E2_IMAGE_FAMILY:-unknown}" "${E2_IMAGE_VERSION:-unknown}" "$image_state" "$image_reason"
  printf '  "runtime":{"enigma2_binary":"%s","enigma2_version":"%s","python_binary":"%s","python_major":"%s","python_version":"%s","native_gui":"%s"},
'     "${E2_BIN:-unknown}" "${E2_VERSION:-unknown}" "${E2_PYTHON_BIN:-unknown}" "${E2_PYTHON_MAJOR:-unknown}" "${E2_PYTHON_VERSION:-unknown}" "$native_gui"
  printf '  "package":{"manager":"%s","family":"%s","install_capability":"%s","reason":"%s"},
'     "${E2_PKG:-none}" "${E2_PACKAGE_FAMILY:-unknown}" "$package_install" "$package_install_reason"
  printf '  "adapter":"%s",
' "$ADAPTER"
  printf '  "architecture":{"raw":"%s","family":"%s"},
' "${E2_ARCH:-unknown}" "${E2_ARCH_FAMILY:-unknown}"
  printf '  "network":"%s",
' "${E2_NETWORK:-unknown}"
  printf '  "real_receiver_validation":false
'
  printf '}
'
}

print_compatibility() {
  compatibility_status
}
