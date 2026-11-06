---
bug_id: BUG-016
status: fixed
severity: medium
scope: release
title: project.godot advertises v0.1.0 while the release ladder is at v0.7.0
---

# BUG-016: the game's declared version never followed the release ladder

<!-- story: e06s03 -->
**Opened by:** the bigpowers adoption audit (item CI6, "root VERSION sync")

## Problem
`.big-release.yml` states, in a comment, that *"CI syncs project.godot + export_presets.cfg from the
tag"*. No such step exists in `.github/workflows/ci-cd.yml` (`grep project.godot` → nothing), and
`game/project.godot:10` still reads `config/version="0.1.0"` while six releases have shipped
(`v0.2.0` … `v0.7.0`).

Every iOS build therefore carries the wrong bundle version. It is invisible today because the export job
is the e11 placeholder; it becomes a store-rejection on the first TestFlight upload.

## Root cause
The sync was documented as if it existed. Nothing asserted the project's version against the tag, so the
drift had no way to fail.

## Fix
1. `scripts/sync-project-version.sh` writes `config/version` from the latest tag (or an explicit
   version), and `--check` asserts they match.
2. Preflight **L5c** runs `--check`, so a stale version fails the gate locally and in CI.
3. The export job runs the sync before building the IPA, so the artifact always matches the tag.
4. Immediate drift corrected: `project.godot` set to `0.7.0`.

## Verification
`bash scripts/preflight.sh` → **PREFLIGHT GREEN**, including the new L5c stage.
