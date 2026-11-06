# ADR-010: Vila recycling and the wheel — deliberate trade-offs

<!-- story: e08s02 -->
<!-- story: e08s03 -->

- **Status:** Accepted
- **Date:** 2026-11-07
- **Recorded by:** e08 post-epic review (BUG-039, BUG-040, BUG-043)
- **Relates to:** ADR-005, ADR-009, `specs/security/epics/e08/THREAT_MODEL.md`

## Decisions

1. **Recycle pays once per session.** The ledger is `VilaScene.recycled_this_session`, in memory. A
   persisted guard would need a `SaveData` version bump (ADR-005); one extra coin per app launch is not
   worth a migration. There is no respawn: the frozen "spawn -> drag -> drop -> reward -> respawn" Fsm
   shipped as `READY <-> PAY`.
2. **The wheel is random in play, seeded in tests.** `WheelScene` seeds from the clock once and exposes
   `seed_rng()` for tests (SC-E08-P1-15). Re-seeding on every spin (the original code) made every spin pay
   the same prize.
3. **Home is locked while the wheel turns.** The ticket is spent at spin start, so leaving would lose it.
   The lock lasts 0.35 s plus a 0.2 s hold.
4. **The cost is floored to one ticket.** `EconomyData` is hand-edited tuning data.
5. **Frozen-contract drift, accepted:** `pick_prize()` replaces `_roll_prize()`; defaults are
   `EconomyData.new()` rather than a `.tres`; the hint hand is a styled `ColorRect` until the family draws
   `mao_dica.png` (never a Kenney placeholder); `DragHint.play` takes an optional third argument, the
   control to pulse.

## Consequences

Reviews that ask for a persisted recycle guard, a respawn loop or a `.tres` table are asking for a story,
not reporting a defect.
