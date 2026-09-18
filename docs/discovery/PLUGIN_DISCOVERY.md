# Plugin Discovery

Enigma2 plugins span core image plugins, OE-Alliance plugins, image-specific feeds, binary plugins, third-party packages, skins, picons, display packages and external repositories.

OpenATV exposes package categories including drivers, extensions, Kodi add-ons, system plugins, softcams, skins, skin components, plugin skins, display packages and picons. Source: https://github.com/openatv/enigma2/blob/master/data/setup.xml

OE-Alliance sources: https://github.com/oe-alliance and https://github.com/oe-alliance/3rdparty-plugins

OpenPLi sources: https://github.com/OpenPLi/enigma2-plugins and https://github.com/OpenPLi/enigma2-binary-plugins

E2 OpenPlugins: https://github.com/e2openplugins

## Verified seed catalog
| ID | Name | Category | Source | Status | Confidence |
|---|---|---|---|---|---|
| openwebif | OpenWebif | Remote Control / Administration | https://github.com/E2OpenPlugins/e2openplugin-OpenWebif | active | verified |
| autobouquetsmaker | AutoBouquetsMaker | Channel / Bouquet / Scanner | https://github.com/oe-alliance/AutoBouquetsMaker | active | verified |
| epgimport | EPGImport | EPG | https://github.com/OpenPLi/enigma2-plugin-extensions-epgimport | active | verified |
| crossepg | CrossEPG | EPG | https://github.com/E2OpenPlugins/e2openplugin-CrossEPG | maintained source | high |
| openairplay | OpenAirPlay | Media / Remote | https://github.com/E2OpenPlugins/e2openplugin-OpenAirPlay | maintained source | high |
| bitrate | Bitrate | Monitoring | https://github.com/E2OpenPlugins/e2openplugin-Bitrate | maintained source | high |
| hetweer | HetWeer | Misc / Weather | https://github.com/E2OpenPlugins/e2openplugin-HetWeer | maintained source | high |
| hdftoolbox | HDF-Toolbox | System | https://github.com/openhdf/hdftoolbox | image-specific | high |
| networkbrowser | NetworkBrowser | Network / Storage | https://github.com/OpenPLi/enigma2-binary-plugins | source component | high |
| moviecut | MovieCut | Recording / Media | https://github.com/OpenPLi/enigma2-binary-plugins | source component | high |
| lcd4linux | LCD4Linux | Display | https://github.com/OpenPLi/enigma2-binary-plugins | source component | high |
| ofgwrite | ofgwrite | Image / Flash | https://github.com/oe-alliance/ofgwrite | critical-risk component | verified |
| picons | Picons | GUI / Channel branding | https://github.com/openatv-picons | feed ecosystem | verified |
| remote-stream-convert | RemoteStreamConvert | Channels / Streaming | https://github.com/OpenLD/enigma2 | image/source component | high |

## Package families
- enigma2-plugin-extensions-*
- enigma2-plugin-systemplugins-*
- enigma2-plugin-skins-*
- enigma2-plugin-skincomponents-*
- enigma2-plugin-display-*
- enigma2-plugin-picons-*
- image/settings packages
- binary plugins
- driver packages
- supporting Python/native packages

## Catalog states
active, maintenance, legacy, deprecated, abandoned, unknown.

The panel must never infer active compatibility merely because a repository exists. The next crawler should enumerate repository trees and feed indexes, extract package names from recipes/IPKs, parse dependencies and architectures, then deduplicate by normalized project identity.