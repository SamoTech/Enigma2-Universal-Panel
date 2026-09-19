# Enigma2 Universal Panel — Platform Compatibility Matrix

Status date: 2026-09-19

## Compatibility contract

The panel is designed as a receiver-side Enigma2 application and uses runtime detection rather than a fixed list of box models.

Compatibility is evaluated in layers:

1. Enigma2 runtime: the receiver must expose the native Enigma2 GUI/runtime expected by the plugin.
2. CPU architecture: package architecture must match the receiver or be declared architecture-independent.
3. Image family: the installed image is classified into a known family where evidence exists.
4. Package backend: the receiver package backend is detected from the live system.
5. Capability: each operation is exposed only when the required receiver capability is present.
6. Plugin metadata: a plugin is installable only when its package candidate, architecture, dependencies, conflicts and image policy all pass.
7. Physical validation: CI and mock-harness coverage do not replace testing on real hardware.

Unknown values never become an automatic compatibility approval.

## Image families

The runtime detector recognizes common Enigma2 image families and falls back to `generic-enigma2` only when an image-specific identity is not available but an Enigma2 runtime is present.

| Family | Examples | Typical package backend | Panel strategy |
|---|---|---|---|
| OE-Alliance derived | OpenATV, OpenViX, OpenHDF, OpenDroid, OpenEight, OpenLD and related OE-A images | opkg | native adapter + runtime detection |
| OpenPLi | OpenPLi | opkg | native adapter + runtime detection |
| DreamOS | DreamOS / Dream Multimedia software | apt + dpkg | native DreamOS adapter + .deb feed path |
| NewNigma2 | NewNigma2 | deb-based on supported Dreambox environments | Dreambox/Deb adapter; verify feed metadata |
| VTi | VTi on VU+ | image-defined | runtime detection; capability-gated |
| Other known Enigma2 | Merlin, EGAMI, HDMU, Pure2, OpenVision and other community images | image-defined | generic Enigma2 adapter until evidence establishes a stronger family |
| Unknown Enigma2 | valid Enigma2 runtime without recognizable image marker | image-defined | generic adapter, fail closed for image-specific actions |

This matrix is a compatibility model, not a claim that every listed image/version/device has been physically tested.

## Device families

The detector classifies the receiver when the firmware exposes model/board identity. The target is broad vendor coverage, including Dream Multimedia/Dreambox.

Known device families include:

- Dream Multimedia / Dreambox
- VU+
- GigaBlue
- Zgemma
- Octagon
- Edision
- Mutant
- Amiko
- Formuler
- AB-COM / AB
- Axas
- Golden Interstar
- Maxytec
- Qviart
- Uclan
- Xsarius
- Xtrend
- SAB
- Galaxy Innovations
- Miraclebox
- Spycat
- WeTek
- Other Enigma2 vendors detected from runtime identity

The universal strategy is deliberately vendor-agnostic. A new device does not require a new adapter merely because the vendor is new; a new adapter is required only when the device exposes materially different capabilities or package semantics.

## Support tiers

- **runtime-detected** — Enigma2 runtime, CPU architecture and package backend are identified.
- **generic-compatible** — the receiver can use the common Enigma2 action/GUI model, but image/device-specific evidence is incomplete.
- **image-specific** — a known image family and adapter are selected.
- **operation-supported** — the specific operation passed capability, compatibility, package and dependency checks.
- **physical-validated** — tested on a real receiver. This is currently outstanding for the project.

The panel must never display `physical-validated` based only on GitHub CI.

## Dreambox requirements

Dreambox is a first-class target.

The Dreambox path must:

- detect Dreambox/DreamOS from live receiver identity;
- detect the Debian-style `.deb` package backend used by supported DreamOS environments;
- avoid applying OE-`opkg` assumptions to DreamOS;
- use receiver-configured package feeds;
- validate package architecture against the live receiver;
- keep plugin installation inside the registered-action/policy boundary;
- preserve native Enigma2 GUI and remote-control operation.

Modern Dreambox environments have materially different package conventions from many OE-Alliance images, so compatibility is evaluated by runtime evidence rather than a single universal package name.

## Device/image separation

The same physical receiver can run different images. Therefore:

**device identity != image identity**

Example:

`Dreambox DM920 + DreamOS` and `Dreambox DM920 + another Enigma2 image` are separate compatibility states.

The panel therefore stores and reports both dimensions.

## Out of scope for automatic approval

The panel must not automatically approve:

- unknown image families;
- unknown CPU architectures;
- unverified package mappings;
- arbitrary download URLs;
- third-party install scripts;
- installer chains that execute unreviewed secondary payloads;
- firmware flashing operations without device-specific evidence.

These cases remain visible in the Store as blocked or unknown instead of being hidden.
