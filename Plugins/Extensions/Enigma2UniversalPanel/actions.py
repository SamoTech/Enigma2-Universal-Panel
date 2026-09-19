"""Registered native GUI actions with strict parameter validation."""

import re
import subprocess


ACTIONS = {
    "receiver.status": {"command": ("/usr/local/bin/e2panel", "status"), "risk": "low", "confirmation": False},
    "receiver.capabilities": {"command": ("/usr/local/bin/e2panel", "capabilities"), "risk": "low", "confirmation": False},
    "receiver.compatibility": {"command": ("/usr/local/bin/e2panel", "compatibility"), "risk": "low", "confirmation": False},
    "receiver.diagnose": {"command": ("/usr/local/bin/e2panel", "diagnose"), "risk": "low", "confirmation": False},
    "receiver.package_state": {"command": ("/usr/local/bin/e2panel", "package-state"), "risk": "low", "confirmation": False},
    "receiver.telemetry": {"command": ("/usr/local/bin/e2panel", "telemetry"), "risk": "low", "confirmation": False},
    "receiver.audit_history": {"command": ("/usr/local/bin/e2panel", "audit-history"), "risk": "low", "confirmation": False},
    "community.catalog": {"command": ("/usr/local/bin/e2panel", "community-catalog"), "risk": "low", "confirmation": False},
    "plugin.library": {"command": ("/usr/local/bin/e2panel", "plugin-library"), "risk": "low", "confirmation": False},
    "plugin.resolve": {"command": ("/usr/local/bin/e2panel", "plugin-resolve"), "risk": "low", "confirmation": False},
    "plugin.preview": {"command": ("/usr/local/bin/e2panel", "plugin-preview"), "risk": "low", "confirmation": False},
    "plugin.info": {"command": ("/usr/local/bin/e2panel", "plugin-info-id"), "risk": "low", "confirmation": False},
    "plugin.install": {"command": ("/usr/local/bin/e2panel", "plugin-install-id"), "risk": "high", "confirmation": True},
    "plugin.update": {"command": ("/usr/local/bin/e2panel", "plugin-update-id"), "risk": "high", "confirmation": True},
    "plugin.remove_preview": {"command": ("/usr/local/bin/e2panel", "plugin-remove-preview"), "risk": "low", "confirmation": False},
    "plugin.remove": {"command": ("/usr/local/bin/e2panel", "plugin-remove-id"), "risk": "high", "confirmation": True},
}

_PLUGIN_ID = re.compile(r"^[a-z0-9][a-z0-9._-]{0,63}$")


def _validate_plugin_id(value):
    if not isinstance(value, str):
        raise ValueError("invalid plugin id")
    match = _PLUGIN_ID.match(value)
    if match is None or match.group(0) != value:
        raise ValueError("invalid plugin id")
    return value


def build_action_command(action_id, params=None):
    action = ACTIONS.get(action_id)
    if action is None:
        raise ValueError("unregistered action")
    params = params or {}
    if not isinstance(params, dict):
        raise ValueError("action parameters must be an object")

    command = list(action["command"])
    if action_id in (
        "plugin.resolve",
        "plugin.preview",
        "plugin.info",
        "plugin.install",
        "plugin.update",
        "plugin.remove_preview",
        "plugin.remove",
    ):
        if set(params) != {"plugin_id"}:
            raise ValueError("plugin_id is required")
        command.append(_validate_plugin_id(params["plugin_id"]))
    elif params:
        raise ValueError("action does not accept parameters")
    return tuple(command)


def _run(command):
    process = subprocess.Popen(
        command,
        shell=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True,
    )
    stdout, _ = process.communicate()
    return process.returncode, (stdout or "").strip()


def run_action(action_id, params=None):
    return _run(build_action_command(action_id, params))
