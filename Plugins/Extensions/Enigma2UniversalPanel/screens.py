import json

from Components.ActionMap import ActionMap
from Components.Label import Label
from Components.MenuList import MenuList
from Screens.InputBox import InputBox
from enigma import eConsoleAppContainer
from Screens.MessageBox import MessageBox
from Screens.Screen import Screen

from .actions import build_action_command, run_action
from .audit_history import AuditHistory


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
        telemetry = {}
        telemetry_code, telemetry_output = run_action("receiver.telemetry")
        if telemetry_code == 0:
            telemetry = self._kv(telemetry_output)
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
            "CPU load: %s / %s / %s" % (
                telemetry.get("load_1", "unknown"),
                telemetry.get("load_5", "unknown"),
                telemetry.get("load_15", "unknown"),
            ),
            "RAM: %s MB used / %s MB total (%s%%)" % (
                telemetry.get("ram_used_mb", "unknown"),
                telemetry.get("ram_total_mb", "unknown"),
                telemetry.get("ram_used_percent", "unknown"),
            ),
            "Root filesystem: %s KB available (%s%% used)" % (
                telemetry.get("root_available_kb", "unknown"),
                telemetry.get("root_used_percent", "unknown"),
            ),
            "",
            "Capabilities:",
        ]
        lines.extend("  - " + item for item in capabilities) if capabilities else lines.append("  - unknown")
        self["state"].setText("\n".join(lines))


class ReceiverTelemetry(Screen):
    skin = """
    <screen name="ReceiverTelemetry" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,80" size="930,450" font="Regular;22" valign="top" />
        <widget name="hint" position="35,555" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Receiver Telemetry")
        self["state"] = Label("Reading telemetry...")
        self["hint"] = Label("GREEN: Refresh    EXIT: Close")
        self["actions"] = ActionMap(
            ["OkCancelActions", "ColorActions"],
            {"cancel": self.close, "green": self.refresh},
            -2,
        )
        self.onLayoutFinish.append(self.refresh)

    @staticmethod
    def _kv(text):
        values = {}
        for line in text.splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                values[key.strip()] = value.strip() or "unknown"
        return values

    def refresh(self):
        try:
            code, output = run_action("receiver.telemetry")
        except Exception as exc:
            self["state"].setText("Telemetry request rejected.\n\n%s" % exc)
            return
        if code != 0:
            self["state"].setText("Telemetry unavailable.\n\n%s" % (output or "unknown"))
            return
        values = self._kv(output)
        lines = [
            "CPU load (1 min): %s" % values.get("load_1", "unknown"),
            "CPU load (5 min): %s" % values.get("load_5", "unknown"),
            "CPU load (15 min): %s" % values.get("load_15", "unknown"),
            "",
            "RAM total: %s MB" % values.get("ram_total_mb", "unknown"),
            "RAM available: %s MB" % values.get("ram_available_mb", "unknown"),
            "RAM used: %s MB (%s%%)" % (
                values.get("ram_used_mb", "unknown"),
                values.get("ram_used_percent", "unknown"),
            ),
            "MemFree kernel value: %s KB" % values.get("mem_free_kb", "unknown"),
            "",
            "Root filesystem total: %s KB" % values.get("root_total_kb", "unknown"),
            "Root filesystem available: %s KB" % values.get("root_available_kb", "unknown"),
            "Root filesystem used: %s%%" % values.get("root_used_percent", "unknown"),
            "",
            "Python runtime: %s" % values.get("python_version", "unknown"),
        ]
        self["state"].setText("\n".join(lines))


class PluginLibrary(Screen):
    skin = """
    <screen name="PluginLibrary" position="center,center" size="1000,650" title="Enigma2 Plugin Library">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="menu" position="35,80" size="930,365" itemHeight="42" font="Regular;21" />
        <widget name="details" position="35,455" size="930,100" font="Regular;18" valign="top" />
        <widget name="hint" position="35,575" size="930,35" font="Regular;19" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Plugin Library — All Categories")
        self["menu"] = MenuList([])
        self["details"] = Label("Loading plugin library...")
        self["hint"] = Label("OK: Details    GREEN: Install    RED: Category    BLUE: Search    YELLOW: Refresh    EXIT: Close")
        self["actions"] = ActionMap(
            ["OkCancelActions", "ColorActions"],
            {"ok": self.show_details, "cancel": self.close, "green": self.install_selected, "yellow": self.refresh, "blue": self.search, "red": self.cycle_category},
            -2,
        )
        self.entries = []
        self.filtered_entries = []
        self.categories = []
        self.category_index = 0
        self.category_filter = "all"
        self.search_term = ""
        self.onLayoutFinish.append(self.refresh)
        self["menu"].onSelectionChanged.append(self._selection_changed)

    def refresh(self):
        try:
            code, output = run_action("plugin.library")
        except Exception as exc:
            self.entries = []
            self.filtered_entries = []
            self["menu"].setList([])
            self["details"].setText("Plugin library request rejected.\n%s" % exc)
            return
        if code != 0:
            self.entries = []
            self.filtered_entries = []
            self["menu"].setList([])
            self["details"].setText("Plugin library unavailable.\n%s" % (output or "unknown"))
            return
        try:
            data = json.loads(output)
            self.entries = data.get("entries") or []
            self.categories = data.get("categories") or []
        except (TypeError, ValueError, AttributeError):
            self.entries = []
            self.filtered_entries = []
            self["menu"].setList([])
            self["details"].setText("Invalid plugin library response.")
            return
        self._apply_filter()

    def _category_name(self):
        if self.category_filter == "all":
            return "All Categories"
        for category in self.categories:
            if category.get("id") == self.category_filter:
                return category.get("name") or self.category_filter
        return self.category_filter.replace("_", " ").title()

    def cycle_category(self):
        category_ids = ["all"] + [x.get("id") for x in self.categories if x.get("id")]
        if not category_ids:
            return
        self.category_index = (self.category_index + 1) % len(category_ids)
        self.category_filter = category_ids[self.category_index]
        self["title"].setText("Plugin Library — %s" % self._category_name())
        self._apply_filter()

    def _apply_filter(self):
        term = self.search_term.lower().strip()
        category = self.category_filter
        self.filtered_entries = [
            entry for entry in self.entries
            if (category == "all" or entry.get("category") == category)
            and (
                not term
                or term in str(entry.get("name", "")).lower()
                or term in str(entry.get("id", "")).lower()
                or term in str(entry.get("category", "")).lower()
                or term in str(entry.get("category_name", "")).lower()
                or term in str(entry.get("author", "")).lower()
            )
        ]
        choices = []
        for entry in self.filtered_entries:
            source = "Feed" if entry.get("source") == "receiver_feed" else "Community"
            item_type = entry.get("item_type", "plugin")
            availability = entry.get("availability", "unknown")
            choices.append(
                "%s  [%s | %s | %s]"
                % (entry.get("name", "unknown"), item_type, source, availability)
            )
        self["menu"].setList(choices)
        self._selection_changed()

    def search(self):
        self.session.openWithCallback(self._search_done, InputBox, title="Search Plugin Library", text=self.search_term)

    def _search_done(self, value):
        if value is None:
            return
        self.search_term = value.strip()
        self._apply_filter()

    def _selected_entry(self):
        index = self["menu"].getSelectionIndex()
        if index is None or index < 0 or index >= len(self.filtered_entries):
            return None
        return self.filtered_entries[index]

    def _selection_changed(self):
        entry = self._selected_entry()
        if not entry:
            self["details"].setText("No plugin selected.")
            return
        source = "Receiver feed" if entry.get("source") == "receiver_feed" else "Community source"
        self["details"].setText(
            "%s | %s | %s\n%s | %s"
            % (
                entry.get("category_name", entry.get("category", "unknown")),
                entry.get("author", "unknown"),
                source,
                entry.get("status", "unknown"),
                entry.get("compatibility_confidence", "unknown"),
            )
        )

    def install_selected(self):
        entry = self._selected_entry()
        if not entry:
            return
        if entry.get("source") != "receiver_feed" or not entry.get("installable"):
            self.session.open(
                MessageBox,
                "This entry is not currently installable through the receiver feed.\n\n"
                "Community installers remain blocked until explicit source admission.",
                MessageBox.TYPE_ERROR,
            )
            return
        plugin_id = entry.get("id", "")
        try:
            code, output = run_action("plugin.preview", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Installation request rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        try:
            preview = json.loads(output)
        except (TypeError, ValueError):
            self.session.open(MessageBox, "Invalid compatibility evidence returned by receiver.", MessageBox.TYPE_ERROR)
            return
        if code != 0 or preview.get("status") != "supported":
            self.session.open(
                MessageBox,
                "Installation blocked.\n\nCompatibility: %s\nAction: %s"
                % (preview.get("status", "unknown"), preview.get("action", "blocked")),
                MessageBox.TYPE_ERROR,
            )
            return
        summary = (
            "Install plugin: %s\n\n"
            "Package: %s\n"
            "Candidate: %s\n"
            "Compatibility: supported\n"
            "Dependencies: %s\n\n"
            "Source: receiver-configured package feed\n"
            "Continue?"
            % (
                entry.get("name", plugin_id),
                preview.get("package", "unknown"),
                preview.get("candidate_version", "unknown"),
                preview.get("dependency_status", "none"),
            )
        )
        self.session.openWithCallback(
            lambda confirmed: self._start_library_install(
                confirmed,
                plugin_id,
                bool(preview.get("requires_gui_restart") is True),
            ),
            MessageBox,
            summary,
            MessageBox.TYPE_YESNO,
        )

    def _start_library_install(self, confirmed, plugin_id, requires_gui_restart):
        if not confirmed:
            return
        try:
            command = build_action_command("plugin.install", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Installation action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        self.session.open(
            PackageInstallProgress,
            plugin_id,
            command,
            "Installing",
            requires_gui_restart,
        )

    def show_details(self):
        entry = self._selected_entry()
        if not entry:
            return
        lines = [
            "Name: %s" % entry.get("name", "unknown"),
            "Plugin ID: %s" % entry.get("id", "unknown"),
            "Category: %s" % entry.get("category", "unknown"),
            "Subcategory: %s" % entry.get("subcategory", "unknown"),
            "Author: %s" % entry.get("author", "unknown"),
            "Type: %s" % entry.get("item_type", "plugin"),
            "Source: %s" % entry.get("source", "unknown"),
            "Source reference: %s" % entry.get("source_reference", entry.get("repository", "unknown")),
            "Availability: %s" % entry.get("availability", "unknown"),
            "Status: %s" % entry.get("status", "unknown"),
            "Compatibility: %s" % entry.get("compatibility_confidence", "unknown"),
            "Installable: %s" % entry.get("installable", False),
            "Updatable: %s" % entry.get("updatable", False),
            "Removable: %s" % entry.get("removable", False),
            "Repository: %s" % entry.get("repository", "unknown"),
        ]
        if entry.get("source") == "community":
            lines.extend([
                "Network: %s" % entry.get("network_reachability", "unknown"),
                "Maintenance: %s" % entry.get("maintenance_status", "unknown"),
                "",
                "Community execution is currently blocked until source admission is complete.",
            ])
            self.session.open(ActionResult, "Plugin Library — Community Entry", "\n".join(lines))
            return

        self.session.open(PluginMetadata, entry.get("id", ""))

class ReceiverCompatibility(Screen):
    skin = """
    <screen name="ReceiverCompatibility" position="center,center" size="1000,650" title="Receiver Compatibility">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,80" size="930,440" font="Regular;20" valign="top" />
        <widget name="hint" position="35,555" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Receiver Compatibility")
        self["state"] = Label("Detecting device and image...")
        self["hint"] = Label("GREEN: Refresh    EXIT: Close")
        self["actions"] = ActionMap(
            ["OkCancelActions", "ColorActions"],
            {"ok": self.close, "cancel": self.close, "green": self.refresh},
            -2,
        )
        self.onLayoutFinish.append(self.refresh)

    def refresh(self):
        try:
            code, output = run_action("receiver.compatibility")
        except Exception as exc:
            self["state"].setText("Compatibility request rejected.\n\n%s" % exc)
            return
        if code != 0:
            self["state"].setText("Compatibility unavailable.\n\n%s" % (output or "unknown"))
            return
        try:
            data = json.loads(output)
        except (TypeError, ValueError):
            self["state"].setText("Invalid compatibility response.\n\n%s" % (output or "unknown"))
            return

        device = data.get("device") or {}
        image = data.get("image") or {}
        runtime = data.get("runtime") or {}
        package = data.get("package") or {}
        architecture = data.get("architecture") or {}

        lines = [
            "Overall: %s" % data.get("overall", "unknown"),
            "Reason: %s" % data.get("reason", "unknown"),
            "",
            "DEVICE",
            "Vendor: %s" % device.get("vendor", "unknown"),
            "Family: %s" % device.get("family", "unknown"),
            "Model: %s" % device.get("model", "unknown"),
            "Machine: %s" % device.get("machine", "unknown"),
            "Chipset: %s" % device.get("chipset", "unknown"),
            "",
            "IMAGE",
            "Image: %s" % image.get("id", "unknown"),
            "Family: %s" % image.get("family", "unknown"),
            "Version: %s" % image.get("version", "unknown"),
            "Adapter: %s" % data.get("adapter", "unknown"),
            "",
            "RUNTIME",
            "Enigma2: %s" % runtime.get("enigma2_version", "unknown"),
            "Python: %s" % runtime.get("python_version", "unknown"),
            "Native GUI: %s" % runtime.get("native_gui", "unknown"),
            "Architecture: %s (%s)" % (architecture.get("raw", "unknown"), architecture.get("family", "unknown")),
            "Package backend: %s (%s)" % (package.get("manager", "unknown"), package.get("family", "unknown")),
            "Package install capability: %s" % package.get("install_capability", "unknown"),
            "",
            "Physical receiver validation: %s" % data.get("real_receiver_validation", False),
        ]
        self["state"].setText("\n".join(lines))


class CommunityInstallerCatalog(Screen):
    skin = """
    <screen name="CommunityInstallerCatalog" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="menu" position="35,80" size="930,390" itemHeight="48" font="Regular;22" />
        <widget name="details" position="35,485" size="930,70" font="Regular;18" valign="top" />
        <widget name="hint" position="35,575" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Community Installer Registry")
        self["menu"] = MenuList([])
        self["details"] = Label("Loading registry...")
        self["hint"] = Label("OK: Details    GREEN: Refresh    EXIT: Close")
        self["actions"] = ActionMap(
            ["OkCancelActions", "ColorActions"],
            {"ok": self.show_details, "cancel": self.close, "green": self.refresh},
            -2,
        )
        self.entries = []
        self.onLayoutFinish.append(self.refresh)
        self["menu"].onSelectionChanged.append(self._selection_changed)

    def refresh(self):
        try:
            code, output = run_action("community.catalog")
        except Exception as exc:
            self["menu"].setList([])
            self["details"].setText("Registry request rejected.\n%s" % exc)
            return
        if code != 0:
            self["menu"].setList([])
            self["details"].setText("Registry unavailable.\n%s" % (output or "unknown"))
            return
        try:
            data = json.loads(output)
            self.entries = data.get("entries") or []
        except (TypeError, ValueError, AttributeError):
            self["menu"].setList([])
            self["details"].setText("Invalid community registry.")
            return
        choices = []
        for entry in self.entries:
            status = entry.get("execution_status", "unknown")
            choices.append("%s  [%s]" % (entry.get("name", "unknown"), status))
        self["menu"].setList(choices)
        self._selection_changed()

    def _selected_entry(self):
        index = self["menu"].getSelectionIndex()
        if index is None or index < 0 or index >= len(self.entries):
            return None
        return self.entries[index]

    def _selection_changed(self):
        entry = self._selected_entry()
        if not entry:
            self["details"].setText("No registry entry selected.")
            return
        self["details"].setText(
            "%s | %s | source=%s | health=%s\n%s"
            % (
                entry.get("developer", "unknown"),
                entry.get("delivery", "unknown"),
                entry.get("source_status", "unknown"),
                (entry.get("health") or {}).get("network_reachability", "unknown"),
                entry.get("notes", ""),
            )
        )

    def show_details(self):
        entry = self._selected_entry()
        if not entry:
            return
        lines = [
            "Name: %s" % entry.get("name", "unknown"),
            "Developer: %s" % entry.get("developer", "unknown"),
            "Category: %s" % entry.get("category", "unknown"),
            "Repository: %s" % entry.get("repository", "unknown"),
            "Pinned source ref: %s" % entry.get("source_ref", "unknown"),
            "Installer path: %s" % entry.get("installer_path", "none"),
            "Delivery: %s" % entry.get("delivery", "unknown"),
            "Source status: %s" % entry.get("source_status", "unknown"),
            "Execution status: %s" % entry.get("execution_status", "unknown"),
            "Version: %s" % entry.get("installer_version", entry.get("release_version", "unknown")),
            "Hosting: %s" % (entry.get("health") or {}).get("hosting_type", "unknown"),
            "Reachability: %s" % (entry.get("health") or {}).get("network_reachability", "unknown"),
            "Maintenance: %s" % (entry.get("health") or {}).get("maintenance_status", "unknown"),
            "",
            entry.get("notes", ""),
        ]
        self.session.open(ActionResult, "Community Installer Metadata", "\n".join(lines))


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
                self["hint"].setText("OK / EXIT: Close — GUI restart required")
                self._offer_gui_restart()
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

    def _offer_gui_restart(self):
        self.session.openWithCallback(
            self._restart_gui_confirmed,
            MessageBox,
            "The %s operation completed successfully.\n\n"
            "This plugin metadata declares that an Enigma2 GUI restart is required.\n"
            "Restart the GUI now?"
            % self.operation,
            MessageBox.TYPE_YESNO,
        )

    def _restart_gui_confirmed(self, confirmed):
        if not confirmed:
            self["hint"].setText("OK / EXIT: Close — GUI restart deferred")
            return
        try:
            command = build_action_command("receiver.restart_gui")
        except Exception as exc:
            self["hint"].setText("GUI restart action rejected: %s" % exc)
            return
        self.session.open(RestartGuiProgress, command)

    def _cleanup(self):
        if not self.finished:
            try:
                self.container.kill()
            except Exception:
                pass



class RestartGuiProgress(Screen):
    skin = """
    <screen name="RestartGuiProgress" position="center,center" size="1000,500" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,90" size="930,320" font="Regular;20" valign="top" />
        <widget name="hint" position="35,430" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session, command):
        Screen.__init__(self, session)
        self.finished = False
        self["title"] = Label("Restarting Enigma2 GUI")
        self["state"] = Label("Starting the controlled GUI restart action...")
        self["hint"] = Label("Please wait — Enigma2 may restart this interface")
        self["actions"] = ActionMap(
            ["OkCancelActions"],
            {"ok": self._close_when_finished, "cancel": self._close_when_finished},
            -2,
        )
        self.container = eConsoleAppContainer()
        self.container.appClosed.append(self._finished)
        self.onClose.append(self._cleanup)
        self.container.execute(*tuple(command))

    def _close_when_finished(self):
        if self.finished:
            self.close()

    def _finished(self, retval):
        self.finished = True
        if retval == 0:
            self["state"].setText(
                "GUI restart command completed.\n\n"
                "The Enigma2 GUI should now be restarting.\n"
                "Audit record: written by receiver action."
            )
        else:
            self["state"].setText(
                "GUI restart failed.\n\nExit code: %s\n"
                "The plugin was not able to complete the restart action."
                % retval
            )
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


class PanelSectionMenu(Screen):
    skin = """
    <screen name="PanelSectionMenu" position="center,center" size="900,600" title="Enigma2 Universal Panel">
        <widget name="menu" position="35,70" size="830,420" itemHeight="50" font="Regular;26" />
        <widget name="title" position="35,20" size="830,40" font="Regular;30" />
        <widget name="hint" position="35,520" size="830,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session, title, entries, controller):
        Screen.__init__(self, session)
        self["title"] = Label(title)
        self["hint"] = Label("UP/DOWN: Select    OK: Open    EXIT: Back")
        self.entries = entries
        self.controller = controller
        self["menu"] = MenuList([entry[0] for entry in entries])
        self["actions"] = ActionMap(["OkCancelActions"], {"ok": self.activate, "cancel": self.close}, -2)

    def activate(self):
        index = self["menu"].getSelectionIndex()
        if index is None or index < 0 or index >= len(self.entries):
            return
        _title, action_id = self.entries[index]
        self.controller._dispatch_action(action_id)


class Enigma2UniversalPanel(Screen):
    skin = """
    <screen name="Enigma2UniversalPanel" position="center,center" size="900,600" title="Enigma2 Universal Panel">
        <widget name="menu" position="35,70" size="830,420" itemHeight="50" font="Regular;26" />
        <widget name="title" position="35,20" size="830,40" font="Regular;30" />
        <widget name="hint" position="35,520" size="830,35" font="Regular;20" />
    </screen>
    """

    SECTIONS = (
        ("STORE", (
            ("Plugin Library", "plugin.library"),
            ("Community Sources", "community.catalog"),
            ("Install Plugin", "plugin.install"),
            ("Update Plugin", "plugin.update"),
            ("Remove Plugin", "plugin.remove"),
        )),
        ("RECEIVER", (
            ("Dashboard", "dashboard"),
            ("Compatibility", "receiver.compatibility"),
            ("Telemetry", "receiver.telemetry"),
            ("Status", "receiver.status"),
            ("Capabilities", "receiver.capabilities"),
        )),
        ("MANAGEMENT", (
            ("Package Browser", "package-browser"),
            ("Diagnostics", "receiver.diagnose"),
            ("Package State", "receiver.package_state"),
            ("Audit History", "receiver.audit_history"),
        )),
        ("ADVANCED", (
            ("Resolve Plugin", "plugin.resolve"),
            ("Preview Plugin", "plugin.preview"),
            ("Plugin Metadata", "plugin.info"),
        )),
    )

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Enigma2 Universal Panel")
        self["hint"] = Label("UP/DOWN: Select    OK: Open    EXIT: Close")
        self["menu"] = MenuList([title for title, _entries in self.SECTIONS])
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

    def _prepare_remove(self, value):
        if value is None or value.strip() == "":
            return
        plugin_id = value.strip()
        try:
            code, output = run_action("plugin.remove_preview", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        try:
            preview = json.loads(output)
        except (TypeError, ValueError):
            self.session.open(MessageBox, "Invalid removal safety evidence returned by receiver.", MessageBox.TYPE_ERROR)
            return
        if code != 0 or preview.get("status") != "supported" or preview.get("action") != "remove":
            self.session.open(
                MessageBox,
                "Removal blocked.\n\n"
                "Status: %s\n"
                "Reason: %s\n"
                "Removable: %s\n"
                "Installed: %s"
                % (
                    preview.get("status", "unknown"),
                    preview.get("reason", "unknown"),
                    preview.get("removable", "unknown"),
                    preview.get("installed_version", "unknown"),
                ),
                MessageBox.TYPE_ERROR,
            )
            return
        summary = (
            "Remove plugin: %s\n\n"
            "Package: %s\n"
            "Installed: %s\n"
            "Image compatibility: %s\n"
            "Architecture compatibility: %s\n"
            "Package architecture: %s\n"
            "GUI restart required: %s\n"
            "Reboot required: %s\n\n"
            "This removes the catalog-resolved package through receiver-configured sources.\n"
            "Do you want to continue?"
            % (
                plugin_id,
                preview.get("package", "unknown"),
                preview.get("installed_version", "unknown"),
                preview.get("compatibility", {}).get("image", "unknown"),
                preview.get("compatibility", {}).get("architecture", "unknown"),
                preview.get("compatibility", {}).get("package_architecture", "unknown"),
                preview.get("requires_gui_restart", "unknown"),
                preview.get("requires_reboot", "unknown"),
            )
        )
        self.session.openWithCallback(
            lambda confirmed: self._start_remove(
                confirmed, plugin_id, bool(preview.get("requires_gui_restart") is True)
            ),
            MessageBox,
            summary,
            MessageBox.TYPE_YESNO,
        )

    def _start_remove(self, confirmed, plugin_id, requires_gui_restart):
        if not confirmed:
            return
        try:
            command = build_action_command("plugin.remove", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        self.session.open(PackageInstallProgress, plugin_id, command, "Removing", requires_gui_restart)

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
        if index is None or index < 0 or index >= len(self.SECTIONS):
            return
        title, entries = self.SECTIONS[index]
        self.session.open(PanelSectionMenu, title, entries, self)

    def _dispatch_action(self, action_id):
        if action_id == "dashboard":
            self.session.open(Dashboard)
            return
        if action_id == "package-browser":
            self.session.open(PackageBrowser)
            return
        if action_id == "plugin.library":
            self.session.open(PluginLibrary)
            return
        if action_id == "community.catalog":
            self.session.open(CommunityInstallerCatalog)
            return
        if action_id == "receiver.compatibility":
            self.session.open(ReceiverCompatibility)
            return
        if action_id == "receiver.audit_history":
            self.session.open(AuditHistory)
            return
        if action_id == "receiver.telemetry":
            self.session.open(ReceiverTelemetry)
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
        if action_id == "plugin.remove":
            self.session.openWithCallback(self._prepare_remove, InputBox, title="Remove plugin ID", text="")
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
        self.session.open(ActionResult, action_id, output)

def main(session, **kwargs):
    session.open(Enigma2UniversalPanel)
