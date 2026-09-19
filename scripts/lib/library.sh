#!/bin/sh
# Unified plugin-library projection.
# Catalog metadata is local; installation remains controlled by registered actions.

plugin_library() {
  [ -r "$PANEL_ROOT/plugins/catalog.json" ] || {
    error "Plugin catalog is unavailable"
    return 1
  }
  [ -r "$PANEL_ROOT/plugins/community.json" ] || { error "Community registry is unavailable"; return 1; }
  [ -r "$PANEL_ROOT/plugins/community-admitted.json" ] || { error "Community admission registry is unavailable"; return 1; }

  PYTHON_BIN=unknown
  if has python3; then
    PYTHON_BIN="$(command -v python3)"
  elif has python; then
    PYTHON_BIN="$(command -v python)"
  fi
  [ "$PYTHON_BIN" != unknown ] || {
    error "Python runtime is required for plugin-library projection"
    return 1
  }

  if [ -r "$PANEL_ROOT/plugins/categories.json" ]; then
    "$PYTHON_BIN" - "$PANEL_ROOT/plugins/catalog.json" "$PANEL_ROOT/plugins/community.json" "$PANEL_ROOT/plugins/categories.json" <<'PY'
import io
import json
import sys

catalog_path, community_path, categories_path = sys.argv[1:4]\nadmitted_path = catalog_path.rsplit('/', 1)[0] + '/community-admitted.json'

def read_json(path):
    with io.open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)

catalog = read_json(catalog_path)
community = read_json(community_path)
taxonomy = read_json(categories_path)\nadmitted = read_json(admitted_path)\nadmitted_map = {e.get('id'): e for e in admitted.get('entries') or []}

category_titles = {}
for category in taxonomy.get("categories") or []:
    category_titles[category.get("id")] = category.get("name") or category.get("id")

category_aliases = {
    "system_administration": "system",
    "service_management": "system",
    "satellite_configuration": "channels",
    "conditional_access_configuration": "security",
    "conditional_access_software": "security",
    "backup_flash": "multiboot",
    "multi_boot": "multiboot",
    "media_streaming": "media",
    "iptv_interface": "media",
    "iptv_stalker": "media",
    "iptv_streaming": "media",
    "stalker_portal": "media",
    "audio_commentary": "audio",
    "epg_bouquet_generation": "epg",
    "iptv_bouquet_generation": "channels",
    "iptv_to_dvb_mapping": "channels",
    "sports_and_satellite": "media",
    "signal_diagnostics": "monitoring",
    "picons": "gui",
    "subtitles": "localization",
    "translation": "localization",
    "timeshift": "recording",
    "third_party_catalog": "utilities",
}
canonical_categories = set(category_titles)

items = []
for entry in catalog.get("plugins") or []:
    category_original = entry.get("category", "unknown")
    category = category_original if category_original in canonical_categories else category_aliases.get(category_original, "utilities")
    items.append({
        "id": entry.get("id"),
        "item_type": "plugin",
        "name": entry.get("display_name") or entry.get("name") or entry.get("id"),
        "category": category,
        "category_original": category_original,
        "category_name": category_titles.get(category, category.replace("_", " ").title()),
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
        "source_reference": entry.get("repository"),
    })

for entry in community.get("entries") or []:
    health = entry.get("health") or {}
    category_original = entry.get("category", "unknown")
    category = category_original if category_original in canonical_categories else category_aliases.get(category_original, "utilities")
    items.append({
        "id": entry.get("id"),
        "item_type": entry.get("item_type", "plugin"),
        "name": entry.get("name") or entry.get("id"),
        "category": category,
        "category_name": category_titles.get(category, category.replace("_", " ").title()),
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
        "source_reference": entry.get("source_reference") or entry.get("repository"),
        "network_reachability": health.get("network_reachability", "unknown"),
        "maintenance_status": health.get("maintenance_status", "unknown"),
        "execution_status": entry.get("execution_status", "blocked"),
        "installer_path": entry.get("installer_path"),
        "installer_version": entry.get("installer_version") or entry.get("release_version"),
        "source_ref": entry.get("source_ref"),
        "installable": bool(admitted_map.get(entry.get("id"))),
        "updatable": bool(admitted_map.get(entry.get("id"))),
        "removable": False,
        "community_admitted": bool(admitted_map.get(entry.get("id"))),
        "requires_gui_restart": bool((admitted_map.get(entry.get("id")) or {}).get("requires_gui_restart", False)),
        "requires_reboot": bool((admitted_map.get(entry.get("id")) or {}).get("requires_reboot", False)),
    })

items.sort(key=lambda item: (
    str(item.get("category", "")),
    str(item.get("name", "")).lower(),
    str(item.get("id", "")),
))

print(json.dumps({
    "schema_version": 2,
    "type": "plugin_library",
    "taxonomy_version": taxonomy.get("schema_version", 1),
    "categories": [
        {
            "id": category.get("id"),
            "name": category.get("name"),
            "description": category.get("description", "")
        }
        for category in taxonomy.get("categories") or []
    ],
    "entries": items,
    "counts": {
        "total": len(items),
        "feed_managed": sum(1 for item in items if item["source"] == "receiver_feed"),
        "community": sum(1 for item in items if item["source"] == "community"),
        "community_blocked": sum(1 for item in items if item["availability"] == "community_blocked"),
    },
}, ensure_ascii=True, separators=(",", ":")))
PY
  else
    "$PYTHON_BIN" - "$PANEL_ROOT/plugins/catalog.json" "$PANEL_ROOT/plugins/community.json" <<'PY'
import io
import json
import sys

def read_json(path):
    with io.open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)

catalog, community = [read_json(path) for path in sys.argv[1:3]]
category_aliases = {
    "system_administration": "system", "service_management": "system",
    "satellite_configuration": "channels", "conditional_access_configuration": "security",
    "conditional_access_software": "security", "backup_flash": "multiboot",
    "multi_boot": "multiboot", "media_streaming": "media", "iptv_interface": "media",
    "iptv_stalker": "media", "iptv_streaming": "media", "stalker_portal": "media",
    "audio_commentary": "audio", "epg_bouquet_generation": "epg",
    "iptv_bouquet_generation": "channels", "iptv_to_dvb_mapping": "channels",
    "sports_and_satellite": "media", "signal_diagnostics": "monitoring",
    "picons": "gui", "subtitles": "localization", "translation": "localization",
    "timeshift": "recording", "third_party_catalog": "utilities"
}
canonical_categories = {
    "system","network","remote_control","media","epg","channels","recording","gui",
    "localization","audio","multiboot","monitoring","security","religious","utilities"
}
def canonical_category(value):
    if value in canonical_categories:
        return value
    return category_aliases.get(value, "utilities")

items = []
for entry in catalog.get("plugins") or []:
    category_original = entry.get("category", "unknown")
    category = canonical_category(category_original)
    items.append({
        "id": entry.get("id"), "item_type": "plugin",
        "name": entry.get("display_name") or entry.get("name") or entry.get("id"),
        "category": category, "category_original": category_original,
        "category_name": category.replace("_", " ").title(),
        "subcategory": entry.get("subcategory", "unknown"),
        "author": entry.get("author", "unknown"), "source": "receiver_feed",
        "source_type": entry.get("source_type", "unknown"), "status": entry.get("status", "unknown"),
        "availability": "feed_managed", "installable": bool(entry.get("installable", False)),
        "updatable": bool(entry.get("updatable", False)), "removable": bool(entry.get("removable", False)),
        "compatibility_confidence": entry.get("compatibility_confidence", "unknown"),
        "repository": entry.get("repository"), "source_reference": entry.get("repository")
    })
for entry in community.get("entries") or []:
    health = entry.get("health") or {}
    category_original = entry.get("category", "unknown")
    category = canonical_category(category_original)
    items.append({
        "id": entry.get("id"), "item_type": entry.get("item_type", "plugin"),
        "name": entry.get("name") or entry.get("id"), "category": category,
        "category_original": category_original,
        "category_name": category.replace("_", " ").title(), "subcategory": "community",
        "author": entry.get("developer", "unknown"), "source": "community",
        "source_type": entry.get("delivery", "unknown"), "status": entry.get("execution_status", "blocked"),
        "availability": "community_blocked" if str(entry.get("execution_status", "")).startswith("blocked") else "community_controlled",
        "installable": False, "updatable": False, "removable": False,
        "compatibility_confidence": "unknown", "repository": entry.get("repository"),
        "source_reference": entry.get("source_reference") or entry.get("repository"),
        "network_reachability": health.get("network_reachability", "unknown"),
        "maintenance_status": health.get("maintenance_status", "unknown")
    })
items.sort(key=lambda item:(str(item.get("category","")),str(item.get("name","")).lower(),str(item.get("id",""))))
print(json.dumps({
    "schema_version": 2,
    "type": "plugin_library",
    "taxonomy_version": 1,
    "categories": [],
    "entries": items,
    "counts": {
        "total": len(items),
        "feed_managed": sum(1 for item in items if item["source"] == "receiver_feed"),
        "community": sum(1 for item in items if item["source"] == "community"),
        "community_blocked": sum(1 for item in items if item["availability"] == "community_blocked")
    }
}, ensure_ascii=True, separators=(",", ":")))
PY
  fi
}
