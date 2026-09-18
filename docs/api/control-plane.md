# Control Plane API Contract

Target API only; not implemented by this discovery commit.

Receiver: GET /api/receivers; POST /api/receivers; GET /api/receivers/:id; POST /api/receivers/:id/detect; GET /api/receivers/:id/status; GET /api/receivers/:id/capabilities

Actions: POST /api/receivers/:id/actions. Payload contains action, validated parameters, dry_run, confirmation and request_id. Arbitrary command strings are prohibited.

Plugins: GET /api/plugins; GET /api/plugins/:id; POST /api/receivers/:id/plugins/install; POST /api/receivers/:id/plugins/update; DELETE /api/receivers/:id/plugins/:id

Channels: GET /api/receivers/:id/channels; POST /api/receivers/:id/channels/scan; POST /api/receivers/:id/channels/import; POST /api/receivers/:id/channels/export

Bouquets: GET/POST/PATCH/DELETE /api/receivers/:id/bouquets and /api/receivers/:id/bouquets/:id

Settings: GET /api/receivers/:id/settings; GET/PUT /api/receivers/:id/settings/:key

Backup: GET/POST /api/receivers/:id/backups; POST /api/receivers/:id/backups/:id/restore

Diagnostics: GET /api/receivers/:id/diagnostics; POST /api/receivers/:id/diagnostics/run

Jobs: GET/POST /api/jobs; GET /api/jobs/:id; POST /api/jobs/:id/run

Audit: GET /api/audit. Every mutation emits an audit event.
