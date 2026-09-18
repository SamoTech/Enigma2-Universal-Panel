# Channel, Service and Bouquet Discovery

## Core storage
The standard receiver-side channel state is primarily represented under /etc/enigma2.

- lamedb: DVB service/transponder database data
- bouquets.tv: TV bouquet references
- bouquets.radio: radio bouquet references
- userbouquet.*: user bouquet/service membership
- settings: Enigma2 configuration
- timers.xml: timer state in current Enigma2 sources

References: https://github.com/openatv/enigma2 ; https://github.com/OpenViX/enigma2 ; https://github.com/openatv/enigma2-plugin-settings-defaultsat

## Service domains
DVB-S, DVB-S2, DVB-S2X, DVB-C, DVB-T, DVB-T2, radio, IPTV/stream services, data services, provider metadata and EPG mappings. Actual tuner support is receiver-dependent.

## Entities
service, transponder, satellite, provider, bouquet, bouquet_membership, service_reference, iptv_playlist, epg_mapping.

## Actions
channel.scan, channel.blind_scan, channel.import, channel.export, channel.create, channel.update, channel.delete, channel.move, channel.rename, channel.lock, channel.hide, channel.favorite, channel.assign_bouquet, channel.remove_from_bouquet, channel.sync, channel.backup, channel.restore.

bouquet.create, bouquet.rename, bouquet.delete, bouquet.add_service, bouquet.remove_service, bouquet.move_service, bouquet.import, bouquet.export, bouquet.backup, bouquet.restore.

AutoBouquetsMaker explicitly builds and updates bouquets from DVB streams and contains scanner, transponder, service and bouquet writer/reader components: https://github.com/oe-alliance/AutoBouquetsMaker

Its scanner manager uses /etc/enigma2 as its working path: https://github.com/oe-alliance/AutoBouquetsMaker/blob/master/AutoBouquetsMaker/src/scanner/manager.py

IPTV is modeled as a service-source type, not as a satellite tuner. Playlist formats and plugins vary, so compatibility must be detected from installed plugins, binaries and service-reference behavior.

Channel/bouquet writes should use backup -> preview -> validate -> stage -> apply -> verify -> rollback where possible.