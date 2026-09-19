from Plugins.Plugin import PluginDescriptor
from .screens import Enigma2UniversalPanel

PLUGIN_NAME = "Enigma2 Universal Panel"
PLUGIN_DESCRIPTION = "Native receiver management panel"
PLUGIN_VERSION = "0.1.0"


def main(session, **kwargs):
    session.open(Enigma2UniversalPanel)


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
    ]
