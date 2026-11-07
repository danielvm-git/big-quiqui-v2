#!/usr/bin/env bash
# story: e11s04
# Personal Team deploy helper — never prints secrets or the environment.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRESET="$ROOT/game/export_presets.cfg"
IPA="$ROOT/build/ios/quiqui.ipa"

usage() {
  echo "Usage: $0 --check | --dry-run" >&2
}

if [[ "${1:-}" == "--check" ]]; then
  test -f "$PRESET"
  grep -q 'name="iOS"' "$PRESET"
  grep -q 'res://tests/' "$PRESET"
  grep -q 'res://addons/gut/' "$PRESET"
  echo "ios-deploy: export preset OK (tests and GUT excluded)"
  exit 0
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "ios-deploy: would export to $IPA (no device call without signing)"
  exit 0
fi

usage
exit 1
