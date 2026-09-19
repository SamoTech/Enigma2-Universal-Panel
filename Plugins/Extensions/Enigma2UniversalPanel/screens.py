from Components.ActionMap import ActionMap
from Components.Label import Label
from Components.MenuList import MenuList
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
        self["actions"] = ActionMap(["OkCancelActions"], {
            "ok": self.close,
            "cancel": self.close,
        }, -2)


class Enigma2UniversalPanel(Screen):
    skin = """
    <screen name="Enigma2UniversalPanel" position="center,center" size="900,600" title="Enigma2 Universal Panel">
        <widget name="menu" position="35,70" size="830,420" itemHeight="50" font="Regular;26" />
        <widget name="title" position="35,20" size="830,40" font="Regular;30" />
        <widget name="hint" position="35,520" size="830,35" font="Regular;20" />
    </screen>
    """

    ENTRIES = (
        ("Receiver Status", "receiver.status"),
        ("Capabilities", "receiver.capabilities"),
        ("Diagnostics", "receiver.diagnose"),
    )

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Enigma2 Universal Panel")
        self["hint"] = Label("UP/DOWN: Select    OK: Open    EXIT: Close")
        self["menu"] = MenuList([entry[0] for entry in self.ENTRIES])
        self["actions"] = ActionMap(["OkCancelActions"], {
            "ok": self.activate,
            "cancel": self.close,
        }, -2)

    def activate(self):
        index = self["menu"].getSelectionIndex()
        if index is None or index < 0 or index >= len(self.ENTRIES):
            return
        title, action_id = self.ENTRIES[index]
        try:
            code, output = run_action(action_id)
        except Exception as exc:
            self.session.open(MessageBox, "Action failed: %s" % exc, MessageBox.TYPE_ERROR)
            return
        if code != 0:
            self.session.open(ActionResult, title, "Command failed with exit code %s.\\n\\n%s" % (code, output))
            return
        self.session.open(ActionResult, title, output)


def main(session, **kwargs):
    session.open(Enigma2UniversalPanel)
