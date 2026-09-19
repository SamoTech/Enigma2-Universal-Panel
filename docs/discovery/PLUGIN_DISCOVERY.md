# Plugin Discovery

Enigma2 plugins span core image plugins, OE-Alliance plugins, image-specific feeds, binary plugins, third-party packages, skins, picons, display packages and external repositories.

The Universal Panel does not assume that repository existence means receiver compatibility. Discovery metadata is evidence for the native GUI and resolver; compatibility remains receiver/image dependent.

## Native GUI relationship

The plugin catalog is displayed by the native Enigma2 GUI only after compatibility and package-source checks.

The GUI should distinguish:

- known supported mapping;
- known package but unsupported image/architecture;
- package/source available but compatibility incomplete;
- unknown mapping;
- feed-dependent package.

An unknown state is not an installation permission.

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

The next discovery expansion should enumerate repository trees and receiver feed indexes, extract package names from recipes/package metadata, parse dependencies and architectures, and deduplicate by normalized project identity.
