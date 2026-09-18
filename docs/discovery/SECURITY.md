# Security Review

The control plane has privileged access to receivers. A compromised control plane, credential, plugin feed or receiver agent can become a privileged remote execution path.

Mandatory controls: action IDs instead of arbitrary shell, strict parameter schemas, authentication/authorization, least privilege, SSH keys, command allowlists, compatibility checks, preflight/dry-run, explicit destructive confirmation, audit logging, request IDs, operation IDs, timeouts, output limits, rollback where practical, fail-closed unknown capability, secure credential storage, signed/verified module metadata and no secrets in logs.

CRITICAL: image flashing, factory reset, destructive restore, arbitrary privileged execution.
HIGH: package removal, network changes, tuner changes, configuration restore.
MEDIUM: plugin install/update, GUI restart, service restart.
LOW: read-only diagnostics/status.

A plugin package is executable code. Repository existence is not a trust decision. The future catalog needs source provenance, signature/checksum metadata where available, license, dependency graph, architecture, image compatibility and lifecycle state.
