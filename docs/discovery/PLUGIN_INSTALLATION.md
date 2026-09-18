# Source-Driven Plugin Management

The Universal Panel is a control plane, not a plugin mirror.

The repository contains plugin metadata, compatibility rules and source references only. It MUST NOT vendor, mirror or redistribute Enigma2 plugin binaries.

Installation occurs on the receiver through the package manager and feeds configured for that receiver/image. OpenATV documents that its plugin browser consumes the package feed for the installed image and that the package feed must match the installed image.

## Runtime model

1. Detect image, architecture and package manager.
2. Detect the receiver's configured feed(s).
3. Refresh package indexes.
4. Discover packages from those indexes.
5. Resolve a normalized plugin ID to a package name when evidence exists.
6. Validate compatibility/dependencies.
7. Install/update/remove through the native package manager.
8. Verify installed state.
9. Record an audit event.
10. Request GUI restart/reboot only when package metadata or the adapter requires it.

The panel never accepts a browser-provided shell command and never downloads an arbitrary plugin archive.

## CLI

- `e2panel plugin-source-status`
- `e2panel plugin-refresh`
- `e2panel plugin-list [pattern]`
- `e2panel plugin-info <package>`
- `e2panel plugin-install <package>`
- `e2panel plugin-update <package>`
- `e2panel plugin-remove <package>`

External feed registration is intentionally disabled until a source has been reviewed and added to the adapter/source registry.

OE-Alliance and OpenVision maintain third-party feed ecosystems. Those are referenced as sources; their binaries are not copied into this repository.

For packages distributed as standalone releases rather than native feeds, a future source adapter can support verified release artifacts. It must verify image/architecture compatibility and checksums before installation. The repository will still not host the binary.