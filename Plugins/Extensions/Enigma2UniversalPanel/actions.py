"""Registered native GUI actions with strict parameter validation."""

import re
import subprocess


ACTIONS = {
    "receiver.status": {"command": ("/usr/local/bin/e2panel", "status"), "risk": "low", "confirmation": False},
    "receiver.capabilities": {"command": ("/usr/local/bin/e2panel", "capabilities"), "risk": "low", "confirmation": False},
    "receiver.diagnose": {"command": ("/usr/local/bin/e2panel", "diagnose"), "risk": "low", "confirmation": False},
    "receiver.package_state": {"command": ("/usr/local/bin/e2panel", "package-state"), "risk": "low", "confirmation": False},
    "plugin.resolve": {"command": ("/usr/local/bin/e2panel", "plugin-resolve"), "risk": "low", "confirmation": False},
    "plugin.preview": {"command": ("/usr/local/bin/e2panel", "plugin-preview"), "risk": "low", "confirmation": False},
}

_PLUGIN_ID = re.compile(r"^[a-z0-9][a-z0-9._-]{0,63}$")


def _validate_plugin_id(value):
    if not isinstance(value, str) or not _PLUGIN_ID.fullmatch(value):
        raise ValueError("invalid plugin id")
    return value


def run_action(action_id, params=None):
    action = ACTIONS.get(action_id)
    if action is None:
        raise ValueError("unregistered action")
    params = params or {}
    if not isinstance(params, dict):
        raise ValueError("action parameters must be an object")

    command = list(action["command"])
    if action_id in ("plugin.resolve", "plugin.preview"):
        if set(params) != {"plugin_id"}:
            raise ValueError("plugin_id is required")
        command.append(_validate_plugin_id(params["plugin_id"]))
    elif params:
        raise ValueError("action does not accept parameters")

    result = subprocess.run(
        command,
        shell=False,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return result.returncode, result.stdout.strip()
