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
- Runtime-first device, image-family, CPU architecture and package-backend detection
- Capability and compatibility model with explicit support tiers
- First-class Dreambox / DreamOS compatibility path
- Adapter registry
- Registered action/policy dispatcher
- Plugin Library / Store catalog and source metadata
- Source-driven receiver package/plugin management
- Normalized runtime package state
- Evidence-backed receiver telemetry
- Community Plugin Library with fail-closed installation admission and source-health metadata (49 community entries)
- Postcondition verification and audit foundations
- Read-only native audit-history display backed by the receiver audit log
- Verified metadata-driven GUI restart handling with explicit confirmation
- Persistent post-boot reboot verification for metadata-required reboots
- Confirmed asynchronous install, update and removal flows
- Read-only receiver validation evidence snapshot for physical-test preflight
- Mock receiver harness and policy tests
- Master native-GUI roadmap

## Native Plugin Library / Store target

The installed plugin is organized into four native top-level sections:

- STORE — Plugin Library, Community Sources, Install/Update/Remove
- RECEIVER — Dashboard, Compatibility, Telemetry, Status, Capabilities
- MANAGEMENT — Packages and Diagnostics
- ADVANCED — Resolver, Preview and Metadata

The Store remains the primary user journey. The installed plugin will provide a store-like library as its primary screen:

- Plugin Library / Store
- Store categories: System, Network, Remote Access, Media & Streaming, EPG, Channels & Bouquets, Recording & Timeshift, Skins & Display, Language & Subtitles, Audio, Multiboot & Recovery, Monitoring & Diagnostics, Security & Access, Religious & Community, Utilities
- Search
- Plugin details
- Compatibility and availability state
- Install from receiver-configured feeds
- Installed / update state
- Community source discovery with explicit blocked/admitted state
- Read-only audit history for completed mutating actions

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
- Audit history

Navigation uses native Enigma2 screens and standard remote-control keys.

The GUI must never execute arbitrary shell commands. GUI operations are registered actions with parameter validation, compatibility checks, confirmation gates where required, postcondition verification and audit logging.

## Installation

Run the bootstrap installer as root on the receiver:

    wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh

For a download-and-validate-only preflight:

    wget -qO- https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh -s -- --check

After installation, the read-only receiver evidence command is:

    e2panel validation-snapshot

It prints live receiver status, capabilities, compatibility, telemetry and reboot-verification evidence and explicitly ends with `physical_validation=not_claimed`. It is an evidence collection aid, not a hardware certification mechanism.

The current bootstrap installs the receiver-side runtime and native GUI. The runtime separates receiver device identity from image identity and detects the package backend before exposing package operations. Dreambox/DreamOS is a first-class compatibility path. The plugin/package manager uses receiver-configured sources. Community third-party installer sources are cataloged separately and remain blocked until explicitly admitted after source and secondary-payload review. Real-receiver validation remains outstanding.

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

The immediate product milestone is the native Enigma2 Plugin Library / Store: registration, categorized store navigation, catalog/search, plugin details, receiver compatibility inspection, compatibility preview, and controlled installation through the existing action/policy/resolver layers.

Remote management and web/fleet management are later phases, not prerequisites for the receiver application.


## Universal device and image support

The panel uses a runtime-first compatibility model rather than maintaining a hard-coded list of “supported boxes”. Device identity and image identity are detected separately because the same receiver can run different Enigma2 images.

The runtime currently recognizes major Enigma2 image families including OE-Alliance-derived images, OpenPLi, DreamOS/Dreambox-oriented Debian images, VTi and several community image families, then falls back to generic Enigma2 when the runtime is valid but the image identity is unknown.

Device-family detection includes Dreambox/Dream Multimedia, VU+, GigaBlue, Zgemma, Octagon, Edision, Mutant, Amiko, Formuler, AB-COM, Axas, Golden Interstar, Maxytec, Qviart, Uclan, Xsarius, Xtrend, SAB, Miraclebox and WeTek, with a generic Enigma2 fallback for otherwise unidentified receivers.

Dreambox is treated as a first-class device family. DreamOS environments use a Debian-style package model in the compatibility layer, while OE-family images keep their native `opkg` path. Package installation is never enabled solely because a model or image name is recognized; the live receiver backend, package candidate, architecture, dependency/conflict state and image policy must all pass.

See `docs/compatibility/PLATFORM_MATRIX.md` for the compatibility contract and support tiers.

Compatibility states are intentionally conservative: runtime detection, generic-compatible, image/device detected, operation-supported and physical-validated are distinct states. The project currently has no physical receiver validation record, so CI/harness evidence must not be presented as hardware certification.
