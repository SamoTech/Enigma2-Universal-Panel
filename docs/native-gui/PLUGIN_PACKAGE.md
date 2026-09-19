# Native Enigma2 package/plugin GUI

Phase 1.4 is being delivered incrementally. The current slice adds a confirmed, asynchronous native package-install path on top of the existing resolver and action policy boundary.

## Current GUI surface

- Package Browser: reads `package-state` from the receiver and displays configured sources plus installed/available package inventory.
- Resolve Plugin: prompts for a normalized plugin ID and calls the registered resolver action.
- Preview Plugin: prompts for a normalized plugin ID and calls the registered, read-only compatibility/dependency preflight.
- Plugin Metadata: prompts for a normalized plugin ID and displays evidence-backed catalog metadata plus installed/candidate package versions when the receiver can resolve them.
- Install Plugin: performs the same preflight, requires explicit confirmation, then executes the registered high-risk install action asynchronously through Enigma2's native console container.
- Update Plugin: performs an installed-state/preflight check, requires explicit confirmation, then executes the registered high-risk update action asynchronously.
- Remove Plugin: performs a removal-specific safety preflight, requires explicit confirmation, then executes the registered high-risk removal action asynchronously.

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
- Removal is allowed only when the catalog declares the plugin `removable=true`, the package mapping is authoritative, the package is installed, and receiver/image/package-architecture checks pass.
- The receiver-side removal action re-runs the removal preflight, uses the catalog-resolved package through receiver-configured sources, verifies that the package is no longer installed, and writes an audit record.
- Metadata lookup is read-only and does not accept package names, URLs, shell commands, or arbitrary feed input.

## Acceptance criteria for this slice

1. Native remote-control navigation reaches Package Browser, Resolve Plugin, and Preview Plugin.
2. Package Browser consumes the existing normalized `package-state` schema.
3. Resolve/Preview use registered actions and strict plugin-ID validation.
4. Invalid IDs and unexpected action parameters are rejected before subprocess execution.
5. No GUI path uses `shell=True`, `os.system`, or arbitrary executable/argument input.
6. Mock/CI validation does not claim real-receiver support.
7. Package mutation runs asynchronously so the GUI thread is not blocked by the package manager.


### Native update flow

The native Update Plugin entry performs a read-only compatibility preflight and requires `status=supported` plus an installed package before confirmation. The mutation runs through the registered high-risk `plugin.update` action using `eConsoleAppContainer`. The receiver-side action re-runs preflight, updates only the catalog-resolved package through the receiver-configured package source, verifies that the package remains installed, and writes an audit record. GUI-restart requirements are displayed from verified catalog metadata; restart execution remains a separate controlled action.

### Native remove flow

The native Remove Plugin entry uses a dedicated read-only removal preflight rather than the install/update preview because removal must not depend on an available candidate version. The preflight requires an authoritative package mapping, `removable=true`, an installed package, and verified receiver/image/package-architecture compatibility. Confirmation is shown on the receiver, then the registered high-risk `plugin.remove` action runs asynchronously through `eConsoleAppContainer`. The receiver action repeats the same gates, removes only the catalog-resolved package through receiver-configured sources, verifies that it is no longer installed, and writes an audit record. GUI-restart/reboot requirements are displayed from catalog metadata; restart execution remains a separate controlled action.


### Receiver telemetry

The native dashboard now consumes a dedicated read-only `receiver.telemetry` action. It reports evidence-backed CPU load averages from `/proc/loadavg`, RAM totals/availability from `/proc/meminfo`, root filesystem capacity from `df`, and the available Python runtime version. The GUI can open a dedicated Receiver Telemetry screen and refresh the sample with the GREEN key. This is sampled telemetry, not a background real-time monitoring daemon.
