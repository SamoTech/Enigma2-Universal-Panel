# Source-Driven Plugin Management

The Universal Panel is a control plane, not a plugin mirror.

The repository contains plugin metadata, compatibility rules and source references only. It MUST NOT vendor, mirror or redistribute Enigma2 plugin binaries.

Installation occurs on the receiver through the package manager and feeds configured for that receiver/image.

## Runtime model

1. Detect image, architecture and package manager.
2. Detect the receiver's configured feed(s).
3. Refresh package indexes.
4. Discover packages from those indexes.
5. Resolve a normalized plugin ID to a package name only when authoritative evidence exists.
6. Validate image, architecture, dependency and conflict compatibility.
7. Install/update/remove through the native package manager.
8. Verify installed state and required postconditions.
9. Record an audit event for normalized-ID installation.
10. Request GUI restart/reboot only when package metadata or the adapter requires it.

The panel never accepts a browser-provided shell command and never downloads an arbitrary plugin archive.

## CLI

- e2panel plugin-source-status
- e2panel plugin-refresh
- e2panel plugin-list [pattern]
- e2panel plugin-info <package>
- e2panel plugin-resolve <plugin-id>
- e2panel plugin-preview <plugin-id>
- e2panel plugin-install-id <plugin-id>

External feed registration is intentionally disabled. Source metadata may document reviewed ecosystems, but runtime installation remains bound to receiver-configured package sources.

Standalone release artifacts may be supported by a future reviewed source adapter. Such an adapter must verify image/architecture compatibility and checksums before installation. The repository still must not host the binary.
