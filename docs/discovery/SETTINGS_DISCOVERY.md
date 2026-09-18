# Settings Discovery

Enigma2 uses /etc/enigma2/settings for substantial configuration state. Current OpenATV source explicitly creates/uses this file: https://github.com/openatv/enigma2/blob/master/tools/enigma2.sh.in

OpenATV setup definitions expose settings for plugin ordering, picon location, package categories and GUI/system behavior: https://github.com/openatv/enigma2/blob/master/data/setup.xml

## Taxonomy
System: hostname, timezone, locale, language, clock/NTP, startup/shutdown, standby, deep standby, power timers.
Network: DHCP/static addressing, gateway, DNS, IPv4/IPv6, Wi-Fi, proxy, SSH, FTP, SMB, NFS, VPN, firewall.
GUI: OSD, resolution, refresh rate, HDMI, HDR where supported, skin, fonts, picons, transparency, infobar, menus, timeout, LCD/VFD.
Tuner: mode, satellite, DiSEqC, LNB/LOF, tone/voltage, motor/positioner, Unicable/JESS, FBC, cable, terrestrial.
Channels: bouquet order, service lists, numbering, service restrictions, parental control, favorites.
EPG: source, refresh, XMLTV, Rytec/provider configuration, cache, retention, scheduling.
Recording: default path, timeshift, instant recording, margins, autotimers, conflict handling, HDD/NAS/NFS.
Media: playback, subtitle behavior, audio language, aspect ratio, transcoding where supported.
Audio/Video: HDMI, AC3, DTS, downmix, passthrough, audio delay, subtitle behavior.
Security: root credential state, SSH, FTP, Telnet, web authentication, parental control, service locks.
Packages: feeds, package sources, update policy, package filters and priorities.
Plugin-specific: dynamically registered namespaces from plugin metadata or maintained adapter definitions.

## Normalized setting record
stable id, raw key, display name, category/subcategory, type, default/current, allowed values/range, config file/key, setter/getter, image/plugin scope, restart/reboot requirement, destructive flag and evidence.

Raw configuration keys are implementation details. The public API should expose stable setting IDs.