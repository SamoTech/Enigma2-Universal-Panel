# Control Plane API Contract

This document describes a **future optional remote control plane**. It is not the primary user interface and is not required for the native receiver panel to operate.

## Boundary

The native Enigma2 GUI and any future remote client use the same registered action model.

Remote payloads contain:

- action identifier
- validated parameters
- dry-run flag
- confirmation state where required
- request ID

Arbitrary command strings are prohibited.

## Future API

Receiver:

- GET /api/receivers
- POST /api/receivers
- GET /api/receivers/:id
- POST /api/receivers/:id/detect
- GET /api/receivers/:id/status
- GET /api/receivers/:id/capabilities

Actions:

- POST /api/receivers/:id/actions

Plugins:

- GET /api/plugins
- GET /api/plugins/:id
- POST /api/receivers/:id/plugins/install
- POST /api/receivers/:id/plugins/update
- DELETE /api/receivers/:id/plugins/:id

Channels:

- GET /api/receivers/:id/channels
- POST /api/receivers/:id/channels/scan
- POST /api/receivers/:id/channels/import
- POST /api/receivers/:id/channels/export

Settings:

- GET /api/receivers/:id/settings
- GET /api/receivers/:id/settings/:key
- PUT /api/receivers/:id/settings/:key

Backup:

- GET/POST /api/receivers/:id/backups
- POST /api/receivers/:id/backups/:id/restore

Diagnostics:

- GET /api/receivers/:id/diagnostics
- POST /api/receivers/:id/diagnostics/run

Jobs:

- GET/POST /api/jobs
- GET /api/jobs/:id
- POST /api/jobs/:id/run

Audit:

- GET /api/audit

Every mutation emits an audit event.

## Non-goal

The API must never become a second implementation of the receiver business logic. It dispatches registered actions to the receiver.
