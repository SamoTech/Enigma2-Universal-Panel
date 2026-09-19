# Enigma2 Universal Panel — Capability Discovery

Discovery baseline: 2026-09-19.

This directory is the evidence-backed capability inventory for the Universal Management Layer. It separates capability discovery from implementation, package/plugin existence from compatibility, image support from receiver/hardware support, and known behavior from unknown behavior.

## Product-interface principle

The primary interface is a **native Enigma2 GUI plugin running on the receiver**.

Discovery therefore covers both:

1. receiver capabilities that the native GUI can expose safely; and
2. optional remote/web capabilities that may be added later.

Remote/web capability must never be treated as a prerequisite for local panel operation.

## Evidence policy

verified = directly represented in authoritative source code, package metadata, maintained documentation, or validated receiver behavior.

high = multiple authoritative sources support the model but receiver/image conditions remain.

medium = credible evidence exists but receiver-side validation is still required.

unknown = evidence is insufficient and must remain unknown.

The inventory is a seed, not a claim that every historical/community plugin has been catalogued.

## Discovery domains

- receiver and image identity
- Enigma2 GUI/plugin APIs
- package managers and feeds
- plugin/package compatibility
- channels and bouquets
- EPG
- settings
- services
- storage/network
- backup/recovery
- diagnostics
- automation
- optional remote management

## Implementation rule

A documented capability is not automatically implemented. A row in the capability matrix describes a target capability and evidence state; implementation status belongs to the roadmap and code/tests.

No feature should be exposed in the GUI solely because it appears in this discovery inventory.

## Primary evidence sources

- https://github.com/openatv/enigma2
- https://github.com/OpenViX/enigma2
- https://github.com/OpenPLi/enigma2
- https://github.com/OpenPLi/enigma2-plugins
- https://github.com/oe-alliance/oe-alliance-core
- https://github.com/oe-alliance/enigma2-plugins
- https://github.com/oe-alliance/3rdparty-plugins
- https://github.com/e2openplugins
- https://github.com/E2OpenPlugins/e2openplugin-OpenWebif
- https://github.com/oe-alliance/AutoBouquetsMaker
- https://github.com/OpenPLi/enigma2-plugin-extensions-epgimport
