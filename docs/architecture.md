# Architecture Overview

This document describes the planned architecture of the Enigma2 Universal Panel.

## Design Principles

- **POSIX compatibility**: All shell scripts target `/bin/sh` and BusyBox environments.
- **Modularity**: Each feature is an independent module loaded on demand.
- **Minimal footprint**: No persistent background daemons in early phases.
- **Safety first**: Scripts never modify critical system files without explicit user confirmation.

## Component Overview

```
install.sh (bootstrap)
    └── Detects environment
    └── Creates /tmp/enigma2-universal-panel
    └── Writes env.sh
    └── Loads requested modules

modules/
    ├── plugins.sh       # Plugin install/remove
    ├── channels.sh      # Channel list deployment
    ├── bouquets.sh      # Bouquet management
    ├── settings.sh      # Settings backup/restore
    ├── maintenance.sh   # System cleanup and repair
    └── ssh-manager.sh   # Remote SSH management

config/
    └── receivers.json   # Receiver metadata and compatibility

plugins/
    └── catalog.json     # Available plugins with metadata
```

## Module Loading (Planned)

Modules will be downloaded from the repository on demand and sourced into the running shell:

```sh
. "${PANEL_WORK_DIR}/modules/plugins.sh"
```

## Web Panel (Phase 6)

The Phase 6 web panel will be a lightweight web application deployable to a local server or accessible externally, communicating with receivers over SSH.
