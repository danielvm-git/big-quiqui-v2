#!/bin/bash
# Pull every TutoTOONS package's complete split-APK set via REA.
set -u
export PATH=/opt/homebrew/bin:/Users/danielvm/.nvm/versions/node/v24.22.2/bin:$PATH
export REA_ADB_PATH=/opt/homebrew/bin/adb
SERIAL=R9XT700Z7JV
cd /Users/danielvm/Developer/big-quiqui-v2 || exit 1
mkdir -p .rea/acq .rea/report

PKGS=$(adb shell pm list packages | grep -i tutotoons | sed 's/package://' | tr -d '\r' | sort)
total=$(echo "$PKGS" | wc -l | tr -d ' ')
i=0
for p in $PKGS; do
  i=$((i + 1))
  if [ -d ".rea/acq/$p" ]; then
    echo "[$i/$total] SKIP (already pulled) $p"
    continue
  fi
  echo "[$i/$total] PULL $p"
  rea pull-adb-package "$SERIAL" "$p" --output-directory .rea/acq --json > ".rea/report/pull-$p.json" 2>&1
  files=$(ls -1 ".rea/acq/$p" 2>/dev/null | wc -l | tr -d ' ')
  size=$(du -sh ".rea/acq/$p" 2>/dev/null | cut -f1)
  echo "        -> $files apks, ${size:-0}"
done
echo "=== DONE: $(du -sh .rea/acq | cut -f1) total ==="
