#!/bin/sh
set -eu

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

[ -f Plugins/Extensions/Enigma2UniversalPanel/plugin.py ] || fail "plugin.py missing"
[ -f Plugins/Extensions/Enigma2UniversalPanel/screens.py ] || fail "screens.py missing"
[ -f Plugins/Extensions/Enigma2UniversalPanel/actions.py ] || fail "actions.py missing"

command -v python3 >/dev/null 2>&1 || fail "python3 unavailable"
python3 -m py_compile \
  Plugins/Extensions/Enigma2UniversalPanel/__init__.py \
  Plugins/Extensions/Enigma2UniversalPanel/plugin.py \
  Plugins/Extensions/Enigma2UniversalPanel/actions.py \
  Plugins/Extensions/Enigma2UniversalPanel/screens.py

if grep -R -nE 'shell[[:space:]]*=[[:space:]*]True|os\.system[[:space:]]*\(|subprocess\.(Popen|call|run).*shell[[:space:]]*=[[:space:]*]True' Plugins/Extensions/Enigma2UniversalPanel >/tmp/e2panel-native-gui-policy 2>/dev/null; then
  cat /tmp/e2panel-native-gui-policy >&2
  fail "arbitrary shell execution detected"
fi

python3 - <<'PY'
from pathlib import Path
import importlib.util

p = Path("Plugins/Extensions/Enigma2UniversalPanel/actions.py").read_text()
assert "ACTIONS =" in p
assert '"receiver.status"' in p
assert '"plugin.resolve"' in p
assert '"plugin.preview"' in p
assert '"plugin.install"' in p
assert '"plugin.info"' in p
assert '"confirmation": True' in p
assert 'build_action_command' in p
assert 'shell=False' in p
assert 'eConsoleAppContainer' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'PackageInstallProgress' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'PluginMetadata' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
resolver = Path("scripts/lib/plugin-resolver.sh").read_text()
panel = Path("panel.sh").read_text()
assert "plugin_info_id()" in resolver
assert "plugin-info-id" in panel
assert 'MessageBox.TYPE_YESNO' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert '"ok": self._close_when_finished' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert '"cancel": self._close_when_finished' in Path("Plugins/Extensions/Enigma2UniversalPanel/screens.py").read_text()
assert 'unregistered action' in p
assert "_PLUGIN_ID" in p

spec = importlib.util.spec_from_file_location("e2_actions", "Plugins/Extensions/Enigma2UniversalPanel/actions.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

for value in ("openwebif", "auto.bouquets-maker", "epg_import_2"):
    assert mod._validate_plugin_id(value) == value

assert mod.build_action_command("plugin.info", {"plugin_id": "openwebif"}) == ("/usr/local/bin/e2panel", "plugin-info-id", "openwebif")
assert mod.build_action_command("plugin.install", {"plugin_id": "openwebif"}) == (
    "/usr/local/bin/e2panel", "plugin-install-id", "openwebif"
)
for action_id in ("plugin.resolve", "plugin.preview", "plugin.info", "plugin.install"):
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

pass "native GUI package, registered actions, parameter validation and shell policy"
