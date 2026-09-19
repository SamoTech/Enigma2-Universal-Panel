# Enigma2 Universal Panel

A native **Enigma2 Plugin Library / Store** and receiver management application. The primary user experience is discovering, inspecting, and installing Enigma2 plugins directly from the receiver, with diagnostics and management capabilities supporting that library.

The panel runs directly on the receiver, appears in the normal Enigma2 Plugins/Extensions menu, and is controlled with the receiver remote control. A browser, web server, phone, PC, SSH session or external control plane is not required for normal operation.

## Architecture

Enigma2 Universal Panel — native Enigma2 GUI
        |
        +--> Plugin Library / Store
        |       +--> receiver-feed catalog
        |       +--> community catalog
        |       +--> search / categories / details
        |       +--> compatibility / install preview
        |
        v
GUI Controller Layer
        |
        v
Registered Actions
        |
        v
Policy + Validation
        |
        v
Capability / Compatibility
        |
        v
Receiver Adapters
        |
        +--> package manager
        +--> Enigma2 services/config
        +--> channels/bouquets
        +--> settings
        +--> backup/restore
        +--> diagnostics

The existing shell/CLI runtime remains a receiver-side foundation and diagnostic/recovery interface. Optional remote and web control planes are future extensions and must use the same registered-action security boundary.

## Current reconstruction

- POSIX/BusyBox-safe receiver bootstrap
- Structured receiver fingerprint
- Image and package-manager detection
- Capability and compatibility model
- Adapter registry
- Registered action/policy dispatcher
- Plugin Library / Store catalog and source metadata
- Source-driven receiver package/plugin management
- Normalized runtime package state
- Evidence-backed receiver telemetry
- Community installer source registry with fail-closed admission and source-health metadata
- Postcondition verification and audit foundations
- Confirmed asynchronous install, update and removal flows
- Mock receiver harness and policy tests
- Master native-GUI roadmap

## Native Plugin Library / Store target

The installed plugin will provide a store-like library as its primary screen:

- Plugin Library / Store
- Search
- Categories
- Plugin details
- Compatibility and availability state
- Install from receiver-configured feeds
- Installed / update state
- Community source discovery with explicit blocked/admitted state

Receiver information, diagnostics, packages, channels, settings, maintenance, and recovery remain supporting management areas.

## Native management areas

The installed plugin will also provide:

- Dashboard
- Receiver information and capabilities
- Packages
- Sources/feeds
- Channels and bouquets
- EPG
- Settings
- Maintenance
- Diagnostics
- Backup/recovery
- System operations

Navigation uses native Enigma2 screens and standard remote-control keys.

The GUI must never execute arbitrary shell commands. GUI operations are registered actions with parameter validation, compatibility checks, confirmation gates where required, postcondition verification and audit logging.

## Installation

Run the bootstrap installer as root on the receiver:

    wget -O - https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh

The current bootstrap installs the receiver-side runtime and native GUI. The plugin/package manager uses receiver-configured sources. Community third-party installer sources are cataloged separately and remain blocked until explicitly admitted after source and secondary-payload review. Real-receiver validation remains outstanding.

## Design principles

1. Native receiver GUI first.
2. Detect before acting.
3. Declare capabilities before exposing operations.
4. Prefer adapters over image-specific conditionals.
5. Never expose unrestricted shell execution.
6. Make destructive operations explicit and auditable.
7. Keep receiver-side code compatible with constrained Enigma2 environments.
8. Keep remote/web control optional.
9. Fail closed when compatibility is unknown.
10. Never host or mirror plugin/package binaries.
11. Never guess package/plugin compatibility.

## Roadmap

The authoritative roadmap is ROADMAP.md.

The immediate product milestone is the native Enigma2 Plugin Library / Store: registration, store navigation, catalog/search/categories, plugin details, compatibility preview, and controlled installation through the existing action/policy/resolver layers.

Remote management and web/fleet management are later phases, not prerequisites for the receiver application.
