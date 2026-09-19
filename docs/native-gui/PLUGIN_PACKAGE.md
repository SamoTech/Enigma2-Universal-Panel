# Native Enigma2 Plugin Package

The first GUI milestone is implemented as a native Enigma2 Python plugin under:

    Plugins/Extensions/Enigma2UniversalPanel/

The entry point uses Enigma2's PluginDescriptor with WHERE_PLUGINMENU, so the panel is registered in the normal Plugins/Extensions menu. This registration pattern is consistent with current Enigma2 plugin implementations.

## Current scope

This slice provides:

- native plugin registration;
- a native Screen-based main panel;
- MenuList navigation;
- OK/EXIT remote-control interaction;
- fixed registered read-only receiver actions;
- result/error screens;
- no web server;
- no arbitrary shell input.

The next GUI slice will connect the dashboard to normalized receiver/package state and then add plugin/package preview screens.

## Installation path

The installer targets the standard Enigma2 plugin tree:

    /usr/lib/enigma2/python/Plugins/Extensions/Enigma2UniversalPanel

The installer must fail rather than silently placing the plugin in an unknown runtime path.
