#!/bin/sh
# Read-only evidence snapshot for real-receiver validation.
# This command never mutates receiver state and accepts no user-controlled paths.

print_validation_snapshot() {
  detect_all
  select_adapter

  printf '%s\n' '=== receiver ==='
  print_status
  printf '%s\n' '=== capabilities ==='
  print_capabilities
  printf '%s\n' '=== compatibility ==='
  print_compatibility
  printf '%s\n' '=== telemetry ==='
  print_telemetry
  printf '%s\n' '=== reboot_verification ==='
  reboot_status
  printf '%s\n' '=== evidence_boundary ==='
  printf '%s\n' 'physical_validation=not_claimed'
  printf '%s\n' 'source=live_receiver_runtime'
}
