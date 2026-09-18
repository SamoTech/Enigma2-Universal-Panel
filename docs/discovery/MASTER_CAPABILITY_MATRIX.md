# Master Capability Matrix

| Domain | Capability | Action | Risk | Root | Restart | Reboot | Rollback | Status | Confidence |
|---|---|---|---|---|---|---|---|---|---|
| Receiver | fingerprint | receiver.detect | low | yes | no | no | n/a | CORE | verified |
| Receiver | capabilities | receiver.capabilities | low | yes | no | no | n/a | CORE | verified |
| System | status | system.status | low | yes | no | no | n/a | CORE | verified |
| System | diagnostics | system.diagnose | low | yes | no | no | n/a | CORE | verified |
| System | package update | system.package_update | medium | yes | possible | possible | partial | CORE | high |
| System | package install/remove | package.install/remove | medium/high | yes | possible | possible | package restore | CORE | high |
| System | restart Enigma2 | system.restart_enigma2 | medium | yes | yes | no | n/a | CORE | verified |
| System | reboot | system.reboot | high | yes | no | yes | n/a | CORE | verified |
| System | backup | backup.create | medium | yes | no | no | n/a | CORE | high |
| System | restore | backup.restore | critical | yes | possible | possible | snapshot | CORE | high |
| Plugin | lifecycle | plugin.install/update/remove | medium/high | yes | possible | possible | package restore | CORE | high |
| Plugin | compatibility | plugin.compatibility | low | yes | no | no | n/a | CORE | verified |
| Channel | scan | channel.scan | medium | yes | possible | no | channel backup | CORE | high |
| Channel | blind scan | channel.blind_scan | medium | yes | possible | no | channel backup | EXTENSION | high |
| Channel | import/export | channel.import/export | medium | yes | no | no | backup | CORE | high |
| Bouquet | lifecycle | bouquet.* | medium/high | yes | possible | no | backup | CORE | high |
| IPTV | playlist management | iptv.* | medium | yes | possible | no | config backup | EXTENSION | medium |
| EPG | import/refresh | epg.import/refresh | low | yes | no | no | n/a | CORE | high |
| Tuner | discovery/signal | tuner.detect/tuner.signal | low | yes | no | no | n/a | CORE | high |
| Recording | timers | recording.timer.* | medium | yes | no | no | timer backup | EXTENSION | high |
| Network | status | network.status | low | yes | no | no | n/a | CORE | verified |
| Network | configuration | network.configure | high | yes | possible | possible | config backup | CORE | medium |
| GUI | skins/picons/display | gui.skin.* / gui.picon.* / gui.display.* | medium | yes | yes | no | package/config restore | EXTENSION | high |
| Diagnostics | crashlogs/feeds | diagnostics.* | low | yes | no | no | n/a | CORE | high |
| Services | status/restart | service.status/restart | low/medium | yes | possible | no | n/a | CORE | medium |
| Automation | scheduled health/backup | job.* | low/medium | yes | possible | possible | snapshot | EXTENSION | high |
| Remote Control | OpenWebif | remote.openwebif | medium | yes | no | no | n/a | CORE | verified |
| Monitoring | resources/storage/tuner | monitor.* | low | yes | no | no | n/a | CORE | high |

This matrix is capability-centric. It does not claim that the current runtime implements every row.
