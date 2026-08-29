# Installation Guide

This document provides detailed installation instructions for the Enigma2 Universal Panel.

## Prerequisites

- Enigma2 receiver running a supported Linux image (OpenATV, OpenVIX, DreamOS, etc.)
- Network/internet access on the receiver
- SSH or Telnet access to the receiver
- Root privileges

## Bootstrap Install

### Via wget

```sh
wget -O - https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh
```

### Via curl

```sh
curl -fsSL https://raw.githubusercontent.com/SamoTech/Enigma2-Universal-Panel/main/install.sh | sh
```

## What the Bootstrap Does

1. Verifies root access
2. Detects the package manager (opkg preferred)
3. Detects receiver architecture
4. Collects system information
5. Checks for `wget` or `curl`
6. Creates the working directory at `/tmp/enigma2-universal-panel`
7. Writes an environment file for use by future modules
8. Prints a system summary

## After Bootstrap

Once bootstrap completes, the working environment is ready at `/tmp/enigma2-universal-panel`. Future module installers will build on this foundation.
