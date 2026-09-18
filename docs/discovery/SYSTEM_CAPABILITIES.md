# System Capability Discovery

Receiver identity: model, manufacturer, machine name, chipset, CPU architecture, CPU cores, RAM, flash/storage, kernel, image, image version/build, Enigma2 version, driver version.

Runtime health: uptime, CPU, memory, storage, inode usage, temperature, processes, services, logs, crashlogs.

Package system: package manager detection, feed detection, package list, install, remove, update, package information, dependency resolution.

Enigma2 lifecycle: restart GUI, restart Enigma2, restart service, reboot, shutdown, standby, deep standby.

Network: interfaces, addresses, routes, DNS, gateway, connectivity, Wi-Fi, VPN, listening services.

Storage: mount discovery, filesystem health, free space, HDD, USB, NFS, SMB, recording destination.

Tuner: tuner discovery, frontend state, lock, SNR, BER, AGC, supported delivery systems, active service, scan capability.

Recording/media: timers, recordings, movie list, timeshift, stream state, transcoding where supported.

OpenWebif provides browser-based channel lists, EPG, timers, recordings, remote control and administration; exact features depend on image, hardware and installed extensions: https://openatv.github.io/enigma2-doku/en/netzwerk/openwebif/

Risk classes: LOW read-only telemetry; MEDIUM reversible runtime changes; HIGH persistent configuration/package/plugin/network/tuner changes; CRITICAL image flashing, factory reset, destructive restore, arbitrary privileged execution.
