# Diagnostics Discovery

Identity: model, chipset, architecture, image, version, build, kernel, Enigma2.

Resource: CPU, load, RAM, swap, flash, storage, inode, temperature.

Process/service: Enigma2 process, init/service manager, failed services, process crashes.

Network: interfaces, addresses, routes, gateway, DNS resolution, TCP reachability, listening ports, Wi-Fi, VPN.

Package: package manager, feed reachability, package database consistency, dependency state.

Tuner: frontend inventory, lock state, signal metrics, active tuner, delivery system, scan availability.

Channel database: lamedb integrity, bouquet references, orphaned services, missing bouquet files.

EPG: database/cache state, importer status, freshness, source configuration.

Recording: mount availability, recording path, free space, timer conflicts, writable destination.

Streaming: service reference, stream availability, transcoding capability, OpenWebif state.

Logs: Enigma2 log, system log, crashlogs, plugin-specific logs.

Health states: healthy, warning, degraded, critical, unknown.

Diagnostics are read-only by default. Repair actions must be separate registered actions.
