"""Registered native GUI actions with strict parameter validation."""

import re
import subprocess

try:
    from .debug import log
except ImportError:
    from debug import log


ACTIONS = {
    "receiver.status": {"command": ("/usr/local/bin/e2panel", "status"), "risk": "low", "confirmation": False},
    "receiver.capabilities": {"command": ("/usr/local/bin/e2panel", "capabilities"), "risk": "low", "confirmation": False},
    "receiver.compatibility": {"command": ("/usr/local/bin/e2panel", "compatibility"), "risk": "low", "confirmation": False},
    "receiver.diagnose": {"command": ("/usr/local/bin/e2panel", "diagnose"), "risk": "low", "confirmation": False},
    "receiver.package_state": {"command": ("/usr/local/bin/e2panel", "package-state"), "risk": "low", "confirmation": False},
    "receiver.package_info": {"command": ("/usr/local/bin/e2panel", "plugin-info"), "risk": "low", "confirmation": False},
    "package.install": {"command": ("/usr/local/bin/e2panel", "package-install"), "risk": "high", "confirmation": True},
    "package.update": {"command": ("/usr/local/bin/e2panel", "package-update"), "risk": "high", "confirmation": True},
    "package.remove": {"command": ("/usr/local/bin/e2panel", "package-remove"), "risk": "critical", "confirmation": True},
    "receiver.telemetry": {"command": ("/usr/local/bin/e2panel", "telemetry"), "risk": "low", "confirmation": False},
    "receiver.audit_history": {"command": ("/usr/local/bin/e2panel", "audit-history"), "risk": "low", "confirmation": False},
    "receiver.panel_update": {"command": ("/usr/local/bin/e2panel", "update"), "risk": "critical", "confirmation": True},
    "receiver.restart_gui": {"command": ("/usr/local/bin/e2panel", "restart-gui"), "risk": "critical", "confirmation": True},
    "receiver.reboot_status": {"command": ("/usr/local/bin/e2panel", "reboot-status"), "risk": "low", "confirmation": False},
    "receiver.reboot_for_plugin": {"command": ("/usr/local/bin/e2panel", "reboot-for-plugin"), "risk": "critical", "confirmation": True},
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
        "receiver.reboot_for_plugin",
    ):
        if set(params) != {"plugin_id"}:
            raise ValueError("plugin_id is required")
        command.append(_validate_plugin_id(params["plugin_id"]))
    elif action_id == "receiver.package_info":
        if set(params) != {"package"}:
            raise ValueError("package is required")
        package = params["package"]
        if not isinstance(package, str) or re.match(r"^[A-Za-z0-9][A-Za-z0-9._+:@%/-]{0,127}$", package) is None:
            raise ValueError("invalid package")
        command.append(package)
    elif action_id in ("package.install", "package.update", "package.remove"):
        if set(params) != {"package"}:
            raise ValueError("package is required")
        package = params["package"]
        if not isinstance(package, str) or not re.match(r"^[A-Za-z0-9][A-Za-z0-9._+:@%/-]{0,127}$", package):
            raise ValueError("invalid package")
        command.append(package)
        if action_id == "package.remove":
            command.append("--confirm")
    elif params:
        raise ValueError("action does not accept parameters")
    return tuple(command)


def _run(command):
    log("action.start", command=command)
    process = subprocess.Popen(
        command,
        shell=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True,
    )
    stdout, _ = process.communicate()
    output = (stdout or "").strip()
    log("action.result", command=command, returncode=process.returncode, output=output)
    return process.returncode, output


def run_action(action_id, params=None):
    return _run(build_action_command(action_id, params))
