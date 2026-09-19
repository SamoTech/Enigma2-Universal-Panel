# Native Enigma2 package/plugin GUI

Phase 1.4 is being delivered incrementally. The current slice adds a confirmed, asynchronous native package-install path on top of the existing resolver and action policy boundary.

## Current GUI surface

- Package Browser: reads `package-state` from the receiver and displays configured sources plus installed/available package inventory.
- Resolve Plugin: prompts for a normalized plugin ID and calls the registered resolver action.
- Preview Plugin: prompts for a normalized plugin ID and calls the registered, read-only compatibility/dependency preflight.
- Install Plugin: performs the same preflight, requires explicit confirmation, then executes the registered high-risk install action asynchronously through Enigma2's native console container.

The GUI does not accept shell commands, feed URLs, package-manager arguments, or arbitrary command parameters. Plugin IDs are validated before they are appended to the fixed `e2panel` command argv.

## Policy boundaries

- Package/plugin binaries are never hosted by this repository.
- Package installation remains receiver-feed driven.
- Arbitrary external feed registration remains disabled.
- Unknown mappings remain blocked by the resolver.
- Installation is source-driven through the receiver's configured package manager.
- The GUI never accepts a package-manager command, feed URL, executable path, or arbitrary argv.
- Confirmation is required before the high-risk install action.
- The receiver-side install action performs post-install verification and writes an audit record.
- A successful asynchronous action is therefore only reported as complete when the receiver action returns success.
- Update/remove flows remain separate and are not exposed by this slice.

## Acceptance criteria for this slice

1. Native remote-control navigation reaches Package Browser, Resolve Plugin, and Preview Plugin.
2. Package Browser consumes the existing normalized `package-state` schema.
3. Resolve/Preview use registered actions and strict plugin-ID validation.
4. Invalid IDs and unexpected action parameters are rejected before subprocess execution.
5. No GUI path uses `shell=True`, `os.system`, or arbitrary executable/argument input.
6. Mock/CI validation does not claim real-receiver support.
7. Package mutation runs asynchronously so the GUI thread is not blocked by the package manager.
