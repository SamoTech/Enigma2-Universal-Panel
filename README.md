# Enigma2 Universal Panel

A Universal Management Layer for Enigma2 receivers.

The project is designed as a control plane, not as a collection of unrelated shell scripts. It detects the receiver and image, normalizes capabilities, selects the correct adapter, and exposes safe operations for plugins, bouquets, settings, maintenance, backups, diagnostics, and remote management.

## Architecture

```
Web / CLI Control Plane
        |
        v
Action + Policy Layer
        |
        v
Capability / Compatibility Engine
        |
        +--> OpenATV adapter
        +--> OpenVIX adapter
        +--> OpenPLi adapter
        +--> DreamOS adapter
        +--> Generic Enigma2 adapter
        |
        v
Receiver Agent / SSH Transport
        |
        v
Enigma2 receiver
```

The web control plane must never expose arbitrary shell execution. Operations are declared actions with capability requirements, previews, validation, audit records, and rollback metadata where practical.

## Current reconstruction

- POSIX/BusyBox-safe receiver bootstrap
- Structured receiver fingerprint
- Image and package-manager detection
- Capability model
- Adapter registry
- Safe operation dispatcher
- Plugin catalog schema
- Receiver profile schema
- Backup/restore foundations
- Maintenance and diagnostics commands
- Audit log foundation
- Remote-management architecture documented for the next layer

## Supported target families

DreamOS, OpenATV, OpenVIX, OpenPLi and other Enigma2-based Linux images. Compatibility is capability-driven; an unknown image falls back to the generic adapter rather than being incorrectly classified.

## Install

Run as root on the receiver:

```sh
wget -O - https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh
```

After installation:

```sh
/usr/local/bin/e2panel status
/usr/local/bin/e2panel capabilities
/usr/local/bin/e2panel diagnose
/usr/local/bin/e2panel menu
```

## Design principles

1. Detect before acting.
2. Declare capabilities before exposing operations.
3. Prefer adapters over image-specific conditionals scattered across scripts.
4. Never expose unrestricted browser-to-shell execution.
5. Make destructive operations explicit and auditable.
6. Keep receiver-side code POSIX/BusyBox compatible where possible.
7. Separate the receiver agent from the web control plane.
8. Fail closed when compatibility is unknown.

## Roadmap

Phase 1: receiver core and compatibility layer.
Phase 2: plugin/channel/settings modules.
Phase 3: receiver-side API/agent.
Phase 4: SSH multi-receiver control plane.
Phase 5: web dashboard, jobs, audit and fleet management.
Phase 6: signed module repository and controlled update channel.
