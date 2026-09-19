from Components.ActionMap import ActionMap
from Components.Label import Label
from Screens.Screen import Screen

from .actions import run_action


class AuditHistory(Screen):
    """Read-only native view of the receiver audit trail."""

    skin = """
    <screen name="AuditHistory" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,80" size="930,450" font="Regular;20" valign="top" />
        <widget name="hint" position="35,555" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Audit History")
        self["state"] = Label("Loading audit records...")
        self["hint"] = Label("GREEN: Refresh    EXIT: Close")
        self["actions"] = ActionMap(
            ["OkCancelActions", "ColorActions"],
            {"cancel": self.close, "green": self.refresh},
            -2,
        )
        self.onLayoutFinish.append(self.refresh)

    def refresh(self):
        try:
            code, output = run_action("receiver.audit_history")
        except Exception as exc:
            self["state"].setText("Audit history request rejected.\n\n%s" % exc)
            return
        if code != 0:
            self["state"].setText("Audit history unavailable.\n\n%s" % (output or "unknown"))
            return
        self["state"].setText(output or "No audit records available.")
