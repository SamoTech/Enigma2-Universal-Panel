# Backup / Restore Discovery

Backup classes: full image, Enigma2 settings, channel database, bouquets, EPG data, plugin inventory, plugin configuration, network configuration, tuner configuration, skins/GUI assets, scripts, cron jobs, certificates, SSH configuration/keys when explicitly selected, package/feed metadata, user data, recording metadata, control-plane receiver profile.

OpenEight's image backup implementation collects image metadata, /etc/enigma2/settings and TV/radio bouquet information: https://github.com/Openeight/enigma2/blob/master/lib/python/Plugins/SystemPlugins/SoftwareManager/ImageBackup.py

OpenViX source contains RestoreWizard/BackupManager functionality, demonstrating image-specific backup/restore behavior: https://github.com/OpenViX/enigma2/commits

Restore transaction: preflight -> compatibility check -> snapshot -> stage -> apply -> restart/reboot if required -> verify -> commit.

Never restore configuration from a different receiver/image without an explicit compatibility decision.
