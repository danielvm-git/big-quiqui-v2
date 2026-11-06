# ADR-009: The care cycle's money, celebration dwell and the missing bedtime voice

<!-- story: e07s01 -->
<!-- story: e07s02 -->
<!-- story: e07s03 -->

- **Status:** Accepted
- **Date:** 2026-11-06
- **Recorded by:** e07 post-epic review (deliberate trade-offs, not silent skips)
- **Relates to:** BUG-019, BUG-020, BUG-027, `specs/security/epics/e07/THREAT_MODEL.md` (T-E07-03/04)

## Context

The e07 post-epic review found three behaviours that are not defects in the shipped code but that a
reviewer cannot leave undocumented, because the next agent would otherwise re-derive them:

1. **Who owns the ledger, and what it cannot guard.** `CareLoopManager._rewarded_cycle_id` is the only
   guard against a double payment, and it lives in RAM next to `cycle_id`. `ProgressManager` has no
   per-cycle guard of its own. `CareLoopManager.reset()` (test-only) zeroes both, so a replay after a
   reset pays again — 10 coins, 2 cycles — which no real play path can do: a fresh launch starts the
   loop in `IDLE` and the first reward of a session is a *new* cycle by definition.
2. **The celebration is short.** `CelebrationScene._ready()` closes the cycle and calls `_leave()`
   immediately, so the party lasts roughly one 0.4 s fade, and `celebrate_parabens.ogg` is cut by the
   transition. The scene's `advance(delta)`/`_clock_sec` are ticking and unused, which reads like a
   dropped hold.
3. **The bedroom has no voice line.** Every other care room opens with a family voice prompt
   (`feed_hora_de_comer`, `bath_hora_do_banho`, `dress_vamos_se_arrumar`, `play_hora_de_brincar`).
   `game/assets/audio/voice/` has no bedtime clip, and inventing one is impossible offline: the
   project's standing rule is family-recorded PT-BR, never TTS.

## Decision

1. **The ledger stays in `CareLoopManager`; it is per-session and documented as such.** The celebration
   does not read `_rewarded_cycle_id` (it only knows `credited_cycle`, its own once-per-mount latch).
   `celebracao.gd`'s docstring no longer claims that `ProgressManager` refuses a second payment for the
   same cycle — it does not, and the manager's transition-into-`CELEBRATE` is the single owner of money.
   A persisted per-cycle guard is **not** introduced: it would require a `SaveData` schema change
   (ADR-005 amendment + migration) to defend a path that does not exist outside tests.
2. **The short celebration is accepted for now and is a product call, not a bug.** A hold would change
   the e07s02 acceptance criteria ("entering plays the voice and one burst, the Casa is requested
   exactly once") and every test that pins the immediate return, so it is deferred to a playtest task
   with a measured `HOLD_SEC`, not patched in a review pass. Confetti and voice are both fired; what a
   child loses is duration, not feedback.
3. **The bedroom answers with SFX and the missing bedtime line is accepted debt.** `tap.ogg` on the
   lamp, `drop.ogg` on the tuck, `success.ogg` when the step is credited (BUG-020). The voice line is
   added when the family records it; until then the room is silent-but-not-mute rather than silent.
4. **Rig dressing outside the closet is out of e07's written scope.** `ProgressManager.dress()` has one
   caller (`ClosetScene`), so the bedroom and the celebration show the neutral rig instead of the outfit
   the child chose. Adding it here would change two stories' acceptance criteria; it becomes a story in
   a later epic (the celebration is where she looks at herself, so it belongs with the album/party work).

## Consequences

- The threat model's T-E07-03 mitigation is accurate only as "paid once per cycle **per session**".
  `AUDIT-e07-epic.md` and the threat model are corrected to say so.
- A future hold, a recorded bedtime line, and rig dressing have a named home; none of them is a
  surprise inside e08.

## Also considered, deliberately not changed

5. **The per-scene `_play_stream` / `_leave` twins stay.** `SleepScene` and `CelebrationScene` each carry
   their own small audio and navigation helpers, as every room since e03 does. The shared infrastructure
   that *is* genuinely shared was already extracted once (BUG-010); collapsing six rooms' private
   helpers into a base class is a refactor with no user-visible effect and no failing gate, so it is not
   smuggled into a review pass.

6. **The celebration does not display the reward (deferred to a story).** `IMPACT_LATEST.md` planned a
   "reward reveal" and `DESIGN_PLAN_LATEST.md` lists the coin/star art for it; e07s02's acceptance
   criteria and frozen `celebracao.tscn` contract do not. Implementing it now would change both — a
   product scope change, not a review fix. `moedinha.png` and `estrela.png` are already shipped and
   already used by `CoinTicketHud`, so the story is unblocked: see BUG-031, which also carries the
   `HOLD_SEC` the reveal needs (item 2 above).
