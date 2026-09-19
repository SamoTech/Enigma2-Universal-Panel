"""Fixed, registered GUI actions. No arbitrary shell execution is permitted."""

import subprocess


ACTIONS = {
    "receiver.status": {"command": ("/usr/local/bin/e2panel", "status"), "risk": "low", "confirmation": False},
    "receiver.capabilities": {"command": ("/usr/local/bin/e2panel", "capabilities"), "risk": "low", "confirmation": False},
    "receiver.diagnose": {"command": ("/usr/local/bin/e2panel", "diagnose"), "risk": "low", "confirmation": False},
    "receiver.package_state": {"command": ("/usr/local/bin/e2panel", "package-state"), "risk": "low", "confirmation": False},
}


def run_action(action_id):
    action = ACTIONS.get(action_id)
    if action is None:
        raise ValueError("unregistered action")
    result = subprocess.run(
        list(action["command"]),
        shell=False,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return result.returncode, result.stdout.strip()
