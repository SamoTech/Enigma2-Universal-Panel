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
p = Path("Plugins/Extensions/Enigma2UniversalPanel/actions.py").read_text()
assert "ACTIONS =" in p
assert '"receiver.status"' in p
assert 'shell=False' in p
assert 'unregistered action' in p
PY

pass "native GUI package and policy"
