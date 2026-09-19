# Installation Guide

The final product is a native Enigma2 GUI plugin. Installation therefore has two layers:

1. bootstrap the receiver-side runtime;
2. install/register the native Enigma2 plugin package.

## Prerequisites

- Enigma2 receiver running a supported Linux image
- Network access for bootstrap/package discovery
- SSH or Telnet access for the current bootstrap path
- root privileges

## Current bootstrap

    wget -O - https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh

or:

    curl -fsSL https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh

The bootstrap currently establishes the receiver-side runtime and management shell. It is not yet the final native GUI installation mechanism.

## Native GUI milestone

The native GUI implementation must install a standard Enigma2 plugin under the receiver's plugin path and register it with Enigma2 so that it appears in the normal Plugins/Extensions menu.

The completed installation experience should be:

Install panel
   |
   v
Enigma2 plugin registered
   |
   v
Plugins / Extensions
   |
   v
Enigma2 Universal Panel
   |
   v
Native remote-control GUI

No web server is required.

## Validation after installation

The release acceptance test must verify:

- plugin registration;
- appearance in the normal Plugins/Extensions menu;
- successful launch;
- remote-control navigation;
- dashboard loading;
- capability display;
- package/plugin discovery;
- preview and confirmation flow;
- postcondition verification.

A mock harness is not a substitute for testing on a real Enigma2 receiver.
