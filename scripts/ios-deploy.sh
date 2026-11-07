#!/usr/bin/env bash
# story: e11s04
# Personal Team deploy helper — never prints secrets or the environment.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRESET="$ROOT/game/export_presets.cfg"
IPA="$ROOT/build/ios/quiqui.ipa"

required_keys=(
  'name="iOS"'
  "application/bundle_identifier="
  "application/min_ios_version="
  "application/targeted_device_family="
  "res://tests/"
  "res://addons/gut/"
)

validate_preset() {
  test -f "$PRESET" || { echo "ios-deploy: missing export_presets.cfg" >&2; return 1; }
  local text
  text="$(cat "$PRESET")"
  for key in "${required_keys[@]}"; do
    case "$key" in
      'name="iOS"' | res://*)
        grep -q "$key" "$PRESET" || { echo "ios-deploy: preset missing $key" >&2; return 1; }
        ;;
      *)
        grep -q "^$key" "$PRESET" || { echo "ios-deploy: preset missing $key" >&2; return 1; }
        ;;
    esac
  done
  mkdir -p "$ROOT/build/ios"
  if ! godot --headless --path "$ROOT/game" --export-pack "iOS" "$ROOT/build/ios/quiqui-check.pck" >/dev/null 2>&1; then
    echo "ios-deploy: Godot export-pack failed for preset iOS" >&2
    return 1
  fi
  rm -f "$ROOT/build/ios/quiqui-check.pck"
  return 0
}

usage() {
  echo "Usage: $0 --check | --dry-run" >&2
}

if [[ "${1:-}" == "--check" ]]; then
  validate_preset
  echo "ios-deploy: export preset OK (pack probe succeeded)"
  exit 0
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  validate_preset || exit 1
  echo "ios-deploy: would export to $IPA (Personal Team signing required for device install)"
  exit 0
fi

usage
exit 1
