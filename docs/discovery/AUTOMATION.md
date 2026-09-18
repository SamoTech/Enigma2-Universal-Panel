# Automation Discovery

Candidate scheduled operations: health check, storage threshold check, network check, EPG refresh, IPTV playlist refresh, channel synchronization, bouquet synchronization, package update, plugin update, backup, log cleanup, disk cleanup, service restart, Enigma2 restart, controlled reboot.

Every job has id, receiver_id, action_id, parameters, schedule, preconditions, timeout, retry_policy, failure_policy, notification_policy and audit_event.

Jobs use the same action registry as interactive operations and never bypass capability or compatibility checks.
