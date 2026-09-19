import json

from Components.ActionMap import ActionMap
from Components.Label import Label
from Components.MenuList import MenuList
from Components.ScrollLabel import ScrollLabel
from Screens.InputBox import InputBox
from enigma import eConsoleAppContainer
from Screens.MessageBox import MessageBox
from Screens.Screen import Screen

from .actions import build_action_command, run_action
from .debug import DebugActionMap, DebugMenuList, log
from .audit_history import AuditHistory


def _add_scroll_actions(screen, widget_name):
    widget = screen[widget_name]
    screen["scroll_actions_%s" % widget_name] = DebugActionMap(
        ["DirectionActions"],
        {
            "up": widget.pageUp,
            "down": widget.pageDown,
            "left": widget.pageUp,
            "right": widget.pageDown,
        },
        -1,
    )



class ActionResult(Screen):
    skin = """
    <screen name="ActionResult" position="center,center" size="1000,620" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="subtitle" position="35,62" size="930,30" font="Regular;18" />
        <widget name="text" position="35,105" size="930,445" font="Regular;20" valign="top" />
        <widget name="hint" position="35,570" size="930,30" font="Regular;18" />
    </screen>
    """


    def __init__(self, session, title, text):
        Screen.__init__(self, session)
        self["title"] = Label(title)
        self["subtitle"] = Label("Receiver-local result")
        self["text"] = ScrollLabel(text or "No output.")
        self["hint"] = Label("OK / EXIT: Back")
        self["actions"] = DebugActionMap(["OkCancelActions"], {"ok": self.close, "cancel": self.close}, -2)
        _add_scroll_actions(self, "text")


class Dashboard(Screen):
    skin = """
    <screen name="Dashboard" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="summary" position="35,62" size="930,30" font="Regular;18" />
        <widget name="state" position="35,102" size="930,428" font="Regular;21" valign="top" />
        <widget name="hint" position="35,565" size="930,28" font="Regular;18" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Dashboard")
        self["summary"] = Label("Receiver-local system status")
        self["state"] = ScrollLabel("Loading receiver state...")
        self["hint"] = Label("GREEN: Refresh    EXIT: Back")
        self["actions"] = ActionMap(["OkCancelActions", "ColorActions"], {"cancel": self.close, "green": self.refresh}, -2)
        self.onLayoutFinish.append(self.refresh)

        _add_scroll_actions(self, "state")
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
        reboot_status_code, reboot_status_output = run_action("receiver.reboot_status")
        reboot_status = "unknown"
        if reboot_status_code == 0:
            try:
                reboot_status = json.loads(reboot_status_output).get("status", "unknown")
            except (TypeError, ValueError, AttributeError):
                reboot_status = "unknown"
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
            "Reboot verification: %s" % reboot_status,
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
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="summary" position="35,62" size="930,30" font="Regular;18" />
        <widget name="state" position="35,102" size="930,428" font="Regular;21" valign="top" />
        <widget name="hint" position="35,565" size="930,28" font="Regular;18" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Receiver Telemetry")
        self["summary"] = Label("Runtime, memory and filesystem telemetry")
        self["state"] = ScrollLabel("Reading telemetry...")
        self["hint"] = Label("GREEN: Refresh    EXIT: Back")
        self["actions"] = ActionMap(
            ["OkCancelActions", "ColorActions"],
            {"cancel": self.close, "green": self.refresh},
            -2,
        )
        _add_scroll_actions(self, "state")
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


class PluginCategorySelector(Screen):
    skin = """
    <screen name="PluginCategorySelector" position="center,center" size="1000,650" title="Plugin Categories">
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="summary" position="35,62" size="930,30" font="Regular;18" />
        <widget name="menu" position="35,100" size="930,340" itemHeight="44" font="Regular;21" />
        <widget name="details" position="35,455" size="930,82" font="Regular;19" valign="top" />
        <widget name="hint" position="35,565" size="930,30" font="Regular;18" />
    </screen>
    """

    def __init__(self, session, categories, selected, callback):
        Screen.__init__(self, session)
        self["title"] = Label("Plugin Categories")
        self["summary"] = Label("Browse the library by category")
        self["menu"] = DebugMenuList([])
        self["details"] = Label("Select a category.")
        self["hint"] = Label("UP/DOWN: Select    OK: Open    EXIT: Back")
        self.categories = categories or []
        self.callback = callback
        self.items = [{"id": "all", "name": "All Categories", "description": "Show every admitted plugin."}]
        self.items.extend(
            {
                "id": item.get("id"),
                "name": item.get("name") or str(item.get("id", "")).replace("_", " ").title(),
                "description": item.get("description", ""),
            }
            for item in self.categories
            if item.get("id")
        )
        self.selected = selected if any(item["id"] == selected for item in self.items) else "all"
        self["menu"].setList([self._label(item) for item in self.items])
        self["actions"] = DebugActionMap(
            ["OkCancelActions"],
            {"ok": self.activate, "cancel": self._cancel},
            -2,
        )
        self["menu"].onSelectionChanged.append(self._selection_changed)
        self._select_current()

    @staticmethod
    def _label(item):
        return item["name"]

    def _select_current(self):
        index = next((i for i, item in enumerate(self.items) if item["id"] == self.selected), 0)
        self["menu"].setIndex(index)
        self._selection_changed()

    def _selection_changed(self):
        index = self["menu"].getSelectionIndex()
        if index is None or index < 0 or index >= len(self.items):
            return
        item = self.items[index]
        self["summary"].setText("%d category option(s)" % len(self.items))
        self["details"].setText(
            "%s\n%s" % (item["name"], item["description"] or "No category description available.")
        )

    def activate(self):
        index = self["menu"].getSelectionIndex()
        if index is None or index < 0 or index >= len(self.items):
            return
        self.callback(self.items[index]["id"])
        self.close()

    def _cancel(self):
        self.close()


class PluginLibrary(Screen):
    skin = """
    <screen name="PluginLibrary" position="center,center" size="1000,650" title="Enigma2 Plugin Library">
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="summary" position="35,62" size="930,30" font="Regular;18" />
        <widget name="menu" position="35,100" size="930,340" itemHeight="44" font="Regular;21" />
        <widget name="details" position="35,455" size="930,82" font="Regular;19" valign="top" />
        <widget name="key_red" position="35,565" size="175,30" font="Regular;18" foregroundColor="#f24b4b" />
        <widget name="key_green" position="210,565" size="175,30" font="Regular;18" foregroundColor="#4bd66f" />
        <widget name="key_yellow" position="385,565" size="175,30" font="Regular;18" foregroundColor="#f3d45c" />
        <widget name="key_blue" position="560,565" size="175,30" font="Regular;18" foregroundColor="#4da6ff" />
        <widget name="hint" position="735,565" size="230,30" font="Regular;18" halign="right" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Plugin Library")
        self["summary"] = Label("Loading library...")
        self["menu"] = DebugMenuList([])
        self["details"] = Label("Loading plugin library...")
        self["key_red"] = Label("RED: Category")
        self["key_green"] = Label("GREEN: Install")
        self["key_yellow"] = Label("YELLOW: Refresh")
        self["key_blue"] = Label("BLUE: Search")
        self["hint"] = Label("OK: Details  |  EXIT: Back")
        self["actions"] = ActionMap(
            ["OkCancelActions", "ColorActions"],
            {"ok": self.show_details, "cancel": self.close, "green": self.install_selected, "yellow": self.refresh, "blue": self.search, "red": self.open_category_selector},
            -2,
        )
        self.entries = []
        self.filtered_entries = []
        self.categories = []
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

    def open_category_selector(self):
        self.session.openWithCallback(
            self._category_selected,
            PluginCategorySelector,
            self.categories,
            self.category_filter,
        )

    def _category_selected(self, category_id):
        if not category_id:
            return
        self.category_filter = category_id
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
            availability = entry.get("availability", "unknown")
            choices.append(
                "%s  [%s | %s]"
                % (entry.get("name", "unknown"), source, availability)
            )
        self["title"].setText("Plugin Library — %s" % self._category_name())
        self["summary"].setText(
            "%d result(s) | Category: %s%s"
            % (
                len(self.filtered_entries),
                self._category_name(),
                " | Search: %s" % self.search_term if self.search_term else "",
            )
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
                bool(preview.get("requires_reboot") is True),
            ),
            MessageBox,
            summary,
            MessageBox.TYPE_YESNO,
        )

    def _start_library_install(self, confirmed, plugin_id, requires_gui_restart, requires_reboot):
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
            requires_reboot,
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
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="summary" position="35,62" size="930,30" font="Regular;18" />
        <widget name="state" position="35,102" size="930,428" font="Regular;20" valign="top" />
        <widget name="hint" position="35,565" size="930,28" font="Regular;18" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Receiver Compatibility")
        self["summary"] = Label("Fail-closed compatibility evidence")
        self["state"] = ScrollLabel("Detecting device and image...")
        self["hint"] = Label("GREEN: Refresh    EXIT: Back")
        self["actions"] = ActionMap(
            ["OkCancelActions", "ColorActions"],
            {"ok": self.close, "cancel": self.close, "green": self.refresh},
            -2,
        )
        self.onLayoutFinish.append(self.refresh)

        _add_scroll_actions(self, "state")
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
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="summary" position="35,62" size="930,30" font="Regular;18" />
        <widget name="menu" position="35,100" size="930,340" itemHeight="44" font="Regular;21" />
        <widget name="details" position="35,455" size="930,82" font="Regular;18" valign="top" />
        <widget name="key_red" position="35,565" size="175,30" font="Regular;17" foregroundColor="#f24b4b" />
        <widget name="key_green" position="210,565" size="175,30" font="Regular;17" foregroundColor="#4bd66f" />
        <widget name="key_yellow" position="385,565" size="175,30" font="Regular;17" foregroundColor="#f3d45c" />
        <widget name="key_blue" position="560,565" size="175,30" font="Regular;17" foregroundColor="#4da6ff" />
        <widget name="hint" position="735,565" size="230,30" font="Regular;17" halign="right" />
    </screen>
    """

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Package Browser")
        self["summary"] = Label("Receiver-local package manager")
        self["menu"] = DebugMenuList([])
        self["details"] = Label("Loading receiver package inventory...")
        self["key_red"] = Label("RED: Remove")
        self["key_green"] = Label("GREEN: Install/Update")
        self["key_yellow"] = Label("YELLOW: Refresh")
        self["key_blue"] = Label("BLUE: Search")
        self["hint"] = Label("OK: Info  |  EXIT: Back")
        self["actions"] = DebugActionMap(
            ["OkCancelActions", "ColorActions"],
            {
                "ok": self.show_info,
                "cancel": self.close,
                "green": self.install_or_update,
                "red": self.remove_selected,
                "yellow": self.refresh,
                "blue": self.search,
            },
            -2,
        )
        self.entries = []
        self.search_term = ""
        self.onLayoutFinish.append(self.refresh)
        self["menu"].onSelectionChanged.append(self._selection_changed)

    def refresh(self):
        try:
            code, output = run_action("receiver.package_state")
        except Exception as exc:
            self.entries = []
            self["menu"].setList([])
            self["details"].setText("Package state request rejected.\n\n%s" % exc)
            return
        if code != 0:
            self.entries = []
            self["menu"].setList([])
            self["details"].setText("Package state unavailable.\n\n%s" % (output or "unknown"))
            return
        try:
            state = json.loads(output)
        except (TypeError, ValueError):
            self.entries = []
            self["menu"].setList([])
            self["details"].setText("Invalid receiver package-state response.")
            return
        installed = state.get("installed_packages") or []
        available = state.get("available_packages") or []
        installed_map = {item.get("name"): item for item in installed if item.get("name")}
        available_map = {item.get("name"): item for item in available if item.get("name")}
        names = sorted(set(installed_map) | set(available_map), key=lambda x: x.lower())
        self.entries = []
        for name in names:
            ins = installed_map.get(name)
            avail = available_map.get(name)
            if ins and avail:
                status = "installed+available"
                version = avail.get("version") or ins.get("version") or "unknown"
            elif ins:
                status = "installed"
                version = ins.get("version") or "unknown"
            else:
                status = "available"
                version = avail.get("version") or "unknown"
            self.entries.append({
                "name": name,
                "installed": ins is not None,
                "installed_version": (ins or {}).get("version", ""),
                "available_version": version,
                "architecture": (avail or ins or {}).get("architecture", "unknown"),
                "status": status,
            })
        self._apply_filter(state)

    def _filtered(self):
        term = self.search_term.lower().strip()
        if not term:
            return self.entries
        return [entry for entry in self.entries if term in entry["name"].lower()]

    def _apply_filter(self, state=None):
        filtered = self._filtered()
        choices = [
            "%s  [%s | %s]"
            % (entry["name"], entry["status"], entry["available_version"])
            for entry in filtered
        ]
        self["menu"].setList(choices)
        self["summary"].setText(
            "%d package(s) | %s | Search: %s"
            % (
                len(filtered),
                state.get("package_manager", "unknown") if state else "receiver package manager",
                self.search_term or "all",
            )
        )
        self._selection_changed()

    def _selected_entry(self):
        index = self["menu"].getSelectionIndex()
        filtered = self._filtered()
        if index is None or index < 0 or index >= len(filtered):
            return None
        return filtered[index]

    def _selection_changed(self):
        entry = self._selected_entry()
        if not entry:
            self["details"].setText("No package selected.")
            return
        self["details"].setText(
            "Installed: %s (%s)  |  Candidate: %s\nArchitecture: %s | State: %s"
            % (
                entry["installed"],
                entry["installed_version"] or "none",
                entry["available_version"],
                entry["architecture"],
                entry["status"],
            )
        )

    def search(self):
        self.session.openWithCallback(
            self._search_done,
            InputBox,
            title="Search Receiver Packages",
            text=self.search_term,
        )

    def _search_done(self, value):
        if value is None:
            return
        self.search_term = value.strip()
        self._apply_filter()

    def show_info(self):
        entry = self._selected_entry()
        if not entry:
            return
        try:
            code, output = run_action("receiver.package_info", {"package": entry["name"]})
        except ValueError:
            self.session.open(
                ActionResult,
                "Package Information",
                "Package information action is unavailable in this panel release.\n\n"
                "Selected: %s" % entry["name"],
            )
            return
        except Exception as exc:
            self.session.open(MessageBox, "Package information failed: %s" % exc, MessageBox.TYPE_ERROR)
            return
        if code != 0:
            output = "Command failed with exit code %s.\n\n%s" % (code, output)
        self.session.open(ActionResult, "Package Information — %s" % entry["name"], output)

    def install_or_update(self):
        entry = self._selected_entry()
        if not entry:
            return
        if entry["installed"]:
            operation = "update"
            action_id = "package.update"
            message = (
                "Update package: %s\n\nInstalled: %s\nCandidate: %s\n\n"
                "The operation uses only receiver-configured package sources.\n"
                "Continue?"
                % (entry["name"], entry["installed_version"] or "unknown", entry["available_version"])
            )
        else:
            operation = "install"
            action_id = "package.install"
            message = (
                "Install package: %s\n\nCandidate: %s\nArchitecture: %s\n\n"
                "The operation uses only receiver-configured package sources.\n"
                "Continue?"
                % (entry["name"], entry["available_version"], entry["architecture"])
            )
        self.session.openWithCallback(
            lambda confirmed: self._start_package_operation(confirmed, action_id, operation, entry["name"]),
            MessageBox,
            message,
            MessageBox.TYPE_YESNO,
        )

    def remove_selected(self):
        entry = self._selected_entry()
        if not entry or not entry["installed"]:
            self.session.open(MessageBox, "Only installed packages can be removed.", MessageBox.TYPE_ERROR)
            return
        message = (
            "Remove package: %s\n\nInstalled version: %s\n\n"
            "This changes the receiver package state.\n"
            "Continue?"
            % (entry["name"], entry["installed_version"] or "unknown")
        )
        self.session.openWithCallback(
            lambda confirmed: self._start_package_operation(
                confirmed, "package.remove", "remove", entry["name"]
            ),
            MessageBox,
            message,
            MessageBox.TYPE_YESNO,
        )

    def _start_package_operation(self, confirmed, action_id, operation, package):
        if not confirmed:
            return
        try:
            command = build_action_command(action_id, {"package": package})
        except Exception as exc:
            self.session.open(MessageBox, "Package action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        self.session.open(
            PackageInstallProgress,
            package,
            command,
            operation.capitalize(),
            False,
            False,
        )



class PackageInstallProgress(Screen):
    skin = """
    <screen name="PackageInstallProgress" position="center,center" size="1000,650" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,85" size="930,430" font="Regular;20" valign="top" />
        <widget name="hint" position="35,555" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session, plugin_id, command, operation="Installing", requires_gui_restart=False, requires_reboot=False):
        Screen.__init__(self, session)
        self.plugin_id = plugin_id
        self.command = tuple(command)
        self.operation = operation
        self.requires_gui_restart = requires_gui_restart
        self.requires_reboot = requires_reboot
        self.output = ""
        self.finished = False
        self["title"] = Label("%s: %s" % (operation, plugin_id))
        self["state"] = ScrollLabel("Starting native package operation...")
        self["hint"] = Label("Please wait — %s running" % operation.lower())
        self["actions"] = ActionMap(
            ["OkCancelActions"],
            {"ok": self._close_when_finished, "cancel": self._close_when_finished},
            -2,
        )
        _add_scroll_actions(self, "state")
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
            if self.requires_reboot:
                self["hint"].setText("OK / EXIT: Close — receiver reboot required")
                self._offer_reboot()
            elif self.requires_gui_restart:
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

    def _offer_reboot(self):
        self.session.openWithCallback(
            self._reboot_confirmed,
            MessageBox,
            "The %s operation completed successfully.\n\n"
            "Verified plugin metadata requires a receiver reboot.\n"
            "The reboot intent will be persisted and verified after the receiver starts again.\n\n"
            "Reboot now?"
            % self.operation,
            MessageBox.TYPE_YESNO,
        )

    def _reboot_confirmed(self, confirmed):
        if not confirmed:
            self["hint"].setText("OK / EXIT: Close — reboot deferred")
            return
        try:
            command = build_action_command(
                "receiver.reboot_for_plugin",
                {"plugin_id": self.plugin_id},
            )
        except Exception as exc:
            self["hint"].setText("Reboot action rejected: %s" % exc)
            return
        self.session.open(RebootProgress, command, self.plugin_id)

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



class RebootProgress(Screen):
    skin = """
    <screen name="RebootProgress" position="center,center" size="1000,500" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,45" font="Regular;30" />
        <widget name="state" position="35,90" size="930,320" font="Regular;20" valign="top" />
        <widget name="hint" position="35,430" size="930,35" font="Regular;20" />
    </screen>
    """

    def __init__(self, session, command, plugin_id):
        Screen.__init__(self, session)
        self.finished = False
        self.plugin_id = plugin_id
        self["title"] = Label("Rebooting Receiver")
        self["state"] = ScrollLabel(
            "Persisting reboot verification intent...\n\n"
            "The receiver will restart now. Verification will occur the next time "
            "Enigma2 Universal Panel is opened."
        )
        self["hint"] = Label("Please wait — receiver reboot in progress")
        self["actions"] = ActionMap(
            ["OkCancelActions"],
            {"ok": self._close_when_finished, "cancel": self._close_when_finished},
            -2,
        )
        _add_scroll_actions(self, "state")
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
                "Reboot request accepted.\n\n"
                "Verification is pending until the receiver boots again.\n"
                "Open Enigma2 Universal Panel after boot to complete verification."
            )
        else:
            self["state"].setText(
                "Reboot request failed.\n\n"
                "Exit code: %s\n"
                "No successful reboot verification can be claimed."
                % retval
            )
        self["hint"].setText("OK / EXIT: Close")

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
        self["state"] = ScrollLabel("Starting the controlled GUI restart action...")
        self["hint"] = Label("Please wait — Enigma2 may restart this interface")
        self["actions"] = ActionMap(
            ["OkCancelActions"],
            {"ok": self._close_when_finished, "cancel": self._close_when_finished},
            -2,
        )
        _add_scroll_actions(self, "state")
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
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="summary" position="35,62" size="930,30" font="Regular;18" />
        <widget name="state" position="35,102" size="930,428" font="Regular;20" valign="top" />
        <widget name="hint" position="35,565" size="930,28" font="Regular;18" />
    </screen>
    """

    def __init__(self, session, plugin_id):
        Screen.__init__(self, session)
        self.plugin_id = plugin_id
        self["title"] = Label("Plugin Metadata — %s" % plugin_id)
        self["summary"] = Label("Read-only package and compatibility metadata")
        self["state"] = ScrollLabel("Loading metadata...")
        self["hint"] = Label("OK / EXIT: Back")
        self["actions"] = ActionMap(["OkCancelActions"], {"ok": self.close, "cancel": self.close}, -2)
        self.onLayoutFinish.append(self.refresh)

        _add_scroll_actions(self, "state")
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
    <screen name="PanelSectionMenu" position="center,center" size="1000,620" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="subtitle" position="35,62" size="930,30" font="Regular;18" />
        <widget name="menu" position="35,105" size="930,405" itemHeight="48" font="Regular;25" />
        <widget name="hint" position="35,540" size="930,30" font="Regular;18" />
    </screen>
    """

    def __init__(self, session, title, entries, controller):
        Screen.__init__(self, session)
        self["title"] = Label(title.title())
        self["subtitle"] = Label("Select an operation with UP/DOWN, then press OK")
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
    <screen name="Enigma2UniversalPanel" position="center,center" size="1000,620" title="Enigma2 Universal Panel">
        <widget name="title" position="35,20" size="930,42" font="Regular;30" />
        <widget name="subtitle" position="35,62" size="930,30" font="Regular;18" />
        <widget name="menu" position="35,105" size="930,405" itemHeight="48" font="Regular;25" />
        <widget name="hint" position="35,540" size="930,30" font="Regular;18" />
    </screen>
    """

    SECTIONS = (
        ("Store", (
            ("Plugin Library", "plugin.library"),
            ("Community Sources", "community.catalog"),
            ("Install Plugin", "plugin.install"),
            ("Update Plugin", "plugin.update"),
            ("Remove Plugin", "plugin.remove"),
        )),
        ("Receiver", (
            ("Dashboard", "dashboard"),
            ("Compatibility", "receiver.compatibility"),
            ("Reboot Status", "receiver.reboot_status"),
            ("Telemetry", "receiver.telemetry"),
            ("Status", "receiver.status"),
            ("Capabilities", "receiver.capabilities"),
        )),
        ("Management", (
            ("Package Browser", "package-browser"),
            ("Diagnostics", "receiver.diagnose"),
            ("Package State", "receiver.package_state"),
            ("Audit History", "receiver.audit_history"),
            ("Update Panel", "receiver.panel_update"),
            ("Restart GUI", "receiver.restart_gui"),
        )),
        ("Advanced", (
            ("Resolve Plugin", "plugin.resolve"),
            ("Preview Plugin", "plugin.preview"),
            ("Plugin Metadata", "plugin.info"),
        )),
    )

    def __init__(self, session):
        Screen.__init__(self, session)
        self["title"] = Label("Enigma2 Universal Panel")
        self["subtitle"] = Label("Enigma2 Universal Panel v1.8.0 | Native receiver UI | No web dependency")
        self["hint"] = Label("UP/DOWN: Select    OK: Open    EXIT: Back")
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
            lambda confirmed: self._start_update(
                confirmed,
                plugin_id,
                bool(preview.get("requires_gui_restart") is True),
                bool(preview.get("requires_reboot") is True),
            ),
            MessageBox, summary, MessageBox.TYPE_YESNO,
        )

    def _start_update(self, confirmed, plugin_id, requires_gui_restart, requires_reboot):
        if not confirmed:
            return
        try:
            command = build_action_command("plugin.update", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        self.session.open(PackageInstallProgress, plugin_id, command, "Updating", requires_gui_restart, requires_reboot)

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
                confirmed,
                plugin_id,
                bool(preview.get("requires_gui_restart") is True),
                bool(preview.get("requires_reboot") is True),
            ),
            MessageBox,
            summary,
            MessageBox.TYPE_YESNO,
        )

    def _start_remove(self, confirmed, plugin_id, requires_gui_restart, requires_reboot):
        if not confirmed:
            return
        try:
            command = build_action_command("plugin.remove", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        self.session.open(PackageInstallProgress, plugin_id, command, "Removing", requires_gui_restart, requires_reboot)

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
            lambda confirmed: self._start_install(
                confirmed,
                plugin_id,
                bool(preview.get("requires_gui_restart") is True),
                bool(preview.get("requires_reboot") is True),
            ),
            MessageBox,
            summary,
            MessageBox.TYPE_YESNO,
        )

    def _start_install(self, confirmed, plugin_id, requires_gui_restart, requires_reboot):
        if not confirmed:
            return
        try:
            command = build_action_command("plugin.install", {"plugin_id": plugin_id})
        except Exception as exc:
            self.session.open(MessageBox, "Action rejected: %s" % exc, MessageBox.TYPE_ERROR)
            return
        self.session.open(
            PackageInstallProgress,
            plugin_id,
            command,
            "Installing",
            requires_gui_restart,
            requires_reboot,
        )

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

    def _prepare_panel_update(self):
        try:
            code, output = run_action("receiver.panel_update")
        except Exception as exc:
            self.session.open(MessageBox, "Panel update failed.\n\n%s" % exc, MessageBox.TYPE_ERROR)
            return
        if code != 0:
            self.session.open(MessageBox, "Panel update failed.\n\n%s" % (output or "unknown error"), MessageBox.TYPE_ERROR)
            return
        result = {}
        for line in (output or "").splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                result[key] = value
        status = result.get("status", "unknown")
        if status == "refreshed":
            message = "Panel refresh completed.\n\nInstalled version: v%s\nTarget release: v%s\n\nThe official installer redeployed the current panel release. Use Receiver → Restart GUI to activate the refreshed Python modules." % (result.get("previous_version", "unknown"), result.get("target_version", "unknown"))
        elif status == "updated":
            message = "Panel update completed.\n\nPrevious version: v%s\nInstalled version: v%s\n\nUse Receiver → Restart GUI to activate the updated Python modules." % (result.get("previous_version", "unknown"), result.get("target_version", "unknown"))
        elif status == "current":
            message = "The panel is already up to date.\n\nInstalled: %s\nLatest: %s" % (result.get("current_version", "unknown"), result.get("latest_version", "unknown"))
        else:
            message = "Unexpected panel update result.\n\n%s" % (output or "unknown")
        self.session.open(MessageBox, message, MessageBox.TYPE_INFO)

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
        if action_id == "receiver.panel_update":
            summary = ("Update Enigma2 Universal Panel\n\n"
                       "Installed version: v1.8.0\n"
                       "The updater will retrieve the official release version, validate it, "
                       "then perform a transactional update.\n\n"
                       "No arbitrary URL or command is accepted.\n\nContinue?")
            self.session.openWithCallback(
                lambda confirmed: self._prepare_panel_update() if confirmed else None,
                MessageBox, summary, MessageBox.TYPE_YESNO,
            )
            return
        if action_id == "receiver.reboot_status":
            code, output = run_action(action_id)
            if code != 0:
                output = "Command failed with exit code %s.\n\n%s" % (code, output)
            self.session.open(ActionResult, "Reboot Verification", output)
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
