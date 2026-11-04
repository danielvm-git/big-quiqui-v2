# e01 — Test Plan (Foundation + TitleScene)

<!-- story: e01s01 -->
**Skill:** `plan-tests` · **Date:** 2026-11-04 · **Risk level:** LOW (net-new, 0 dependents)
**Companion:** `specs/tech-architecture/TEST_PLAN_LATEST.md` (project-level 9-layer pyramid)

Scenario IDs follow `SC-<EPIC>-<PRIORITY>-<NN>`. P0 must exist before the story is
`done`; P1 is expected; P2/P3 optional per time budget.

## Coverage matrix

| ID | Level | Story | Scenario | Fails when |
|---|---|---|---|---|
| SC-E01-P0-01 | unit | e01s01 | `Fsm` accepts only declared `legal_edges`; undeclared transition returns `false` and emits `fsm.illegal_transition` | an edge not in the table is allowed |
| SC-E01-P0-02 | unit | e01s01 | `Fsm.transition_to(current)` is a silent idempotent no-op returning `false` | a same-state call fires a transition event or changes state |
| SC-E01-P0-03 | unit | e01s01 | `max_dwell_sec` fires `fsm.dwell_timeout` exactly once past the limit, never before | the watchdog is time-unstable or double-fires |
| SC-E01-P0-04 | unit | e01s01 | `Log` writes one JSON object per line, schema-valid (level, event, session, ts) | a line is not parseable JSON or misses a required key |
| SC-E01-P0-05 | unit | e01s01 | `Log` redacts PII (name, e-mail, long digit runs, absolute paths) before write | a raw name or absolute path reaches the file |
| SC-E01-P0-06 | unit | e01s01 | `TestReset` redirects saves to `user://test_progress.json` and deletes it in `before_each` | a test can read/write production `user://progress.json` |
| SC-E01-P0-07 | integration | e01s01 | `TouchSim.tap_control(..., with_mouse_echo=true)` fires exactly once per tap | the handler double-fires on the synthesized `device == -1` event |
| SC-E01-P0-08 | **control** | e01s01 | `preflight.sh` exits **1** when the GUT suite discovers 0 scripts | the Zero-Test Guard is bypassed (vacuity regression) |
| SC-E01-P1-01 | unit | e01s02 | `SceneManager` FSM: `IDLE→FADING_OUT→SWAPPING→FADING_IN→IDLE`, 2.0 s watchdog recovers a stuck transition | a transition can hang with no recovery |
| SC-E01-P1-02 | unit | e01s02 | 1-slot pending queue: two transitions in flight never drop the second | rapid navigation drops a request |
| SC-E01-P1-03 | unit | e01s02 | `AudioManager` ducks music/SFX by −9 dB while a `Voice` stream plays, restores after | ducking sticks or never engages |
| SC-E01-P1-04 | unit | e01s03 | `SaveData` round-trip: save → reset RAM → load equals original | a field is lost or coerced |
| SC-E01-P1-05 | unit | e01s03 | atomic write: `progress.json.tmp` never survives a successful save | a partial file can be read |
| SC-E01-P1-06 | integration | e01s04 | `QuiQuiRig` breathing/blink run off the foot pivot; outfit never covers `ExpressionOverlay` | the face is hidden by an outfit |
| SC-E01-P1-07 | e2e | e01s05 | `titulo.tscn` boots, Play button (≥120 px) navigates, theme plays | the scene cannot be entered by tap |
| SC-E01-P1-08 | e2e / geometry | e01s05 | `GeometryOracle` at 1920×1080 **and** 2048×1536: background covers 100%, 0 px letterbox, all targets ≥120 px | layout breaks on iPad 4:3 |
| SC-E01-P2-01 | unit | e01s05 | 20 consecutive taps do not leak nodes (monitor count stable) | per-tap nodes accumulate |

## Test level distribution (e01)

| Level | Count | Where |
|---|---|---|
| Unit (GUT) | 12 | `game/tests/unit/test_*.gd` |
| Integration | 3 | `game/tests/integration/test_*.gd` |
| E2E / geometry | 3 | `game/tests/integration/test_*_scene.gd` |
| Control | 1 | `game/tests/integration/test_preflight_guard.gd` |

## Fixtures

| Fixture | Purpose | Isolation |
|---|---|---|
| `TestReset` | redirect saves + reset singletons | `user://test_progress.json`, deleted in `before_each` |
| `FsmProbe` | assert zero illegal transitions / dwell timeouts | attaches per test, no globals |
| `TouchSim` | synthetic finger + mouse echo | deterministic input, no timing |
| `GeometryOracle` | dual-aspect layout assertions | sets viewport size, restores after |
| `LogTempSink` | capture JSONL without touching `user://logs` | temp dir per test |

## F.I.R.S.T. audit (`enforce-first`)

| Property | How it holds |
|---|---|
| **Fast** | no `await` on real timers except SC-E01-P0-03, which uses a fake clock |
| **Independent** | every test calls `TestReset`; no shared scene instance |
| **Repeatable** | no wall-clock or RNG assertions (blink uses a seeded RNG) |
| **Self-validating** | every assertion is a boolean predicate — no log-scraping in tests |
| **Timely** | each scenario is written RED before its implementation (single commit per RED step) |

## Gates

```bash
bash scripts/preflight.sh                       # full chain, must exit 0
bash scripts/lib/plan-consistency-check.sh specs/epics/e01-tracer-title-and-foundation/
bash scripts/run-story-verify.sh e01s01         # once tasks flip to passing
```
