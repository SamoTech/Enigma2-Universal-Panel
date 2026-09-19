# Source-Driven Plugin Management

The Universal Panel is a native Enigma2 **Plugin Library / Store** with receiver-management capabilities. It is not a plugin mirror.

The repository contains plugin metadata, compatibility rules and source references only. It MUST NOT vendor, mirror or redistribute Enigma2 plugin binaries.

## Plugin Library / Store flow

The primary user journey is browse → inspect → compatibility preview → confirm → install → verify. The store combines receiver-feed plugin metadata with a separate community-source registry while keeping execution policy distinct.

## Native GUI installation flow

1. Detect image, architecture and package manager.
2. Detect receiver-configured feed(s).
3. Discover package candidates.
4. Resolve normalized plugin ID to a native package name when evidence exists.
5. Validate image/architecture compatibility.
6. Validate dependencies/conflicts where reliable evidence exists.
7. Show a read-only installation preview.
8. Ask for confirmation.
9. Install through the receiver's native package manager.
10. Verify the postcondition.
11. Record an audit event.
12. Request GUI/Enigma2 restart only when required by verified metadata or adapter behavior.

The CLI uses the same underlying resolver/action policy.

## GUI behavior

The native GUI must not:

- execute arbitrary shell commands;
- accept arbitrary plugin archive URLs;
- register arbitrary external feeds;
- bypass compatibility checks;
- guess unknown package mappings.

It should show clear states such as:

- Supported
- Unsupported
- Unknown
- Partial / requires receiver evidence

Unknown is not treated as compatible.

## Sources

Installation uses feeds already configured by the receiver/image. Arbitrary feed registration remains disabled until a source is reviewed and explicitly admitted to the source registry.

The repository never becomes a binary package host.

## CLI compatibility

The current CLI operations remain useful for diagnostics/recovery:

- e2panel plugin-source-status
- e2panel plugin-refresh
- e2panel plugin-list [pattern]
- e2panel plugin-info <package>
- e2panel plugin-preview <plugin-id>
- e2panel plugin-install <package>
- e2panel plugin-update <package>
- e2panel plugin-remove <package> --confirm
- e2panel plugin-install-id <plugin-id>

The native GUI is the primary user interface; CLI is secondary.


## Community installer registry

The project also recognizes a separate class of third-party Enigma2 software distributed through direct installer scripts rather than receiver-configured package feeds. These sources are cataloged in `plugins/community.json`. The registry currently tracks 49 unique community-library entries: 21 previously audited sources plus 28 additional items from the expanded community inventory. New entries are added as verified install sources only when current evidence exists; other entries may be retained as metadata-only provenance, while repeated entries are ignored.

This registry is deliberately separate from the normal package-feed catalog:

- The repository stores metadata and provenance only; it never mirrors third-party binaries.
- Community installer URLs are not arbitrary user input. Each executable source must be explicitly admitted to the registry.
- The native GUI never executes a user-supplied shell pipeline.
- TLS certificate verification is required.
- Installer execution is blocked by default until the source and secondary payloads have been reviewed and explicitly admitted.
- A pinned installer script alone is not considered sufficient when that script fetches mutable package archives, native libraries, or other secondary payloads.
- Entries whose current repository or installer cannot be established are retained as provenance records and remain blocked.

The native GUI exposes the registry as **Community Installers** so an administrator can inspect the developer, repository, pinned source reference, delivery method, and current execution status before any future installation action is admitted.


## Community source health

The community registry now records source-health metadata independently from installation admission. Hosting type, repository reachability, installer endpoint evidence, and maintenance evidence are tracked separately.

A repository being reachable does not imply that a raw installer endpoint is reachable. A web/API cache miss is not treated as proof that an external host is down. Legacy HTTP/DynDNS sources remain blocked unless their current endpoint can be established.

The native **Community Installers** screen exposes these health fields before any future execution workflow.
