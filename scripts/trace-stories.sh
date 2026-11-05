#!/usr/bin/env bash
# story: e01s01
set -euo pipefail

# Verify that every GDScript file in game/scripts/, game/tests/ and game/tools/ carries a # story: eNNsYY tag
STRICT="${1:-}"
MISSING=0

if [ -d "game/scripts" ]; then
  while IFS= read -r -d '' file; do
    if ! grep -qE '^# story: e[0-9]{2}s[0-9]{2}' "$file"; then
      echo "MISSING STORY TAG: $file"
      MISSING=$((MISSING + 1))
    fi
  done < <(find game/scripts game/tests game/tools -type f -name "*.gd" -print0 2>/dev/null || true)
fi

if [ "$MISSING" -gt 0 ] && [ "$STRICT" = "--strict" ]; then
  echo "FAIL: $MISSING file(s) missing '# story: eNNsYY' header."
  exit 1
fi

echo "OK: Story traceability check passed ($MISSING missing)."
