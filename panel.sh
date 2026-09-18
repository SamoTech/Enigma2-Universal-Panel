#!/bin/sh
BASE="/usr/lib/enigma2-universal-panel"
. "$BASE/scripts/lib/common.sh"
. "$BASE/scripts/lib/detect.sh"
. "$BASE/scripts/lib/compat.sh"
. "$BASE/scripts/lib/plugins.sh"
. "$BASE/scripts/lib/actions.sh"
. "$BASE/scripts/lib/status.sh"
. "$BASE/scripts/lib/diagnose.sh"

usage() {
  cat <<EOF
Enigma2 Universal Panel $PANEL_VERSION

Usage:
  e2panel status
  e2panel capabilities
  e2panel diagnose
  e2panel restart-enigma2
  e2panel restart-gui
  e2panel reboot --confirm
  e2panel package-update
  e2panel package-install <package>
  e2panel package-remove <package> --confirm
  e2panel package-state
  e2panel plugin-source-status
  e2panel plugin-refresh
  e2panel plugin-list [pattern]
  e2panel plugin-info <package>
  e2panel plugin-install <package>
  e2panel plugin-update <package>
  e2panel plugin-remove <package> --confirm
EOF
}

menu() {
  while :; do
    printf '\nEnigma2 Universal Panel\n'
    printf '1) Status\n2) Capabilities\n3) Diagnostics\n4) Package/source state\n5) Plugin source status\n6) Refresh plugin sources\n7) List packages\n8) Install package\n9) Update package\n10) Remove package\n11) Restart Enigma2\n12) Restart GUI\n13) Reboot\n14) Exit\n'
    printf 'Select: '
    read choice
    case "$choice" in
      1) print_status ;;
      2) print_capabilities ;;
      3) diagnose ;;
      4) plugin_package_state ;;
      5) plugin_source_status ;;
      6) plugin_refresh_sources ;;
      7) printf 'Pattern (optional): '; read pattern; plugin_list "$pattern" ;;
      8) printf 'Package: '; read pkg; action_plugin_install "$pkg" ;;
      9) printf 'Package: '; read pkg; action_plugin_update "$pkg" ;;
      10) printf 'Package: '; read pkg; printf 'Type REMOVE to confirm: '; read confirm; [ "$confirm" = REMOVE ] && action_plugin_remove "$pkg" ;;
      11) action_restart_enigma2 ;;
      12) action_restart_gui ;;
      13) printf 'Type REBOOT to confirm: '; read confirm; [ "$confirm" = REBOOT ] && action_reboot ;;
      14) return 0 ;;
      *) printf 'Invalid selection\n' ;;
    esac
  done
}

cmd="$1"
shift 2>/dev/null || true
case "$cmd" in
  status) print_status ;;
  capabilities) print_capabilities ;;
  diagnose) diagnose ;;
  restart-enigma2) action_restart_enigma2 ;;
  restart-gui) action_restart_gui ;;
  reboot) [ "$1" = "--confirm" ] && action_reboot || { error 'reboot requires --confirm'; exit 2; } ;;
  package-update) action_package_update ;;
  package-install) action_package_install "$1" ;;
  package-remove) [ "$2" = "--confirm" ] && action_package_remove "$1" || { error 'package-remove requires package and --confirm'; exit 2; } ;;
  package-state) plugin_package_state ;;
  plugin-source-status) plugin_source_status ;;
  plugin-refresh) plugin_refresh_sources ;;
  plugin-list) plugin_list "$1" ;;
  plugin-info) plugin_info "$1" ;;
  plugin-install) action_plugin_install "$1" ;;
  plugin-update) action_plugin_update "$1" ;;
  plugin-remove) [ "$2" = "--confirm" ] && action_plugin_remove "$1" || { error 'plugin-remove requires package and --confirm'; exit 2; } ;;
  menu|"") menu ;;
  *) usage; exit 2 ;;
esac
