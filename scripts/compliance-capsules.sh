#!/usr/bin/env bash
# story: e01s01
# plan-consistency-check across every epic capsule (plan-work hard gate).
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
for capsule in specs/epics/e*/; do
  [ -d "$capsule" ] || continue
  if bash scripts/lib/plan-consistency-check.sh "$capsule" >/tmp/bq-capsule.log 2>&1; then
    :
  else
    printf '  BLOCKED: %s\n' "$(basename "$capsule")"
    tail -3 /tmp/bq-capsule.log | sed 's/^/      /'
    fail=1
  fi
done
[ "$fail" -eq 0 ] && echo "all capsules: CRITICAL=0 HIGH=0"
exit "$fail"
