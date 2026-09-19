#!/bin/sh
set -eu

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f Plugins/Extensions/Enigma2UniversalPanel/plugin.py ] || fail "plugin.py missing"
[ -f Plugins/Extensions/Enigma2UniversalPanel/screens.py ] || fail "screens.py missing"
[ -f Plugins/Extensions/Enigma2UniversalPanel/audit_history.py ] || fail "audit_history.py missing"
[ -f Plugins/Extensions/Enigma2UniversalPanel/actions.py ] || fail "actions.py missing"

command -v python3 >/dev/null 2>&1 || fail "python3 unavailable"
python3 -m py_compile \
  Plugins/Extensions/Enigma2UniversalPanel/__init__.py \
  Plugins/Extensions/Enigma2UniversalPanel/plugin.py \
  Plugins/Extensions/Enigma2UniversalPanel/actions.py \
  Plugins/Extensions/Enigma2UniversalPanel/audit_history.py \
  Plugins/Extensions/Enigma2UniversalPanel/screens.py

if grep -R -nE 'shell[[:space:]]*=[[:space:]*]True|os\.system[[:space:]]*\(|subprocess\.(Popen|call|run).*shell[[:space:]]*=[[:space:]*]True' Plugins/Extensions/Enigma2UniversalPanel >/tmp/e2panel-native-gui-policy 2>/dev/null; then
  cat /tmp/e2panel-native-gui-policy >&2
  fail "arbitrary shell execution detected"
fi

if ! grep -Fq '. "$BASE/scripts/lib/telemetry.sh"' panel.sh; then
  fail "telemetry library is not sourced by panel runtime"
fi

grep -Fq 'telemetry) print_telemetry;;' panel.sh || fail "telemetry command is not wired"
grep -Fq 'audit-history) audit_history;;' panel.sh || fail "audit history command is not wired"
grep -Fq 'community-catalog) community_catalog;;' panel.sh || fail "community catalog command is not wired"
grep -Fq 'plugin-library) plugin_library;;' panel.sh || fail "plugin library command is not wired"
grep -Fq 'compatibility) print_compatibility;;' panel.sh || fail "compatibility command is not wired"
grep -Fq 'reboot-status) reboot_status;;' panel.sh || fail "reboot-status command is not wired"
grep -Fq '_restart_enigma2_detached()' scripts/lib/actions.sh || fail "detached Enigma2 restart helper missing"
grep -Fq 'setsid sh -c' scripts/lib/actions.sh || fail "setsid restart path missing"
grep -Fq 'nohup sh -c' scripts/lib/actions.sh || fail "nohup restart fallback missing"
grep -Fq 'method=detached-init' scripts/lib/actions.sh || fail "detached restart audit marker missing"
grep -Fq '*vuuno4kse*)' scripts/lib/detect.sh || fail "VU+ Uno 4K SE hostname detection missing"
grep -Fq 'E2_MODEL="VU+ Uno 4K SE"' scripts/lib/detect.sh || fail "VU+ Uno 4K SE canonical model mapping missing"

grep -Fq '#!/bin/sh' scripts/lib/telemetry.sh || fail "telemetry library is not a shell script"

grep -Fq 'print_telemetry()' scripts/lib/telemetry.sh || fail "telemetry function missing"

grep -Fq '/proc/loadavg' scripts/lib/telemetry.sh || fail "load telemetry source missing"
grep -Fq '/proc/meminfo' scripts/lib/telemetry.sh || fail "memory telemetry source missing"
grep -Fq 'df -k /' scripts/lib/telemetry.sh || fail "filesystem telemetry source missing"

grep -Fq 'audit_history()' scripts/lib/common.sh || fail "audit history function missing"
grep -Fq 'tail -n 20' scripts/lib/common.sh || fail "audit history is not bounded"
grep -Fq 'name="Audit History"' Plugins/Extensions/Enigma2UniversalPanel/plugin.py || fail "audit history plugin entry missing"
grep -Fq 'class AuditHistory' Plugins/Extensions/Enigma2UniversalPanel/audit_history.py || fail "audit history screen missing"
grep -Fq 'receiver.audit_history' Plugins/Extensions/Enigma2UniversalPanel/audit_history.py || fail "audit history action missing"

python3 - <<'PY'
from pathlib import Path
import importlib.util
import sys

p = Path("Plugins/Extensions/Enigma2UniversalPanel/actions.py").read_text()
screens = Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert "ACTIONS =" in p
assert '"receiver.status"' in p
assert '"receiver.package_state"' in p
assert '"receiver.package_info"' in p
assert '"community.preview"' in p
assert '"community.install"' in p
assert '"package.install"' in p
assert '"package.update"' in p
assert '"package.remove"' in p

assert '"receiver.telemetry"' in p
assert '"receiver.compatibility"' in p
assert '"receiver.audit_history"' in p
assert '"receiver.restart_gui"' in p
assert '"receiver.reboot_status"' in p
assert '"receiver.reboot_for_plugin"' in p
assert '"plugin.resolve"' in p
assert '"plugin.preview"' in p
assert '"plugin.install"' in p
assert 'community-admitted.json' in Path("scripts/lib/library.sh").read_text()
assert 'community_confirmed' in Path("scripts/lib/community.sh").read_text()
assert '"plugin.info"' in p
assert '"plugin.update"' in p
assert '"plugin.remove_preview"' in p
assert '"plugin.remove"' in p
assert '"confirmation": True' in p
assert 'build_action_command' in p
assert 'shell=False' in p
assert 'eConsoleAppContainer' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'PackageInstallProgress' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'Update Plugin' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'Remove Plugin' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert '_prepare_remove' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert '_prepare_update' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'Receiver Telemetry' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class ReceiverTelemetry' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class RestartGuiProgress' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class RebootProgress' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'def _offer_reboot(self):' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'receiver.reboot_for_plugin' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'requires_reboot' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'receiver.reboot_for_plugin' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'receiver.reboot_status' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'GUI restart required' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'receiver.restart_gui' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class ReceiverCompatibility' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'receiver.compatibility' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class CommunityInstallerCatalog' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class CommunityInstallerCatalog' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class PackageBrowser' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class PackageBrowser' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class PluginLibrary' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'class StoreCategories' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'Plugin Store' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'Choose a category' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'self.session.open(StoreCategories)' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()

assert 'RED: Categories' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'GREEN: Install' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'YELLOW: Refresh' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'BLUE: Search' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'name="key_red"' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'name="key_green"' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'name="key_yellow"' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'name="key_blue"' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'name="summary"' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'Plugin Library' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'Search Plugin Library' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'title.title()' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'Native receiver UI | Store-first workflow | No web dependency' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'plugin.library' in p
assert 'if action_id == "plugin.library"' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'self.session.open(StoreCategories)' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'network_reachability' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
resolver = Path("scripts/lib/plugin-resolver.sh").read_text()
panel = Path("panel.sh").read_text()
assert "plugin_update_id()" in resolver
assert "plugin_remove_preview()" in resolver
assert "plugin_remove_id()" in resolver
assert "plugin_info_id()" in resolver
assert "plugin_update_id()" in resolver
assert "plugin-info-id" in panel
assert "plugin-remove-preview" in panel
assert "plugin-remove-id" in panel
assert 'MessageBox.TYPE_YESNO' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert '"ok": self._close_when_finished' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert '"cancel": self._close_when_finished' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'unregistered action' in p
assert "_PLUGIN_ID" in p
assert 'subprocess.Popen' in p
assert 'universal_newlines=True' in p
assert 'class PanelSectionMenu' in screens
assert '("Store", (' in screens
assert '("Receiver", (' in screens
assert '("Management", (' in screens
assert '("Advanced", (' in screens
assert 'Audit History' in Path("Plugins/Extensions/Enigma2UniversalPanel/plugin.py").read_text()

plugin_dir = Path("Plugins/Extensions/Enigma2UniversalPanel").resolve()
sys.path.insert(0, str(plugin_dir))
spec = importlib.util.spec_from_file_location("e2_actions", str(plugin_dir / "actions.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

for value in ("openwebif", "auto.bouquets-maker", "epg_import_2"):
    assert mod._validate_plugin_id(value) == value

assert mod.build_action_command("receiver.package_info", {"package": "enigma2-plugin-systemplugins-networkmanager"}) == (
    "/usr/local/bin/e2panel", "plugin-info", "enigma2-plugin-systemplugins-networkmanager"
)
assert mod.build_action_command("package.install", {"package": "enigma2-plugin-extensions-openwebif"}) == (
    "/usr/local/bin/e2panel", "package-install", "enigma2-plugin-extensions-openwebif"
)
assert mod.build_action_command("package.update", {"package": "enigma2-plugin-extensions-openwebif"}) == (
    "/usr/local/bin/e2panel", "package-update", "enigma2-plugin-extensions-openwebif"
)
assert mod.build_action_command("package.remove", {"package": "enigma2-plugin-extensions-openwebif"}) == (
    "/usr/local/bin/e2panel", "package-remove", "enigma2-plugin-extensions-openwebif", "--confirm"
)

assert mod.build_action_command("plugin.info", {"plugin_id": "openwebif"}) == ("/usr/local/bin/e2panel", "plugin-info-id", "openwebif")
assert mod.build_action_command("plugin.update", {"plugin_id": "openwebif"}) == ("/usr/local/bin/e2panel", "plugin-update-id", "openwebif")
assert mod.build_action_command("plugin.remove_preview", {"plugin_id": "openwebif"}) == ("/usr/local/bin/e2panel", "plugin-remove-preview", "openwebif")
assert mod.build_action_command("plugin.remove", {"plugin_id": "openwebif"}) == ("/usr/local/bin/e2panel", "plugin-remove-id", "openwebif")
assert mod.build_action_command("plugin.update", {"plugin_id": "openwebif"}) == ("/usr/local/bin/e2panel", "plugin-update-id", "openwebif")
assert mod.build_action_command("community.install", {"plugin_id": "ciefpplugins"}) == ("/usr/local/bin/e2panel", "community-install", "ciefpplugins")
assert mod.build_action_command("community.preview", {"plugin_id": "ciefpplugins"}) == ("/usr/local/bin/e2panel", "community-preview", "ciefpplugins")
assert mod.build_action_command("plugin.install", {"plugin_id": "openwebif"}) == (
    "/usr/local/bin/e2panel", "plugin-install-id", "openwebif"
)
for action_id in ("plugin.resolve", "plugin.preview", "plugin.info", "plugin.install", "plugin.update", "plugin.remove_preview", "plugin.remove"):
    for value in ("", "OpenWebif", "openwebif;rm", "../../etc/passwd", "openwebif --confirm"):
        try:
            mod.build_action_command(action_id, {"plugin_id": value})
        except ValueError:
            pass
        else:
            raise AssertionError("unsafe plugin id accepted by %s: %r" % (action_id, value))

for value in ("", "OpenWebif", "openwebif;rm", "../../etc/passwd", "openwebif --confirm"):
    try:
        mod._validate_plugin_id(value)
    except ValueError:
        pass
    else:
        raise AssertionError("unsafe plugin id accepted: %r" % value)

try:
    mod.run_action("receiver.status", {"unexpected": "value"})
except ValueError:
    pass
else:
    raise AssertionError("unexpected parameters accepted")
PY

pass "native GUI package, registered actions, parameter validation, shell policy and telemetry wiring"
