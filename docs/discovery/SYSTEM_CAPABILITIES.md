# System Capability Discovery

The capability inventory describes what Enigma2 receivers may expose. It is not a claim that every capability is currently implemented.

## Native panel target

The native Enigma2 GUI is the primary presentation layer for supported capabilities.

Receiver identity: model, manufacturer, machine name, chipset, CPU architecture, CPU cores, RAM, flash/storage, kernel, image, image version/build, Enigma2 version, driver version.

Runtime health: uptime, CPU, memory, storage, inode usage, temperature, processes, services, logs, crashlogs.

Package system: package manager detection, feed detection, package list, install, remove, update, package information, dependency resolution.

Enigma2 lifecycle: restart GUI, restart Enigma2, restart service, reboot, shutdown, standby, deep standby.

Network: interfaces, addresses, routes, DNS, gateway, connectivity, Wi-Fi, VPN, listening services.

Storage: mount discovery, filesystem health, free space, HDD, USB, NFS, SMB, recording destination.

Tuner: tuner discovery, frontend state, lock, SNR, BER, AGC, supported delivery systems, active service, scan capability.

Recording/media: timers, recordings, movie list, timeshift, stream state, transcoding where supported.

Channels/bouquets: service discovery, scanning, bouquet inspection, import/export and controlled editing where the receiver adapter supports it.

EPG: discovery, import and refresh where supported.

Settings: discovery, normalized read/write settings and validation where supported.

Diagnostics: crash logs, service state, feed state, package state and health diagnostics.

## Risk classes

LOW = read-only telemetry.

MEDIUM = reversible runtime changes.

HIGH = persistent configuration/package/plugin/network/tuner changes.

CRITICAL = image flashing, factory reset, destructive restore, or arbitrary privileged execution.

Critical and unsupported operations must not be exposed by the GUI.

## Remote/web distinction

OpenWebif and future remote APIs are optional external management surfaces. They are not the local panel and are not required to use the native GUI.
