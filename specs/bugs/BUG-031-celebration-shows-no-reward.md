---
bug_id: BUG-031
status: deferred
severity: low
scope: ui
title: The celebration pays +5/+1 but never shows it; the impact assessment planned a "reward reveal"
---
# BUG-031 (deferred): the party is the payoff, but the coins are revealed elsewhere

<!-- story: e07s02 -->

**Found by:** e07 post-epic review (comparing the epic against `specs/IMPACT_LATEST.md` and
`specs/tech-architecture/DESIGN_PLAN_LATEST.md`, which is what the review brief asks for).

## Problem

`IMPACT_LATEST.md` describes `celebracao.gd` as "CELEBRATE scene: confetti, **reward reveal**,
`complete_cycle`", and `DESIGN_PLAN_LATEST.md`'s e07 row lists `moedinha.png` / `estrela.png` for the
celebration. What shipped is confetti + voice + a one-fade return to the hub, whose `CoinTicketHud` then
shows the new totals.

For a pre-reading child the reward is therefore **not** connected to the party: five coins and a ticket
appear one fade later, on a different scene, in a corner. The frozen contract in `e07s02.md` §3 does not
list a HUD, and its acceptance criteria do not mention a reveal, so the epic is internally consistent —
it is the plan that was not delivered.

## Why it is not fixed in this pass

Implementing the reveal means new nodes in `celebracao.tscn` (a coin and a ticket bursting from the
confetti centre, no text) and a change to e07s02's frozen scene contract and acceptance criteria. That is
a **product scope change**, not a review fix: it belongs to a story with its own ACs, its own oracle run
and a playtest question ("does a 4-year-old look at the corner or at the confetti?"). Adding it silently
inside a post-epic pass would be exactly the kind of scope creep the gate exists to prevent.

`moedinha.png` and `estrela.png` already exist and are already used by `CoinTicketHud`, so the art is
available; nothing is blocked on assets.

## Proposed story (for the next planning pass)

> e??: the celebration shows what she earned — a coin and a ticket arc out of the burst before the
> return to the hub, one `moedinha.png` + one `estrela.png`, `GeometryOracle` `STEP_ROOM_SPEC` green on
> both canvases, no text, and a `HOLD_SEC` long enough to see them (see ADR-009 item 2 — the same hold
> the celebration needs).

## Verification of the current behaviour

`test_entering_pays_once_and_moves_the_loop_to_idle` pins the payment and the single Casa request; no
test (and no code) claims a visible reveal. Recorded in ADR-009 item 6.
