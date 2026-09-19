# Native Enigma2 package/plugin GUI

Phase 1.4 is being delivered incrementally. The first slice is read-only: the receiver plugin can inspect normalized package state and invoke the existing resolver for plugin IDs without introducing a second execution path.

## Current GUI surface

- Package Browser: reads `package-state` from the receiver and displays configured sources plus installed/available package inventory.
- Resolve Plugin: prompts for a normalized plugin ID and calls the registered resolver action.
- Preview Plugin: prompts for a normalized plugin ID and calls the registered, read-only compatibility/dependency preflight.

The GUI does not accept shell commands, feed URLs, package-manager arguments, or arbitrary command parameters. Plugin IDs are validated before they are appended to the fixed `e2panel` command argv.

## Policy boundaries

- Package/plugin binaries are never hosted by this repository.
- Package installation remains receiver-feed driven.
- Arbitrary external feed registration remains disabled.
- Unknown mappings remain blocked by the resolver.
- This slice performs no package mutation and therefore does not bypass confirmation or postcondition policy.
- Installation/update/remove/progress/verification screens remain the next Phase 1.4 slice.

## Acceptance criteria for this slice

1. Native remote-control navigation reaches Package Browser, Resolve Plugin, and Preview Plugin.
2. Package Browser consumes the existing normalized `package-state` schema.
3. Resolve/Preview use registered actions and strict plugin-ID validation.
4. Invalid IDs and unexpected action parameters are rejected before subprocess execution.
5. No GUI path uses `shell=True`, `os.system`, or arbitrary executable/argument input.
6. Mock/CI validation does not claim real-receiver support.
