import json

from Components.ActionMap import ActionMap
from Components.Label import Label
from Components.MenuList import MenuList
from Components.Sources.StaticText import StaticText
from Screens.MessageBox import MessageBox
from Screens.Screen import Screen

from .actions import run_action


class ActionResult(Screen):
    skin = """
    <screen name="ActionResult" position="center,center" size="900,520" title="Enigma2 Universal Panel">
        <widget name="text" position="30,30" size="840,430" font="Regular;22" valign="top" />
        <widget name="hint" position="30,465" size="840,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session, title, text):
        Screen.__init__(self, session)
        self["text"] = Label(title + "\\n\\n" + (text or "No output."))
        self["hint"] = Label("OK / EXIT: Back")
        self["actions"] = ActionMap(["OkCancelActions"], {"ok": self.close, "cancel": self.close}, -2)


class Dashboard(Screen):
    skin = """
    <screen name="Dashboard" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,80" size="930,450" font="Regular;22" valign="top" />
        <widget name="hint" position="35,555" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Enigma2 Universal Panel — Dashboard")
        self["state"] = Label("Loading receiver state...")
        self["hint"] = Label("GREEN: Refresh    EXIT: Close")
        self["actions"] = ActionMap(["OkCancelActions", "ColorActions"], {
            "cancel": self.close,
            "green": self.refresh,
        }, -2)
        self.onLayoutFinish.append(self.refresh)

    def _kv(self, text):
        values = {}
        for line in text.splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                values[key.strip()] = value.strip() or "unknown"
        return values

    def refresh(self):
        code, output = run_action("receiver.status")
        if code != 0:
            self["state"].setText("Status unavailable.\\n\\n" + (output or "unknown"))
            return
        state = self._kv(output)
        cap_code, cap_output = run_action("receiver.capabilities")
        capabilities = []
        if cap_code == 0:
            capabilities = [line.split("=", 1)[0] for line in cap_output.splitlines() if line.endswith("=1")]
        lines = [
            "Panel version: %s" % state.get("panel_version", "unknown"),
            "Receiver: %s" % state.get("hostname", "unknown"),
            "Image: %s" % state.get("image", "unknown"),
            "Adapter: %s" % state.get("adapter", "unknown"),
            "Architecture: %s" % state.get("architecture", "unknown"),
            "Enigma2: %s" % state.get("enigma2_version", "unknown"),
            "Package manager: %s" % state.get("package_manager", "unknown"),
            "Network: %s" % state.get("network", "unknown"),
            "Storage available: %s KB" % state.get("available_storage_kb", "unknown"),
            "",
            "Capabilities:",
        ]
        lines.extend("  - " + item for item in capabilities) if capabilities else lines.append("  - unknown")
        self["state"].setText("\\n".join(lines))


class Enigma2UniversalPanel(Screen):
    skin = """
    <screen name="Enigma2UniversalPanel" position="center,center" size="900,600" title="Enigma2 Universal Panel">
        <widget name="menu" position="35,70" size="830,420" itemHeight="50" font="Regular;26" />
        <widget name="title" position="35,20" size="830,40" font="Regular;30" />
        <widget name="hint" position="35,520" size="830,35" font="Regular;20" />
    </screen>
    """

    ENTRIES = (("Dashboard", "dashboard"), ("Receiver Status", "receiver.status"), ("Capabilities", "receiver.capabilities"), ("Diagnostics", "receiver.diagnose"), ("Package State", "receiver.package_state"))

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Enigma2 Universal Panel")
        self["hint"] = Label("UP/DOWN: Select    OK: Open    EXIT: Close")
        self["menu"] = MenuList([entry[0] for entry in self.ENTRIES])
        self["actions"] = ActionMap(["OkCancelActions"], {"ok": self.activate, "cancel": self.close}, -2)

    def activate(self):
        index = self["menu"].getSelectionIndex()
        if index is None or index < 0 or index >= len(self.ENTRIES):
            return
        title, action_id = self.ENTRIES[index]
        if action_id == "dashboard":
            self.session.open(Dashboard)
            return
        try:
            code, output = run_action(action_id)
        except Exception as exc:
            self.session.open(MessageBox, "Action failed: %s" % exc, MessageBox.TYPE_ERROR)
            return
        if action_id == "receiver.package_state" and code == 0:
            try:
                output = json.dumps(json.loads(output), indent=2)
            except (TypeError, ValueError):
                pass
        if code != 0:
            output = "Command failed with exit code %s.\\n\\n%s" % (code, output)
        self.session.open(ActionResult, title, output)


def main(session, **kwargs):
    session.open(Enigma2UniversalPanel)
