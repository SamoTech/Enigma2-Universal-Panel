# Enigma2 Universal Panel

> A universal management and installation panel for Enigma2 receivers.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Enigma2-blue.svg)](https://github.com/SamoTech/Enigma2-Universal-Panel)
[![Shell](https://img.shields.io/badge/shell-POSIX%20sh-green.svg)](install.sh)

---

## 📖 About

The **Enigma2 Universal Panel** provides a centralized system for managing and installing everything your Enigma2 Linux receiver needs — from plugins and channel lists to system maintenance tools — all from a single bootstrap script.

Supported receivers include DreamBox, Vu+, OpenATV, OpenVIX, and any Enigma2-based set-top box running a standard Linux image.

---

## 🎯 Project Goal

This panel will provide a centralized system for managing and installing:

- **Enigma2 plugins** — install, update, and remove plugins
- **Channel lists** — deploy curated channel lists to your receiver
- **Satellite bouquets** — manage satellite and FTA bouquets
- **IPTV bouquets** — import and manage IPTV channel groups
- **Settings packages** — deploy full settings backups/presets
- **Installation scripts** — run targeted scripts for specific tasks
- **System maintenance tools** — clean, repair, and optimize your receiver
- **Backup and restore tools** — full or partial backup/restore of settings

---

## ⚙️ Installation Methods (Planned)

| Method | Description |
|---|---|
| Direct Download | Download and run scripts from this repository |
| OPKG Installation | Install packages via the OPKG package manager |
| Shell Scripts | Execute targeted shell scripts via SSH/Telnet |
| SSH Execution | Run commands remotely over SSH |
| Telnet Execution | Run commands remotely over Telnet |
| Manual Command Copy | Copy and paste commands into the receiver terminal |

---

## 🚀 Quick Start — Bootstrap Installer

To install the panel bootstrap script on your Enigma2 receiver, connect via SSH or Telnet and run:

### Using `wget`:

```sh
wget -O - https://raw.githubusercontent.com/USERNAME/Enigma2-Universal-Panel/main/install.sh | sh
```

### Using `curl`:

```sh
curl -fsSL https://raw.githubusercontent.com/USERNAME/Enigma2-Universal-Panel/main/install.sh | sh
```

> ⚠️ **Important:** Replace `USERNAME` with the actual GitHub username hosting this repository (e.g. `SamoTech`).

**Requirements:**
- Must be run as `root`
- Enigma2 Linux receiver with network access
- `wget` or `curl` available on the receiver

---

## 🗺️ Roadmap

### Phase 1 — Repository & Installer Foundation *(current)*
- [x] Project structure setup
- [x] Bootstrap installer script (`install.sh`)
- [x] System detection (architecture, package manager, tools)
- [x] Working environment preparation
- [ ] Module loading framework

### Phase 2 — Plugin Catalog
- [ ] `plugins/catalog.json` with curated plugin list
- [ ] Plugin install/remove/update commands
- [ ] Plugin compatibility metadata per receiver/image

### Phase 3 — Channel & Bouquet Management
- [ ] Satellite bouquet packages
- [ ] IPTV bouquet import support
- [ ] Channel list deployment scripts

### Phase 4 — Settings Deployment
- [ ] Settings backup packages
- [ ] One-command settings restore
- [ ] Image-specific settings profiles

### Phase 5 — Remote Receiver Management via SSH
- [ ] SSH command execution from panel
- [ ] Remote status monitoring
- [ ] Multi-receiver management support

### Phase 6 — Web-Based Universal Panel
- [ ] Browser-accessible management panel
- [ ] Receiver connection manager
- [ ] Plugin/channel/settings dashboard
- [ ] Scheduled tasks and automation

---

## 📁 Repository Structure

```
Enigma2-Universal-Panel/
├── install.sh              # Bootstrap installer
├── scripts/
│   ├── install/            # Installation scripts
│   ├── maintenance/        # Maintenance and repair scripts
│   ├── backup/             # Backup and restore scripts
│   └── system/             # System utility scripts
├── plugins/
│   └── catalog.json        # Plugin catalog metadata
├── channels/
│   ├── bouquets/           # Satellite and IPTV bouquet files
│   └── settings/           # Channel settings packages
├── config/
│   └── receivers.json      # Receiver compatibility definitions
└── docs/
    ├── installation.md     # Detailed installation guide
    ├── compatibility.md    # Receiver and image compatibility
    └── architecture.md     # Project architecture overview
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests for:
- New plugin catalog entries
- Additional receiver compatibility data
- Script improvements
- Documentation updates

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

*Built with ❤️ for the Enigma2 community.*
