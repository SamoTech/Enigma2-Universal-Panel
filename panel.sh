#!/bin/sh
BASE="/usr/lib/enigma2-universal-panel"
. "$BASE/scripts/lib/common.sh"
. "$BASE/scripts/lib/detect.sh"
. "$BASE/scripts/lib/compat.sh"
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
  e2panel reboot
  e2panel package-update
  e2panel package-install <package>
  e2panel package-remove <package>
  e2panel menu
EOF
}

menu() {
  while :; do
    printf '\nEnigma2 Universal Panel\n'
    printf '1) Status\n2) Capabilities\n3) Diagnostics\n4) Restart Enigma2\n5) Restart GUI\n6) Reboot\n7) Exit\n'
    printf 'Select: '
    read choice
    case "$choice" in
      1) print_status ;;
      2) print_capabilities ;;
      3) diagnose ;;
      4) action_restart_enigma2 ;;
      5) action_restart_gui ;;
      6) printf 'Type REBOOT to confirm: '; read confirm; [ "$confirm" = REBOOT ] && action_reboot ;;
      7) return 0 ;;
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
  package-remove) action_package_remove "$1" ;;
  menu|"") menu ;;
  *) usage; exit 2 ;;
esac
