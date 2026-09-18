# Architecture

## 1. Control-plane model

The panel has two execution domains.

Receiver plane: a small POSIX shell runtime installed on the Enigma2 receiver. It performs detection, local operations, validation and controlled module execution.

Control plane: a future web service that stores receiver profiles, credentials/keys, jobs, module metadata and audit events. It communicates through a receiver agent or SSH adapter.

## 2. Detection pipeline

boot -> root check -> OS/image detection -> Enigma2 detection -> architecture -> package manager -> storage/network -> capabilities -> adapter selection.

Detection output is stored as a normalized fingerprint. No module should independently reinvent receiver detection.

## 3. Adapter contract

Every image adapter should expose:

- id
- image families
- supported architectures
- required commands
- capabilities
- install package
- remove package
- update package
- restart enigma2
- restart gui
- reboot
- read logs
- backup
- restore

An operation is rejected if its required capability is absent.

## 4. Security boundary

The web application must not accept an arbitrary command string and send it to a receiver. It sends an action identifier plus validated parameters. The receiver resolves that action through a fixed allowlist.

Examples: system.restart_enigma2, system.reboot, package.install, package.remove, backup.create.

## 5. State

Receiver state is ephemeral and can be re-detected. Desired state belongs in the control plane. This enables idempotent jobs and drift detection.

## 6. Future web API

GET /api/receivers
POST /api/receivers
POST /api/receivers/:id/detect
GET /api/receivers/:id/capabilities
POST /api/receivers/:id/actions
GET /api/receivers/:id/logs
POST /api/receivers/:id/backups
POST /api/receivers/:id/restores
GET /api/plugins
GET /api/jobs
GET /api/audit
