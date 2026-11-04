# Threat Model — e01 (Foundation + TitleScene)

<!-- story: e01s01 -->
**Skill:** `security-review` (build-epic Step 0) · **Date:** 2026-11-04
**Surface:** Godot 4.7 client, 100% offline, iPadOS + desktop, no accounts, no network.
**Method:** STRIDE over the trust boundaries that actually exist for a local kids' game.

## Assets

| Asset | Why it matters | Where it lives |
|---|---|---|
| Child's play diary (`user://logs/quiqui-*.jsonl`) | may contain names, times, absolute paths | device only |
| Save file (`user://progress.json`) | coins, tickets, owned furniture | device only |
| Family voice recordings | personal data (LGPD Art. 14 — child data) | shipped inside the app |
| Art/audio assets | IP; also the only `res://` inputs | bundled |

## Trust boundaries

1. **Engine ↔ filesystem** (`user://` only; `res://` is read-only in an exported build).
2. **Input ↔ game logic** (touch events; synthesized mouse echo; drag coordinates).
3. **Data files ↔ runtime** (JSONL read-back by `scripts/logs.sh`; `SaveData` load).
4. **There is no network boundary.** Any `HTTPRequest`/`WebSocketPeer` in `game/` is a
   build-breaking defect (enforced by a CI grep, not by convention).

## STRIDE

| Category | Threat (concrete) | Likelihood | Mitigation (already specified) |
|---|---|---|---|
| **S**poofing | none — no identity, no accounts, no multi-user | n/a | — |
| **T**ampering | a crafted `progress.json` with absurd coin counts | low (child cannot author JSON) | `SaveData` typed resource validates ranges on load; invalid → defaults + `Log.event("save.invalid")` |
| **R**epudiation | parent cannot tell what the child did | low | append-only JSONL diary, `session.marker` crash detection, `scripts/logs.sh summary` |
| **I**nformation disclosure | **primary risk:** a name/e-mail/absolute path written into the diary, then shared by a parent | medium | `Log.redact_pii` at write time; `scripts/logs.sh audit --self-test` runs 6 PII cases in Preflight `L3` and CI |
| **D**enial of service | a corrupted save or missing audio stream locks input | medium | graceful degradation: missing stream → `Log.event` + silent fallback; save load failure → defaults; `SceneManager` 2.0 s watchdog |
| **E**levation of privilege | `res://` path traversal via an item/resource id | low | ids validated against `\A[a-z0-9_]{1,64}\z` **before** any `res://` path is built |

## Kids-specific threats (not in STRIDE)

| Threat | Mitigation |
|---|---|
| Dark patterns / accidental purchase | no store SDK, no IAP, no ads — nothing to purchase in the binary |
| Data leaving the device | network APIs banned + CI grep over `game/scripts`, `game/components`, `game/scenes` |
| `signals/` eavesdropping of the diary by other apps | iOS app sandbox; `user://` is per-app; no shared container entitlements |
| Reading requirement | zero text gates: every prompt is visual + PT-BR voice |
| Motion / photosensitivity | no full-screen strobe; celebration rays are <3 Hz (verified at e07 by design review) |

## Findings for e01s01 implementation (must be closed in that story)

| ID | Finding | Severity | Required action |
|---|---|---|---|
| T-E01-01 | `Log` is the only PII chokepoint; if a later story writes files directly it bypasses redaction | HIGH | `Log` exposes the only writer; add a test asserting no `FileAccess.open("user://logs/...")` outside `log.gd` (static grep test) |
| T-E01-02 | `TestReset` must not be reachable in an exported build | MED | guard with `OS.is_debug_build()`; assert in SC-E01-P0-06 |
| T-E01-03 | `dir`/`path` values in log events could carry absolute paths | MED | `Log` normalizes any `res://`/`user://`/`/Users/` prefix to a token (covered by the 6 PII self-test cases) |
| T-E01-04 | `GDScript.reload()` in `type_gate` executes no code, but confirms nothing about runtime type safety | LOW | accepted: static gate only; runtime coverage comes from GUT |

## Out of scope (with reason)

- Network exfiltration: no network stack exists; the CI grep is the control.
- Multi-tenant isolation: single-user local app.
- Supply chain beyond `game/addons/gut` (vendored, pinned 9.6.0) and Godot 4.7 itself.

## Verification

```bash
bash scripts/logs.sh audit --self-test        # 6 PII cases rejected
grep -RInE '\b(HTTPRequest|HTTPClient|WebSocketPeer)\b' game/scripts game/components game/scenes || echo "no network APIs"
test -f specs/security/epics/e01/THREAT_MODEL.md
```
