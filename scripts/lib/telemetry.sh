#!/bin/sh
# Evidence-backed receiver telemetry. Read-only; no mutation.

print_telemetry() {
  load_1=unknown
  load_5=unknown
  load_15=unknown
  if [ -r /proc/loadavg ]; then
    set -- $(cat /proc/loadavg 2>/dev/null)
    load_1=${1:-unknown}
    load_5=${2:-unknown}
    load_15=${3:-unknown}
  fi

  mem_total_kb=unknown
  mem_available_kb=unknown
  mem_free_kb=unknown
  if [ -r /proc/meminfo ]; then
    mem_total_kb=$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo 2>/dev/null)
    mem_available_kb=$(awk '/^MemAvailable:/ {print $2; exit}' /proc/meminfo 2>/dev/null)
    mem_free_kb=$(awk '/^MemFree:/ {print $2; exit}' /proc/meminfo 2>/dev/null)
  fi

  ram_total_mb=unknown
  ram_available_mb=unknown
  ram_used_mb=unknown
  ram_used_percent=unknown
  if [ "$mem_total_kb" != unknown ] && [ "$mem_available_kb" != unknown ] && [ "$mem_total_kb" -gt 0 ]; then
    ram_total_mb=$((mem_total_kb / 1024))
    ram_available_mb=$((mem_available_kb / 1024))
    ram_used_mb=$(((mem_total_kb - mem_available_kb) / 1024))
    ram_used_percent=$(((mem_total_kb - mem_available_kb) * 100 / mem_total_kb))
  fi

  root_total_kb=unknown
  root_available_kb=unknown
  root_used_percent=unknown
  if has df; then
    set -- $(df -k / 2>/dev/null | awk 'NR==2 {print $2, $4, $5}')
    root_total_kb=${1:-unknown}
    root_available_kb=${2:-unknown}
    root_used_percent=$(printf "%s" "${3:-unknown}" | tr -d "%")
    [ -n "$root_used_percent" ] || root_used_percent=unknown
  fi

  python_version=unknown
  if has python3; then
    python_version=$(python3 --version 2>&1 | sed 's/^Python //')
  elif has python; then
    python_version=$(python --version 2>&1 | sed 's/^Python //')
  fi

  printf 'load_1=%s\n' "$load_1"
  printf 'load_5=%s\n' "$load_5"
  printf 'load_15=%s\n' "$load_15"
  printf 'ram_total_mb=%s\n' "$ram_total_mb"
  printf 'ram_available_mb=%s\n' "$ram_available_mb"
  printf 'ram_used_mb=%s\n' "$ram_used_mb"
  printf 'ram_used_percent=%s\n' "$ram_used_percent"
  printf 'mem_free_kb=%s\n' "$mem_free_kb"
  printf 'root_total_kb=%s\n' "$root_total_kb"
  printf 'root_available_kb=%s\n' "$root_available_kb"
  printf 'root_used_percent=%s\n' "$root_used_percent"
  printf 'python_version=%s\n' "$python_version"
}
