# BUG-063 — `project.godot` advertised 0.10.0 while the latest tag was v0.10.1

<!-- story: e12s01 -->
- **Severity:** low · **Priority:** P2 · **Scope:** release · **Status:** fixed locally (2026-11-08)
- **Found by:** `bash scripts/preflight.sh` (L5c `sync-project-version --check`) at the start of
  the Builder restart — the same gate BUG-016 introduced, biting again on `main`

## Symptom

`game/project.godot` said `config/version="0.10.0"`; `git describe --tags` says `v0.10.1`, and that
tag is an ancestor of `HEAD`. So the drift is committed, not local: the tree that CI would build
advertised a version one release behind.

## Why it recurred

`.big-release.yml` disables the Godot publisher on purpose (it rewrote `config/version` and never
committed it — BUG-016), and CI only runs `scripts/sync-project-version.sh --check`: it asserts the
two agree, it never writes. That is the right shape for a release gate, but it means the bump has
to arrive in a commit. A `fix:` commit landed on `main` after the tag was cut and did not carry it.

## Fix applied

`bash scripts/sync-project-version.sh` — `0.10.0` → `0.10.1`, matching the latest tag. Data-only,
no code touched.

## Durable fix (upstream, not here)

The pipeline is a copy of the portfolio template (ADR-007: pipeline logic belongs upstream), so the
systemic fix is in `danielvm-git/.github` → `test-build-release-godot.yml`: either commit the synced
`config/version` as part of the release job, or fail the release job earlier with a message that
names the missing bump. Recorded here so the next re-sync carries it, and not fixed locally, because
inventing a local stage is exactly what ADR-007 forbids.

## Evidence

- `bash scripts/sync-project-version.sh --check` → `version in sync: 0.10.1`.
- `bash scripts/preflight.sh --fast` → L5c PASS.
