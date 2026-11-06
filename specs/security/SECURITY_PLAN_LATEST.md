# Security plan — threat model coverage and the rule that keeps it current

<!-- story: e06s03 -->
**Skill:** `security-review` · **Updated:** 2026-11-06 (bigpowers adoption audit, item E23)

## The rule

A threat model is written at **build-epic step 0**, before the first story of an epic produces code, and
it lives at `specs/security/epics/<epic>/THREAT_MODEL.md`. A story that touches auth, input handling, data
persistence or a filesystem path may not leave step 6 (audit) with an open HIGH finding.

## Coverage

| Epic | Threat model | Findings | Status |
|---|---|---|---|
| e01 | `epics/e01/THREAT_MODEL.md` | — | complete |
| e02 | `epics/e02/THREAT_MODEL.md` | T-E02-01..03 | complete |
| e03 | `epics/e03/THREAT_MODEL.md` | T-E03-01..06 | complete, all closed |
| e04 | `epics/e04/THREAT_MODEL.md` | T-E04-01..07 | complete, all closed |
| e05 | `epics/e05/THREAT_MODEL.md` | T-E05-01..07 | complete, all closed |
| e06 | `epics/e06/THREAT_MODEL.md` | T-E06-01..06 | complete, all closed |
| e07 | `epics/e07/THREAT_MODEL.md` | draft | **draft** — closes at e07 step 0 before any code |
| e08–e11 | not written | — | written at their step 0 |

## Why there is no `specs/security/REVIEW.md`

That file is expected by `release-branch` for repositories with server surfaces. This project has **no
server, no auth and no user data leaving the device**: the only trust boundaries are `user://` files and
the engine's input dispatch. The per-epic threat models above are the equivalent artefact, and
`release-branch` cites them instead.

## Standing invariants (checked mechanically)

| Invariant | Where it is enforced |
|---|---|
| No network: `HTTPRequest`/`HTTPClient`/`WebSocketPeer`/`OS.shell` never in `game/` | preflight no-grep stage, `health.sh offline`, `ci-lint` |
| No secret in the repo or a workflow | `ci-lint` (no env dumps), review |
| Ids from disk never reach a path unless `Ids`-valid | `Ids` + `SaveData` load drop + tests |
| Diary never carries prose or PII | `log_tool.py audit` (preflight L3) |
| Save writes are atomic | `ProgressManager._write_tmp` + ADR-005 |
