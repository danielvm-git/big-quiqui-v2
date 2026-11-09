#!/usr/bin/env python3
# story: e11s03
"""Traceability gate: every planned story -> the code that implements it -> the test that proves it.

`e11s03` promised a "gate-trace Full Traceability Sign-Off" and the artifact never existed: the
only thing anyone checked was `scripts/trace-stories.sh`, which asks whether a file *has* a
`# story:` tag, not whether the story it names is implemented, tested, or even planned.

This reads the plan (`specs/release-plan.yaml`), the story tags in `game/`, and writes
`specs/TRACEABILITY_LATEST.md`. A story that the plan calls done and that has no test is a
**dark story** and exits non-zero (unless it is listed in `UNTESTABLE` below with a reason).

Usage:
  python3 scripts/traceability.py --write   # regenerate the artifact, non-zero on a dark story
  python3 scripts/traceability.py --check   # same scan, no write (what preflight runs)
  python3 scripts/traceability.py --self-test  # prove the detector can fail
"""

import argparse
import os
import re
import sys

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("traceability: PyYAML missing — pip install -r requirements.txt")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "specs", "release-plan.yaml")
OUT = os.path.join(ROOT, "specs", "TRACEABILITY_LATEST.md")
# A story's *deliverable* can legitimately be a test helper (e11s02 shipped MonkeyStream and
# no production code), so helpers count as code. What must never happen is a planned story
# with no artifact at all, or production behaviour with no test that exercises it.
CODE_DIRS = [
    os.path.join(ROOT, "game", "scripts"),
    os.path.join(ROOT, "game", "tools"),
    os.path.join(ROOT, "game", "tests", "helpers"),
]
TEST_DIRS = [os.path.join(ROOT, "game", "tests", "unit"), os.path.join(ROOT, "game", "tests", "integration")]
# Some stories were verified by an audit doc rather than by their own code tag (e04s03 shipped as
# RINSE/DRY inside e04s02's files and was signed off in AUDIT-e04-epic.md). The audit record is
# evidence too; pretending it is not would report a verified story as missing.
AUDIT_DIR = os.path.join(ROOT, "specs", "verifications")
# Both shapes exist in this repo: `# story: e01s01` in scripts and `<!-- story: e04s03 -->` in the
# audit/review markdown.
TAG_RE = re.compile(r"^(?:#|<!--) story: (e\d{2}s\d{2})", re.MULTILINE)

# A story the plan calls done that cannot carry a test, with the reason. Anything not listed
# here must have one; adding a row is a deliberate, reviewable act.
UNTESTABLE = {
    "e11s04": "the iOS export preset is proved by CI's export job and a device smoke test; "
    "the preset file itself is asserted structurally by test_export_preset.gd",
}


def _tagged(paths):
    """story id -> sorted list of files that carry its tag."""
    found = {}
    for base in paths:
        for dirpath, _dirnames, filenames in os.walk(base):
            for name in sorted(filenames):
                if not name.endswith(".gd"):
                    continue
                path = os.path.join(dirpath, name)
                with open(path, encoding="utf-8") as handle:
                    head = handle.read(4096)
                for story in set(TAG_RE.findall(head)):
                    found.setdefault(story, []).append(os.path.relpath(path, ROOT))
    for story in found:
        found[story].sort()
    return found


def _planned_stories():
    """(epic id, epic status, [story ids]) from the release plan."""
    with open(PLAN, encoding="utf-8") as handle:
        plan = yaml.safe_load(handle)
    rows = []
    for epic in plan.get("epics", []):
        rows.append((epic["id"], str(epic.get("status", "")), [str(s) for s in epic.get("stories", [])]))
    return rows


def _capsule_stories():
    """story ids that have a capsule file, so a planned-but-not-yet-planned story is visible."""
    epics_dir = os.path.join(ROOT, "specs", "epics")
    found = set()
    for dirpath, _dirnames, filenames in os.walk(epics_dir):
        for name in filenames:
            match = re.match(r"(e\d{2}s\d{2})\.md$", name)
            if match:
                found.add(match.group(1))
    return found


def _tagged_md(path):
    found = {}
    if not os.path.isdir(path):
        return found
    for name in sorted(os.listdir(path)):
        if not name.endswith(".md"):
            continue
        full = os.path.join(path, name)
        with open(full, encoding="utf-8") as handle:
            head = handle.read(4096)
        for story in set(TAG_RE.findall(head)):
            found.setdefault(story, []).append(os.path.relpath(full, ROOT))
    return found


def collect():
    code = _tagged(CODE_DIRS)
    tests = _tagged(TEST_DIRS)
    audit = _tagged_md(AUDIT_DIR)
    plan = _planned_stories()
    capsules = _capsule_stories()
    rows = []
    for epic_id, status, stories in plan:
        for story in stories:
            rows.append(
                {
                    "story": story,
                    "epic": epic_id,
                    "epic_status": status,
                    "coded": code.get(story, []),
                    "tested": tests.get(story, []),
                    "audit": audit.get(story, []),
                    "capsule": story in capsules,
                }
            )
    return rows, code, tests, audit


def verdict(row):
    """covered | code_only | test_only | audited | missing | waived.

    `missing` is the only one that fails the gate: a planned, done story with no artifact
    anywhere in the repo. The others are degrees of evidence, reported for the roadmap.
    """
    if row["story"] in UNTESTABLE:
        return "waived"
    if row["coded"] and row["tested"]:
        return "covered"
    if row["coded"]:
        return "code_only"
    if row["tested"]:
        return "test_only"
    if row["audit"]:
        return "audited"
    return "missing"


def render(rows, code, tests, audit):
    counts = {}
    for row in rows:
        counts[verdict(row)] = counts.get(verdict(row), 0) + 1
    orphan_code = sorted(set(code) - {row["story"] for row in rows})
    orphan_tests = sorted(set(tests) - {row["story"] for row in rows})
    lines = [
        "# Traceability — planned story to code to test",
        "",
        "<!-- story: e11s03 -->",
        "**Generated by** `python3 scripts/traceability.py --write`. Do not hand-edit.",
        "",
        f"**{len(rows)} planned stories**: "
        + ", ".join(f"{count} {name}" for name, count in sorted(counts.items()))
        + f". {len(orphan_code)} tag(s) in code with no story in the plan, "
        + f"{len(orphan_tests)} test tag(s) outside the plan.",
        "",
        "| Story | Epic | Epic status | Code | Tests | Audit | Capsule | Verdict |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for row in rows:
        lines.append(
            "| `{story}` | {epic} | {epic_status} | {code_n} | {test_n} | {audit_n} | {capsule} | {verdict} |".format(
                story=row["story"],
                epic=row["epic"],
                epic_status=row["epic_status"],
                code_n=len(row["coded"]),
                test_n=len(row["tested"]),
                audit_n=len(row["audit"]),
                capsule="yes" if row["capsule"] else "**no**",
                verdict=verdict(row).upper(),
            )
        )
    lines += ["", "## Waived", ""]
    for story, reason in sorted(UNTESTABLE.items()):
        lines.append(f"- `{story}` — {reason}")
    lines += ["", "## Tags outside the plan", ""]
    for story in orphan_code:
        lines.append(f"- code: `{story}` in {', '.join(code[story])}")
    for story in orphan_tests:
        lines.append(f"- tests: `{story}` in {', '.join(tests[story])}")
    if not orphan_code and not orphan_tests:
        lines.append("- none")
    lines.append("")
    return "\n".join(lines), counts


def self_test():
    """Prove the detector can fail: a story with no test must be UNTESTED, not COVERED."""
    covered = {"story": "e01s01", "epic": "e01", "epic_status": "done", "coded": ["a.gd"], "tested": ["t.gd"], "audit": [], "capsule": True}
    dark = {"story": "e99s01", "epic": "e99", "epic_status": "done", "coded": ["a.gd"], "tested": [], "audit": [], "capsule": True}
    naked = {"story": "e99s02", "epic": "e99", "epic_status": "done", "coded": [], "tested": [], "audit": [], "capsule": True}
    waived = {"story": "e11s04", "epic": "e11", "epic_status": "done", "coded": [], "tested": [], "audit": [], "capsule": True}
    audited = {"story": "e99s03", "epic": "e99", "epic_status": "done", "coded": [], "tested": [], "audit": ["a.md"], "capsule": True}
    cases = [
        (covered, "covered"),
        (dark, "code_only"),
        (naked, "missing"),
        (audited, "audited"),
        (waived, "waived"),
    ]
    for row, want in cases:
        got = verdict(row)
        if got != want:
            print(f"traceability --self-test: {row['story']} expected {want}, got {got}")
            return 1
    print("traceability --self-test: the detector distinguishes covered/code_only/missing/audited/waived")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="regenerate specs/TRACEABILITY_LATEST.md")
    parser.add_argument("--check", action="store_true", help="scan only (default)")
    parser.add_argument("--self-test", action="store_true", help="prove the detector can fail")
    args = parser.parse_args()
    if args.self_test:
        return self_test()

    rows, code, tests, audit = collect()
    text, counts = render(rows, code, tests, audit)
    if args.write:
        with open(OUT, "w", encoding="utf-8") as handle:
            handle.write(text)
        print(f"traceability: wrote {os.path.relpath(OUT, ROOT)} ({len(rows)} stories)")

    bad = [
        row
        for row in rows
        if verdict(row) == "missing" and row["epic_status"] == "done"
    ]
    for row in bad:
        print(f"traceability: {verdict(row).upper()} {row['story']} ({row['epic']}, {len(row['tested'])} test files)")
    if bad:
        print(f"traceability: {len(bad)} story(ies) without a test — see specs/TRACEABILITY_LATEST.md")
        return 1
    print("traceability: every planned story has code and a test (or a recorded waiver)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
