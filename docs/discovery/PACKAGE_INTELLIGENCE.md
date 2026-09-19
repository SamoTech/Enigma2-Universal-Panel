# Package & Source Intelligence

The Universal Panel treats the receiver as the installation authority. The repository does not host, mirror, or redistribute plugin/package binaries.

The native Enigma2 GUI is the primary consumer of this runtime intelligence. CLI and future remote clients use the same underlying data and policy.

## Runtime flow

SEARCH -> DISCOVER -> COMPATIBILITY -> DEPENDENCIES -> PREVIEW -> CONFIRM -> INSTALL -> VERIFY -> AUDIT

## Source discovery

The agent inspects native image feed information, /proc/getFeedsUrl when present, existing /etc/opkg/*.conf files for opkg, apt source files for apt-based systems, and existing ipkg configuration where applicable.

Arbitrary feed registration is disabled. A source becomes installable only when it is already configured by the image or has been explicitly admitted to the repository source registry after compatibility and security review.

## Package inventory

Runtime state includes image, architecture, package manager, network state, configured feeds, installed packages, available packages, upgrade candidates, dependency status, and conflicts.

The inventory is generated on the receiver and is not committed into the repository.

The native GUI must present unknown or unavailable fields explicitly rather than filling them with guessed values.

## Normalization

Native package names and versions are preserved. A normalized plugin identifier may map to a native package name only when evidence establishes the mapping. Unknown mappings remain unknown; the engine must never guess.

For installation preflight, an explicit native package architecture of all or an exact match to the detected receiver architecture is accepted. An explicit mismatch is rejected. Missing or unknown native package architecture remains unknown and blocks installation rather than being guessed compatible.

## Safety

Package mutations require a supported package manager, root privileges, a valid package identifier, a receiver-configured source, compatibility checks where metadata exists, post-install verification, and audit logging. Removal is destructive and requires explicit confirmation.

The GUI must use the same preflight and postcondition rules as the CLI.

## Binary policy

.ipk, .deb, plugin archives, and other executable payloads are not stored in this repository. Source metadata, schemas, compatibility rules, and documentation are allowed.

## Evidence levels

- native: reported by the receiver/image
- configured: present in receiver configuration
- catalog: repository metadata
- inferred: derived from multiple signals
- unknown: insufficient evidence

Inferred and unknown values must never be treated as authoritative installation facts.
