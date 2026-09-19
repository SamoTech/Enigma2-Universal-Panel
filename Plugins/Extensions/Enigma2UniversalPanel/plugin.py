from Plugins.Plugin import PluginDescriptor
from .screens import Enigma2UniversalPanel
from .audit_history import AuditHistory
from .version import PLUGIN_NAME, PLUGIN_DESCRIPTION, PANEL_VERSION

PLUGIN_VERSION = PANEL_VERSION


def main(session, **kwargs):
    session.open(Enigma2UniversalPanel)


def audit_history(session, **kwargs):
    session.open(AuditHistory)


def Plugins(**kwargs):
    return [
        PluginDescriptor(
            name=PLUGIN_NAME,
            description=PLUGIN_DESCRIPTION,
            where=PluginDescriptor.WHERE_PLUGINMENU,
            fnc=main,
        ),
        PluginDescriptor(
            name=PLUGIN_NAME,
            description=PLUGIN_DESCRIPTION,
            where=PluginDescriptor.WHERE_EXTENSIONSMENU,
            fnc=main,
        ),
        PluginDescriptor(
            name="Audit History",
            description="Read-only receiver action audit history",
            where=PluginDescriptor.WHERE_EXTENSIONSMENU,
            fnc=audit_history,
        ),
    ]
