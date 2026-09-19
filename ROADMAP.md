# Enigma2 Universal Panel — Master Roadmap

Status date: 2026-09-19

## Product definition

Enigma2 Universal Panel is primarily a **native Enigma2 receiver plugin**. The user-facing panel runs directly on the receiver, appears in the normal Enigma2 Plugins/Extensions menu, and is controlled with the receiver remote control.

The project is not a web dashboard with a receiver agent attached to it.

The receiver plugin is the local management application. CLI remains a diagnostic and recovery interface. Optional remote management is a later control-plane capability and must never become a prerequisite for local operation.

## Product architecture

```
Native Enigma2 GUI Plugin
        |
        v
GUI Controller / View Models
        |
        v
Registered Action + Policy Layer
        |
        v
Capability / Compatibility Engine
        |
        v
Receiver Adapters
        |
        +--> Native package manager
        +--> Enigma2 services/configuration
        +--> Channels / bouquets
        +--> Settings
        +--> Backup / restore
        +--> Diagnostics
        |
        v
Receiver
```

The same action registry and policy rules must be usable by the native GUI and CLI. No GUI path may execute an arbitrary shell command.

## Non-negotiable invariants

1. Native receiver GUI is the primary interface.
2. No browser, web server, phone, PC or external control plane is required for normal operation.
3. The plugin must be discoverable through the normal Enigma2 Plugins/Extensions menu.
4. Remote-control navigation must work with standard Enigma2 input semantics.
5. GUI actions use registered actions with validated parameters.
6. Destructive operations require explicit confirmation.
7. Compatibility is fail-closed when evidence is insufficient.
8. Package/plugin binaries are never hosted or mirrored by this repository.
9. Plugin installation uses receiver-configured package sources.
10. Unknown package/plugin mappings are not guessed.
11. Mutating operations verify postconditions and create audit records.
12. Real-receiver validation must be clearly distinguished from mock/harness validation.

## Phase 0 — Evidence and reconstruction baseline

Status: COMPLETE

- Repository structure and receiver bootstrap reconstructed.
- Receiver/image/package-manager detection established.
- Capability and adapter models established.
- Action registry and policy layer established.
- Plugin catalog and compatibility metadata established.
- Source-driven package/plugin installation established.
- Binary-hosting prohibition established.
- Mock receiver harness established.
- Normalized runtime package state established.

## Phase 1 — Native Enigma2 GUI foundation

Status: IN PROGRESS

Goal: make the project a real Enigma2 application that opens and runs on the receiver itself.

### 1.1 Plugin registration

Status: COMPLETE

- Create native Enigma2 plugin package.
- Register through Enigma2 PluginDescriptor.
- Expose the panel in the normal Plugins/Extensions menu.
- Define plugin metadata/version.
- Ensure clean import on supported Python/Enigma2 environments.

Acceptance:
- Plugin package has no web-server dependency.
- Enigma2 can discover and load the plugin.
- Main panel opens from the normal plugin menu.

### 1.2 Native screen framework

Status: COMPLETE

- Main dashboard.
- MenuList-based navigation.
- Action/status screens.
- MessageBox confirmations.
- Progress/result screens.
- Remote-control key handling.
- Safe screen close/back behavior.

Acceptance:
- Entire core navigation is possible with the remote control.
- No browser or SSH session is required.

### 1.3 Receiver dashboard

Status: COMPLETE for the initial read-only dashboard slice.

Expose evidence-backed runtime state:

- receiver/model
- image/version
- architecture
- Enigma2 version
- package manager
- network status
- storage
- uptime/health
- available capabilities

Unknown values must be displayed as unknown, not inferred.

### 1.4 Plugin/package GUI

Status: NEXT

Build native screens over the existing resolver/action layer:

- installed plugins
- available packages
- plugin metadata
- compatibility result
- installation preview
- confirmation
- installation progress
- verification result
- update/remove flows

Acceptance:
- GUI installation uses the same policy gates as CLI.
- Unknown mappings are blocked.
- External arbitrary feeds remain blocked.

## Phase 2 — Core receiver management

Status: PLANNED

- System status
- diagnostics
- services
- restart Enigma2
- restart GUI
- reboot
- storage
- network status
- logs/crashlogs
- package lifecycle
- maintenance operations

Every mutation gets explicit risk classification, confirmation where required, postcondition verification and audit logging.

## Phase 3 — Channels, bouquets and EPG

Status: PLANNED

- tuner discovery
- signal information
- service/channel discovery
- channel scan
- bouquet management
- import/export
- EPG discovery/import/refresh
- recording/timer foundations

No channel or bouquet operation should be exposed unless the receiver capability and adapter support it.

## Phase 4 — Settings and configuration

Status: PLANNED

- settings discovery
- normalized settings model
- safe configuration editing
- validation
- backup before destructive/high-risk changes
- restore
- GUI restart requirements

## Phase 5 — Backup, recovery and maintenance

Status: PLANNED

- backup inventory
- backup creation
- integrity checks
- restore previews
- confirmation gates
- recovery diagnostics
- maintenance jobs

Critical operations must remain fail-closed and explicitly confirmed.

## Phase 6 — Automation and local jobs

Status: PLANNED

- scheduled maintenance
- package/update checks
- health checks
- backup scheduling
- job history
- job cancellation where safe
- audit trail

Local automation must not bypass action policy.

## Phase 7 — Optional remote management

Status: FUTURE

Remote management is an extension, not the product foundation.

Possible transports:

- SSH
- receiver-side API/agent
- controlled remote jobs

The remote layer must call the same registered actions and policy engine. It must never create a second unrestricted execution path.

## Phase 8 — Optional web/fleet control plane

Status: FUTURE

Only after the native receiver application is mature:

- multi-receiver inventory
- remote job management
- fleet health
- centralized audit
- controlled updates
- optional web dashboard

The web layer must never be required to open or operate the local panel.

## Phase 9 — Controlled module/update ecosystem

Status: FUTURE

- signed metadata
- verified update channels
- compatibility manifests
- checksums/signatures
- controlled module installation

Repository binary-hosting policy remains unchanged.

## Current execution order

1. Native Enigma2 plugin package and registration.
2. Native screen/navigation framework.
3. Dashboard backed by existing detection/capability functions.
4. Plugin/package screens backed by existing resolver/actions.
5. Native GUI test/harness coverage.
6. Receiver-side real-device validation.
7. Core management screens.
8. Channels/bouquets/EPG.
9. Settings and backup/recovery.
10. Local automation.
11. Optional remote control plane.
12. Optional web/fleet layer.

## Definition of done for the native GUI milestone

The milestone is not complete until a supported Enigma2 receiver can:

1. install the panel;
2. see it in the normal Plugins/Extensions menu;
3. open it with the remote control;
4. navigate the dashboard without a browser;
5. inspect receiver capabilities;
6. inspect installed/available packages;
7. preview a supported plugin installation;
8. confirm the operation;
9. perform the native package operation;
10. verify the postcondition;
11. show a clear success/failure result;
12. leave an audit record.

Mock tests are necessary but do not constitute real-receiver validation.
