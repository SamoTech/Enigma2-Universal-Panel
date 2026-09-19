#!/bin/sh
BASE="/usr/lib/enigma2-universal-panel"
. "$BASE/scripts/lib/common.sh"
. "$BASE/scripts/lib/detect.sh"
. "$BASE/scripts/lib/compat.sh"
. "$BASE/scripts/lib/plugins.sh"
. "$BASE/scripts/lib/plugin-resolver.sh"
. "$BASE/scripts/lib/actions.sh"
. "$BASE/scripts/lib/status.sh"
. "$BASE/scripts/lib/diagnose.sh"

usage() {
  cat <<EOF
Enigma2 Universal Panel $PANEL_VERSION
Usage:
  e2panel status | capabilities | diagnose
  e2panel package-state
  e2panel plugin-source-status | plugin-refresh | plugin-list [pattern]
  e2panel plugin-info <package>
  e2panel plugin-resolve <plugin-id>
  e2panel plugin-preview <plugin-id>
  e2panel plugin-info-id <plugin-id>
  e2panel plugin-install <package>
  e2panel plugin-update <package>
  e2panel plugin-remove <package> --confirm
  e2panel plugin-install-id <plugin-id>
  e2panel plugin-remove-preview <plugin-id>
  e2panel plugin-remove-id <plugin-id>
  e2panel telemetry
  e2panel community-catalog
  e2panel restart-enigma2 | restart-gui
  e2panel reboot --confirm
EOF
}
menu() {
  while :; do
    printf '\nEnigma2 Universal Panel\n'
    printf '1) Status\n2) Capabilities\n3) Diagnostics\n4) Package/source state\n5) Plugin source status\n6) Refresh sources\n7) Discover packages\n8) Resolve plugin ID\n9) Preview plugin install\n10) Install package\n11) Update package\n12) Remove package\n13) Restart Enigma2\n14) Restart GUI\n15) Reboot\n16) Exit\nSelect: '
    read choice
    case "$choice" in
      1) print_status;; 2) print_capabilities;; 3) diagnose;; 4) plugin_package_state;;
      5) plugin_source_status;; 6) plugin_refresh_sources;;
      7) printf 'Pattern: '; read pattern; plugin_list "$pattern";;
      8) printf 'Plugin ID: '; read id; plugin_resolve "$id";;
      9) printf 'Plugin ID: '; read id; plugin_preview "$id";;
      10) printf 'Package: '; read pkg; action_plugin_install "$pkg";;
      11) printf 'Package: '; read pkg; action_plugin_update "$pkg";;
      12) printf 'Package: '; read pkg; printf 'Type REMOVE: '; read confirm; [ "$confirm" = REMOVE ] && action_plugin_remove "$pkg";;
      13) action_restart_enigma2;; 14) action_restart_gui;;
      15) printf 'Type REBOOT: '; read confirm; [ "$confirm" = REBOOT ] && action_reboot;;
      16) return 0;; *) printf 'Invalid selection\n';;
    esac
  done
}
cmd="$1"; shift 2>/dev/null || true
case "$cmd" in
  status) print_status;; capabilities) print_capabilities;; diagnose) diagnose;;
  package-state) plugin_package_state;;
  telemetry) print_telemetry;;
  community-catalog) community_catalog;;
  plugin-source-status) plugin_source_status;; plugin-refresh) plugin_refresh_sources;;
  plugin-list) plugin_list "$1";; plugin-info) plugin_info "$1";;
  plugin-resolve) plugin_resolve "$1";;
  plugin-preview) plugin_preview "$1";;
  plugin-info-id) plugin_info_id "$1";;
  plugin-install) action_plugin_install "$1";;
  plugin-update) action_plugin_update "$1";;
  plugin-remove-preview) plugin_remove_preview "$1";;
  plugin-remove-id) plugin_remove_id "$1";;
  plugin-remove) [ "$2" = "--confirm" ] && action_plugin_remove "$1" || { error 'plugin-remove requires package and --confirm'; exit 2; };;
  plugin-install-id) plugin_resolve_install "$1";;
  restart-enigma2) action_restart_enigma2;; restart-gui) action_restart_gui;;
  reboot) [ "$1" = "--confirm" ] && action_reboot || { error 'reboot requires --confirm'; exit 2; };;
  menu|"") menu;; *) usage; exit 2;;
esac
