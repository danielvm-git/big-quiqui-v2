#!/usr/bin/env bash
# story: e05s03
# status-counts.sh — the honest epic/story counts, computed from the two files that
# actually hold them.
#
# Why this exists: `pj` counts keys in `execution-status.yaml` (including the
# per-row `recorded_by`/`evidence` sub-keys) and reported 35/155 for a project with
# 43 planned stories. A dashboard may render whatever it likes; this prints the
# numbers a human should trust, and flags the drift that hid nine e01/e02 stories.
#
#   bash scripts/status-counts.sh          # human summary
#   bash scripts/status-counts.sh --json   # machine summary
#
# Exit: 0 always (reporting tool). Drift is printed, not silenced.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/python-env.sh"
cd "$(dirname "$0")/.."

$PYTHON - "${1:-}" <<'PY'
import json
import sys

import yaml

want_json = sys.argv[1] == "--json"
plan = yaml.safe_load(open("specs/release-plan.yaml")) or {}
status = yaml.safe_load(open("specs/execution-status.yaml")) or {}
sot = status.get("stories") or {}
dev = status.get("development_status") or {}

plan_epics = plan.get("epics") or []
epics = []
total = done = 0
for epic in plan_epics:
    stories = epic.get("stories") or []
    finished = [s for s in stories if (sot.get(s) or {}).get("status") == "done"]
    missing = [s for s in stories if s not in sot]
    unstarted = [s for s in missing if dev.get(epic.get("id")) != "done"]
    total += len(stories)
    done += len(finished)
    epics.append(
        {
            "id": epic.get("id"),
            "title": (epic.get("title") or "").split(":")[0],
            "status": dev.get(epic.get("id")),
            "stories_done": len(finished),
            "stories_total": len(stories),
            "missing_from_sot": missing,
            "unstarted": unstarted,
        }
    )

# Drift is narrow on purpose: a story with no SoT row that belongs to a *done* epic.
# That is how nine e01/e02 stories left every dashboard while their capsules said
# done. A planned story has no row yet, and that is not drift.
flags = [e for e in epics if e["status"] == "done" and e["missing_from_sot"]]
unstarted = sum(len(e["unstarted"]) for e in epics)

summary = {
    "epics_total": len(epics),
    "epics_done": sum(1 for e in epics if e["status"] == "done"),
    "stories_total": total,
    "stories_done": done,
    "stories_left": total - done,
    "next_epic": next((e["id"] for e in epics if e["status"] != "done"), None),
    "drift": [{"epic": e["id"], "missing_from_sot": e["missing_from_sot"]} for e in flags],
    "unstarted_stories": unstarted,
    "epics": epics,
}

if want_json:
    print(json.dumps(summary, indent=2))
    raise SystemExit(0)

print(f"epics    {summary['epics_done']}/{summary['epics_total']} done · {summary['epics_total'] - summary['epics_done']} left")
print(f"stories  {summary['stories_done']}/{summary['stories_total']} done · {summary['stories_left']} left")
print(f"next     {summary['next_epic'] or '(none)'}")
print()
for epic in epics:
    mark = "✓" if epic["status"] == "done" else "·"
    print(f"  {mark} {epic['id']}  {epic['stories_done']}/{epic['stories_total']}  {epic['title']}")
print(f"queued   {unstarted} story rows are created when their story starts")
if flags:
    print()
    print("DRIFT — done epics whose stories are absent from execution-status.yaml:")
    for epic in flags:
        print(f"  {epic['id']}: {', '.join(epic['missing_from_sot'])}")
else:
    print("no drift: every story of a done epic has its row")
PY
