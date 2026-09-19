#!/bin/sh
# Unified plugin-library projection.
# Catalog metadata is local; installation remains controlled by registered actions.

plugin_library() {
  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || {
    error "Plugin catalog is unavailable"
    return 1
  }
  [ -r "$PANEL_ROOT/plugins/community.json" ] || {
    error "Community registry is unavailable"
    return 1
  }
  has python3 || {
    error "Python 3 is required for plugin-library projection"
    return 1
  }

  python3 - "$PANEL_ROOT/plugins/catalog.json" "$PANEL_ROOT/plugins/community.json" <<'PY'
import json
import sys

catalog_path, community_path = sys.argv[1:3]
with open(catalog_path, "r", encoding="utf-8") as fh:
    catalog = json.load(fh)
with open(community_path, "r", encoding="utf-8") as fh:
    community = json.load(fh)

items = []
for entry in catalog.get("plugins") or []:
    items.append({
        "id": entry.get("id"),
        "name": entry.get("display_name") or entry.get("name") or entry.get("id"),
        "category": entry.get("category", "unknown"),
        "subcategory": entry.get("subcategory", "unknown"),
        "author": entry.get("author", "unknown"),
        "source": "receiver_feed",
        "source_type": entry.get("source_type", "unknown"),
        "status": entry.get("status", "unknown"),
        "availability": "feed_managed",
        "installable": bool(entry.get("installable", False)),
        "updatable": bool(entry.get("updatable", False)),
        "removable": bool(entry.get("removable", False)),
        "compatibility_confidence": entry.get("compatibility_confidence", "unknown"),
        "repository": entry.get("repository"),
    })

for entry in community.get("entries") or []:
    health = entry.get("health") or {}
    items.append({
        "id": entry.get("id"),
        "name": entry.get("name") or entry.get("id"),
        "category": entry.get("category", "unknown"),
        "subcategory": "community",
        "author": entry.get("developer", "unknown"),
        "source": "community",
        "source_type": entry.get("delivery", "unknown"),
        "status": entry.get("execution_status", "blocked"),
        "availability": "community_blocked" if str(entry.get("execution_status", "")).startswith("blocked") else "community_controlled",
        "installable": False,
        "updatable": False,
        "removable": False,
        "compatibility_confidence": "unknown",
        "repository": entry.get("repository"),
        "network_reachability": health.get("network_reachability", "unknown"),
        "maintenance_status": health.get("maintenance_status", "unknown"),
    })

items.sort(key=lambda item: (
    str(item.get("category", "")),
    str(item.get("name", "")).lower(),
    str(item.get("id", "")),
))

print(json.dumps({
    "schema_version": 1,
    "type": "plugin_library",
    "entries": items,
    "counts": {
        "total": len(items),
        "feed_managed": sum(1 for item in items if item["source"] == "receiver_feed"),
        "community": sum(1 for item in items if item["source"] == "community"),
        "community_blocked": sum(1 for item in items if item["availability"] == "community_blocked"),
    },
}, ensure_ascii=True, separators=(",", ":")))
PY
}
