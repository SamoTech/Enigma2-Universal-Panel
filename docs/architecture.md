# Architecture

## Product boundary

The primary product is a **native Enigma2 plugin**.

It runs inside the Enigma2 receiver environment, is registered through the normal Enigma2 plugin system, appears in the Plugins/Extensions menu, and uses native Enigma2 GUI screens controlled by the receiver remote.

A web UI is not the primary interface and is not a runtime dependency.

## Runtime layers

Native Enigma2 GUI Plugin
        |
        v
GUI Controllers / View Models
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
        +--> Package manager
        +--> Enigma2 configuration/services
        +--> Channels / bouquets / EPG
        +--> Settings
        +--> Backup / restore
        +--> Diagnostics

The existing POSIX shell runtime remains useful for bootstrap, low-level receiver operations, CLI diagnostics and recovery. It is not a replacement for the native GUI.

## GUI contract

The GUI must:

- use native Enigma2 Screen/List/Config/MessageBox mechanisms;
- support standard remote-control navigation;
- expose only registered capabilities/actions;
- validate all parameters before mutation;
- require confirmation for destructive operations;
- display preflight results before risky mutations;
- display postcondition verification;
- surface unknown/unsupported capabilities explicitly;
- never execute arbitrary command strings.

The GUI should call shared action/controller functions rather than duplicate package or compatibility logic.

## Detection and compatibility

The common detection pipeline remains:

boot -> root check -> OS/image detection -> Enigma2 detection -> architecture -> package manager -> storage/network -> capabilities -> adapter selection.

Detection produces normalized state. GUI screens consume that state rather than implementing independent detection.

An operation is unavailable when its required capability is absent or compatibility evidence is insufficient.

## Package/plugin path

GUI
 -> plugin/package discovery
 -> compatibility
 -> dependency/conflict checks
 -> preview
 -> confirmation
 -> native package manager
 -> postcondition verification
 -> audit

The receiver remains the installation authority. The repository contains metadata and policy, never plugin/package binaries.

## Optional remote control plane

Remote management is a separate future layer:

Remote client
     |
 SSH / receiver API
     |
Registered Actions
     |
same policy + compatibility engine
     |
native receiver operations

The remote layer must not introduce arbitrary shell execution or bypass the native action policy.

## Optional web/fleet layer

A web dashboard may eventually provide multi-receiver inventory, jobs and centralized audit. It is an optional management surface after the receiver-side product is mature.

It must never be required to open or operate the local panel.

## Authoritative planning

See ROADMAP.md for the execution order and acceptance criteria.
