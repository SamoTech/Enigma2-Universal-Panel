# Receiver & Image Compatibility

This document lists known compatible Enigma2 receivers and Linux images.

## Supported Images

| Image | Status |
|---|---|
| OpenATV 7.x | ✅ Supported |
| OpenVIX 5.x | ✅ Supported |
| DreamOS | ✅ Supported |
| Black Hole | ⚠️ Partial |
| Egami | ⚠️ Partial |
| OpenPLi | 🔜 Planned |
| OpenDROID | 🔜 Planned |

## Supported Architectures

| Architecture | Receivers |
|---|---|
| MIPS | DreamBox 500, 800, 7000 series |
| ARM (32-bit) | Vu+ Uno/Solo, GigaBlue, Octagon |
| ARM64 / AArch64 | Newer GigaBlue, AX/Mutant receivers |

## Notes

- The bootstrap script is POSIX sh / BusyBox compatible.
- OPKG is the primary package manager target; apt-get and ipkg are secondary fallbacks.
- Receivers without network access require manual script transfer via USB or FTP.
