# Real Receiver Validation — VU+ Uno 4K SE / OpenATV 8

Status: **PENDING — physical receiver test not yet performed**

This runbook defines the evidence required to move the native GUI milestone from CI/harness evidence to a real-receiver validation record. It does not imply that the target combination is certified before the test is actually executed.

## Target test profile

- Device: VU+ Uno 4K SE
- Image family: OpenATV 8
- Validation scope: native Enigma2 Plugin Library / Store and supporting receiver management paths
- Control surface: receiver remote control and native Enigma2 GUI only
- External browser/web/SSH/PC dependency: not allowed for the acceptance flow

## Evidence rules

Record observed values exactly as reported by the receiver. Do not infer model, image, architecture, Python runtime, package backend, package versions, or plugin compatibility.

Use `unknown` when a value cannot be established from receiver evidence.

CI and mock-harness results are supporting evidence only. They do not satisfy physical validation.

## Preflight evidence

Capture the native Receiver Compatibility / Dashboard evidence for:

- model and device family
- image family and version
- CPU architecture
- Python major/version when exposed
- package backend
- detected capabilities
- panel/runtime version
- network state
- available storage

Expected outcome: runtime identity is internally consistent and the compatibility layer does not claim unsupported evidence as supported.

## Native GUI acceptance flow

1. Open the panel from the normal Enigma2 Plugins/Extensions menu.
2. Navigate the top-level sections with the remote control.
3. Open Plugin Library.
4. Browse categories.
5. Search for a known catalog entry.
6. Open plugin details.
7. Inspect compatibility evidence.
8. Confirm that unsupported/unknown compatibility is visibly blocked.
9. For a receiver-feed plugin with verified `status=supported`, open the installation preview.
10. Verify package, candidate version, architecture/image compatibility, dependency state, and restart/reboot metadata shown by the preview.
11. Cancel one confirmation to verify that cancellation causes no mutation.
12. Perform one approved install only if the receiver itself supplies the package candidate through its configured source and the preview is supported.
13. Verify the package postcondition after installation.
14. Verify the audit record.
15. If verified metadata requires GUI restart, confirm the native restart prompt and verify the panel returns normally.
16. If verified metadata requires reboot, confirm the native reboot prompt and verify post-boot package state and reboot verification.
17. Test update/remove only when the catalog and receiver evidence make those operations supported.
18. Open Audit History and verify the recent mutation records are visible.

## Safety checks

The physical test must confirm that:

- community metadata-only entries remain blocked;
- arbitrary feed URLs are not accepted by the Store;
- arbitrary shell commands are not exposed by GUI screens;
- invalid plugin IDs are rejected;
- destructive operations require explicit confirmation;
- unknown compatibility remains fail-closed;
- failed operations do not produce false success state;
- postconditions are checked before an operation is reported successful.

Do not install an unverified community installer merely to obtain a test result.

## Required result record

For each tested operation record:

- timestamp
- receiver model as observed
- image/version as observed
- architecture as observed
- package backend as observed
- plugin ID
- operation
- preview status
- observed candidate/installed version, if available
- confirmation result
- execution result
- postcondition result
- audit record result
- GUI restart result, if applicable
- reboot verification result, if applicable
- failure output, if any

Do not redact or replace an unknown value with a guessed value.

## Certification boundary

A successful test of VU+ Uno 4K SE + OpenATV 8 establishes evidence for that tested receiver/image combination and the operations actually exercised. It does **not** certify every VU+ model, every OpenATV 8 release, or the wider Enigma2 ecosystem.

Until this runbook is executed on the physical receiver, the repository status remains **physical validation pending**.
