# Verify + Audit — e07 (Bedroom Sleep & Celebration, closing the care cycle)

<!-- story: e07s01 -->
<!-- story: e07s02 -->
<!-- story: e07s03 -->
<!-- story: e07s04 -->
**Flow:** `build-epic` steps 0–6 for four stories · **Date:** 2026-11-06 · **Branch:**
`epic/e07-sleep-and-celebration-scenes`
**Gate:** **PREFLIGHT GREEN** — 36 scripts, **393 tests, 2057 asserts** (epic start: 378 / 1969)

## Verdict

**PASS.** Four stories, six threat findings closed, three defects found by the tests before they shipped.

## Per story

| Story | Delivered | Tests |
|---|---|---|
| e07s01 | `SleepScene`, `quarto_sono.tscn` (11 nodes): lamp toggle, night tint on the background only, plush tuck, zzz, SLEEP credited once | 6 |
| e07s02 | `CelebrationScene`, `celebracao.tscn` (6 nodes): confetti, voice, closes the cycle; reward owned by the manager | 4 |
| e07s03 | `CareLoopManager.close_celebrate_if_needed()` + wiring in `SceneManager.request_scene` | 2 |
| e07s04 | cycle E2E on both canvases, detour mid-cycle | 3 |

## Verify (step 5)

- **Cold start:** `godot --headless --path game --quit-after 3` → **0** errors or warnings.
- **Gates:** L0 lint/format ✓ · L0b type gate ✓ · L1 GUT 393/393 ✓ · L3 PII ✓ · L4 trace ✓ · L5/L5b ✓ ·
  **L5c** version sync ✓ · **L6** workflow lint ✓.
- **UAT:** the four story suites plus the cycle E2E; every scene passes `GeometryOracle` with
  `STEP_ROOM_SPEC` on `1920×1080` and `2048×1536`; no scene carries text.

## Audit (step 6)

| Section | Result | Note |
|---|---|---|
| Strict typing / type gate | **PASS** | 36 scripts |
| Fsm discipline | **PASS** | one `SLEEPING→FINISHED` machine; the cycle walked by the existing loop machine |
| Touch / echo | **PASS** | every interactive node ignores `device == -1` |
| Functions ≤ 20 lines | **PASS after fixes** | `request_scene` 26 → 21 + `_park` + `_close_celebrate_for_detour` |
| File size (300 guideline) | **PASS** | new scripts 92–203 lines |
| No dead code / duplication | **PASS** | `_leave()`/`_request()` each exist once per scene, no shared copy |
| Network / PII | **PASS** | L3 green, no HTTP/WebSocket/`OS.shell` |

### Three defects the tests caught

1. **Double reward.** `CelebrationScene` paid with `complete_cycle` *and* `CareLoopManager` pays on entry to
   CELEBRATE → 10 coins instead of 5, 2 cycles instead of 1. The money owner is the manager; the scene now
   only closes the cycle. Caught by the first run of e07s02's tests.
2. **The detour guard closed legitimate transitions.** Wired naively in `request_scene`, it closed
   CELEBRATE on `SleepScene`'s own request for the celebration, breaking `SLEEP → CELEBRATE`. Fixed with
   two whitelisted targets (hub, celebration).
3. **E2E asserted an intermediate state that cannot exist.** The celebration mounts on SLEEP's request, so
   there is no observable `CELEBRATE` state after the loader settles; the test now asserts the end state.

### Notes and accepted debt

1. **Art gap, recorded:** the set has no `abajur` or `cobertor`, so the lamp uses `zzz.png` as its icon and
   the blanket is the plush. Placeholder for the art pass, same as `bg_quarto` in e05.
2. **`bg_quarto` is the bedroom** and `bg_celebracao` the party: both exist, no placeholder needed there.
3. **The e03-era "doors stay pending" test retired.** Every care door now has a scene, so the test asserts
   all five navigate to their own room — the fifth and last time a new scene changed the hub.
4. **e07s04's scope is stated in its spec:** it drives the two new rooms by touch and walks the earlier
   four steps through the loop; each earlier room's gesture is proven by its own E2E suite.

## Traceability

`trace-stories.sh --strict` → 0 missing. `e07s01..s04` referenced from their specs, task files and the
verification rows above.
