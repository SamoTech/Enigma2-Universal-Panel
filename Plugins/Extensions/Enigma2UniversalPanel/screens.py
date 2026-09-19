import json

from Components.ActionMap import ActionMap
from Components.Label import Label
from Components.MenuList import MenuList
from Screens.InputBox import InputBox
from enigma import eConsoleAppContainer
from Screens.MessageBox import MessageBox
from Screens.Screen import Screen

from .actions import build_action_command, run_action


class ActionResult(Screen):
    skin = """
    <screen name="ActionResult" position="center,center" size="900,520" title="Enigma2 Universal Panel">
        <widget name="text" position="30,30" size="840,430" font="Regular;22" valign="top" />
        <widget name="hint" position="30,465" size="840,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session, title, text):
        Screen.__init__(self, session)
        self["text"] = Label(title + "\n\n" + (text or "No output."))
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
        self["actions"] = ActionMap(["OkCancelActions", "ColorActions"], {"cancel": self.close, "green": self.refresh}, -2)
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
            self["state"].setText("Status unavailable.\n\n" + (output or "unknown"))
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
        self["state"].setText("\n".join(lines))


class PackageBrowser(Screen):
    skin = """
    <screen name="PackageBrowser" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,80" size="930,450" font="Regular;20" valign="top" />
        <widget name="hint" position="35,555" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Packages — receiver configured sources")
        self["state"] = Label("Loading package state...")
        self["hint"] = Label("GREEN: Refresh    EXIT: Close")
        self["actions"] = ActionMap(["OkCancelActions", "ColorActions"], {"cancel": self.close, "green": self.refresh}, -2)
        self.onLayoutFinish.append(self.refresh)

    def refresh(self):
        code, output = run_action("receiver.package_state")
        if code != 0:
            self["state"].setText("Package state unavailable.\n\n" + (output or "unknown"))
            return
        try:
            state = json.loads(output)
        except (TypeError, ValueError):
            self["state"].setText("Invalid package-state response.\n\n" + (output or "unknown"))
            return
        installed = state.get("installed_packages") or []
        available = state.get("available_packages") or []
        feeds = state.get("feeds") or []
        lines = [
            "Package manager: %s" % state.get("package_manager", "unknown"),
            "Image: %s" % state.get("image", "unknown"),
            "Architecture: %s" % state.get("architecture", "unknown"),
            "Network: %s" % state.get("network", "unknown"),
            "Configured sources: %d" % len(feeds),
            "Installed packages: %d" % len(installed),
            "Available packages: %d" % len(available),
            "",
            "Installed (first 20):",
        ]
        lines.extend("  - %s %s" % (item.get("name", "unknown"), item.get("version", "unknown")) for item in installed[:20])
        lines.append("")
        lines.append("Available (first 20):")
        lines.extend("  - %s %s" % (item.get("name", "unknown"), item.get("version", "unknown")) for item in available[:20])
        self["state"].setText("\n".join(lines))


class PackageInstallProgress(Screen):
    skin = """
    <screen name="PackageInstallProgress" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,85" size="930,430" font="Regular;20" valign="top" />
        <widget name="hint" position="35,555" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session, plugin_id, command, operation="Installing", requires_gui_restart=False):
        Screen.__init__(self, session)
        self.plugin_id = plugin_id
        self.command = tuple(command)
        self.operation = operation
        self.requires_gui_restart = requires_gui_restart
        self.output = ""
        self.finished = False
        self["title"] = Label("%s plugin: %s" % (operation, plugin_id))
        self["state"] = Label("Starting native package operation...")
        self["hint"] = Label("Please wait — %s running" % operation.lower())
        self["actions"] = ActionMap(
            ["OkCancelActions"],
            {"ok": self._close_when_finished, "cancel": self._close_when_finished},
            -2,
        )
        self.container = eConsoleAppContainer()
        self.container.dataAvail.append(self._data_available)
        self.container.appClosed.append(self._finished)
        self.onClose.append(self._cleanup)
        self.container.execute(*self.command)

    def _close_when_finished(self):
        if self.finished:
            self.close()

    def _data_available(self, data):
        if isinstance(data, bytes):
            data = data.decode("utf-8", "replace")
        self.output += data or ""
        tail = self.output[-2600:].strip()
        self["state"].setText("%s from receiver-configured sources...\n\n%s" % (self.operation, (tail or "Package manager running...")))

    def _finished(self, retval):
        self.finished = True
        if retval == 0:
            text = (
                "%s completed.\n\nPostcondition verification: PASS\n"
                "Audit record: written by receiver action\n\n"
                "Plugin: %s" % (self.operation, self.plugin_id)
            )
            self["state"].setText(text)
            if self.requires_gui_restart:
                self["hint"].setText("OK / EXIT: Close — GUI restart may be required")
            else:
                self["hint"].setText("OK / EXIT: Close")
        else:
            text = (
                "%s failed or was blocked.\n\n"
                "Exit code: %s\n"
                "Postcondition: NOT VERIFIED\n\n%s"
                % (self.operation, retval, self.output[-2200:].strip())
            )
            self["state"].setText(text)
            self["hint"].setText("OK / EXIT: Close")

    def _cleanup(self):
        if not self.finished:
            try:
                self.container.kill()
            except Exception:
                pass



class PluginMetadata(Screen):
    skin = """
    <screen name="PluginMetadata" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,80" size="930,450" font="Regular;20" valign="top" />
        <widget name="hint" position="35,555" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session, plugin_id):
        Screen.__init__(self, session)
        self.plugin_id = plugin_id
        self["title"] = Label("Plugin Metadata — %s" % plugin_id)
        self["state"] = Label("Loading metadata...")
        self["hint"] = Label("OK / EXIT: Close")
        self["actions"] = ActionMap(["OkCancelActions"], {"ok": self.close, "cancel": self.close}, -2)
        self.onLayoutFinish.append(self.refresh)

    def refresh(self):
        try:
            code, output = run_action("plugin.info", {"plugin_id": self.plugin_id})
        except Exception as exc:
            self["state"].setText("Metadata request rejected.\n\n%s" % exc)
            return
        if code != 0:
            self["state"].setText("Metadata unavailable.\n\n%s" % (output or "unknown"))
            return
        try:
            metadata = json.loads(output)
        except (TypeError, ValueError):
            self["state"].setText(output or "Invalid metadata response.")
            return
        lines = [
            "Name: %s" % metadata.get("name", "unknown"),
            "Category: %s" % metadata.get("category", "unknown"),
            "Author: %s" % metadata.get("author", "unknown"),
            "Package: %s" % metadata.get("package", "unknown"),
            "Status: %s" % metadata.get("status", "unknown"),
            "Installable: %s" % metadata.get("installable", "unknown"),
            "Updatable: %s" % metadata.get("updatable", "unknown"),
            "Removable: %s" % metadata.get("removable", "unknown"),
            "Requires GUI restart: %s" % metadata.get("requires_gui_restart", "unknown"),
            "Requires reboot: %s" % metadata.get("requires_reboot", "unknown"),
            "Compatibility confidence: %s" % metadata.get("compatibility_confidence", "unknown"),
            "Source type: %s" % metadata.get("source_type", "unknown"),
            "",
            "Receiver package state:",
            "Installed version: %s" % metadata.get("installed_version", "unknown"),
            "Candidate version: %s" % metadata.get("candidate_version", "unknown"),
        ]
        self["state"].setText("\n".join(lines))


class Enigma2UniversalPanel(Screen):
    skin = """
    <screen name="Enigma2UniversalPanel" position="center,center" size="900,600" title="Enigma2 Universal Panel">
        <widget name="menu" position="35,70" size="830,420" itemHeight="50" font="Regular;26" />
        <widget name="title" position="35,20" size="830,40" font="Regular;30" />
        <widget name="hint" position="35,520" size="830,35" font="Regular;20" />
    </screen>
    """

    ENTRIES = (
        ("Dashboard", "dashboard"),
        ("Package Browser", "package-browser"),
        ("Resolve Plugin", "plugin.resolve"),
        ("Preview Plugin", "plugin.preview"),
        ("Plugin Metadata", "plugin.info"),
        ("Install Plugin", "plugin.install"),
        ("Update Plugin", "plugin.update"),
        ("Receiver Status", "receiver.status"),
        ("Capabilities", "receiver.capabilities"),
        ("Diagnostics", "receiver.diagnose"),
        ("Package State", "receiver.package_state"),
    )

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Enigma2 Universal Panel")
        self["hint"] = Label("UP/DOWN: Select    OK: Open    EXIT: Close")
        self["menu"] = MenuList([entry[0] for entry in self.ENTRIES])
        self["actions"] = ActionMap(["OkCancelActions"], {"ok": self.activate, "cancel": self.close}, -2)

    def _plugin_input(self, action_id):
        title = "Resolve plugin ID" if action_id == "plugin.resolve" else "Preview plugin ID"
        self.session.openWithCallback(lambda value: self._run_plugin_action(action_id, value), InputBox, title=title, text="")

    def _plugin_metadata_input(self):
        self.session.openWithCallback(lambda value: self._open_plugin_metadata(value), InputBox, title="Plugin metadata ID", text="")

    def _open_plugin_metadata(self, value):
        if value is None or value.strip() == "":
            return
        self.session.open(PluginMetadata, value.strip())

    def _prepare_update(self, value):
        if value is None or value.strip() == "":
            return
        plugin_id = value.strip()
        try:
            code, output = run_action("plugin.preview", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        try:
            preview = json.loads(output)
        except (TypeError, ValueError):
            self.session.open(MessageBox, "Invalid compatibility evidence returned by receiver.", MessageBox.TYPE_ERROR)
            return
        if code != 0 or preview.get("status") != "supported" or preview.get("action") != "update_or_reinstall":
            self.session.open(MessageBox, "Update blocked.\n\nCompatibility: %s\nAction: %s" % (preview.get("status", "unknown"), preview.get("action", "blocked")), MessageBox.TYPE_ERROR)
            return
        summary = (
            "Update plugin: %s\n\nPackage: %s\n"
            "Installed: %s\nCandidate: %s\n"
            "GUI restart required: %s\n\n"
            "This operation uses only receiver-configured package sources.\n"
            "Do you want to continue?"
            % (plugin_id, preview.get("package", "unknown"), preview.get("installed_version", "unknown"),
               preview.get("candidate_version", "unknown"), preview.get("requires_gui_restart", "unknown"))
        )
        self.session.openWithCallback(
            lambda confirmed: self._start_update(confirmed, plugin_id, bool(preview.get("requires_gui_restart") is True)),
            MessageBox, summary, MessageBox.TYPE_YESNO,
        )

    def _start_update(self, confirmed, plugin_id, requires_gui_restart):
        if not confirmed:
            return
        try:
            command = build_action_command("plugin.update", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        self.session.open(PackageInstallProgress, plugin_id, command, "Updating", requires_gui_restart)

    def _plugin_install_input(self):
        self.session.openWithCallback(self._prepare_install, InputBox, title="Install plugin ID", text="")

    def _prepare_install(self, value):
        if value is None or value.strip() == "":
            return
        plugin_id = value.strip()
        try:
            code, output = run_action("plugin.preview", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        try:
            preview = json.loads(output)
        except (TypeError, ValueError):
            self.session.open(MessageBox, "Invalid compatibility evidence returned by receiver.", MessageBox.TYPE_ERROR)
            return
        if code != 0 or preview.get("status") != "supported":
            self.session.open(
                MessageBox,
                "Installation blocked.\n\nCompatibility: %s\nRisk: %s\nAction: %s"
                % (preview.get("status", "unknown"), preview.get("risk", "unknown"), preview.get("action", "blocked")),
                MessageBox.TYPE_ERROR,
            )
            return
        summary = (
            "Install plugin: %s\n\n"
            "Package: %s\n"
            "Candidate: %s\n"
            "Image compatibility: %s\n"
            "Architecture compatibility: %s\n"
            "Package architecture: %s\n"
            "Dependencies: %s\n\n"
            "This operation uses only receiver-configured package sources.\n"
            "Do you want to continue?"
            % (
                plugin_id,
                preview.get("package", "unknown"),
                preview.get("candidate_version", "unknown"),
                preview.get("compatibility", {}).get("image", "unknown"),
                preview.get("compatibility", {}).get("architecture", "unknown"),
                preview.get("compatibility", {}).get("package_architecture", "unknown"),
                preview.get("dependency_status", "unknown"),
            )
        )
        self.session.openWithCallback(
            lambda confirmed: self._start_install(confirmed, plugin_id),
            MessageBox,
            summary,
            MessageBox.TYPE_YESNO,
        )

    def _start_install(self, confirmed, plugin_id):
        if not confirmed:
            return
        try:
            command = build_action_command("plugin.install", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        self.session.open(PackageInstallProgress, plugin_id, command)

    def _run_plugin_action(self, action_id, value):
        if value is None or value == "":
            return
        try:
            code, output = run_action(action_id, {"plugin_id": value.strip()})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        title = "Plugin Resolution" if action_id == "plugin.resolve" else "Plugin Installation Preview"
        if code != 0:
            output = "Command failed with exit code %s.\n\n%s" % (code, output)
        self.session.open(ActionResult, title, output)

    def activate(self):
        index = self["menu"].getSelectionIndex()
        if index is None or index < 0 or index >= len(self.ENTRIES):
            return
        title, action_id = self.ENTRIES[index]
        if action_id == "dashboard":
            self.session.open(Dashboard)
            return
        if action_id == "package-browser":
            self.session.open(PackageBrowser)
            return
        if action_id in ("plugin.resolve", "plugin.preview", "plugin.info"):
            if action_id == "plugin.info":
                self._plugin_metadata_input()
            else:
                self._plugin_input(action_id)
            return
        if action_id == "plugin.install":
            self._plugin_install_input()
            return
        if action_id == "plugin.update":
            self.session.openWithCallback(self._prepare_update, InputBox, title="Update plugin ID", text="")
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
            output = "Command failed with exit code %s.\n\n%s" % (code, output)
        self.session.open(ActionResult, title, output)


def main(session, **kwargs):
    session.open(Enigma2UniversalPanel)
