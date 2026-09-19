# Source-Driven Plugin Management

The Universal Panel is a native Enigma2 management application and control plane, not a plugin mirror.

The repository contains plugin metadata, compatibility rules and source references only. It MUST NOT vendor, mirror or redistribute Enigma2 plugin binaries.

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
