# ADR-003: Layered `QuiQuiRig` Separating Layout Box, Foot Pivot, Outfits & Facial Expressions

<!-- story: e01s04 -->
- **Status:** Accepted
- **Retroactive:** yes — recorded after the decision was already in force in code
- **Date:** 2026-11-04

## Context
In the legacy codebase (`AUDIT-e18-s03`), equipping a full-body outfit replaced `_body_sprite.texture`, which prevented any of the 14 facial expressions (`rindo`, `boca_aberta`, `mastigando`, `sono`, etc.) from displaying while dressed. Furthermore, 6 different functions mutated `position` and `scale` concurrently.

## Decision
`QuiQuiRig` (`res://components/quiqui_rig.tscn`) wraps a foot-pivoted `Node2D` inside a `Control` layout box and layers `BodySprite` → `OutfitSprite` → `ExpressionSprite` (face region overlay / composited expression texture) → `HeadwearSprite` → `NeckSprite` → `GlassesSprite`. All motion tweens run through a single `MotionController` using a monotonic `_motion_token: int` that restores `_rest_transform` before starting any new animation.

## Consequences
QuiQui displays all 14 facial expressions even while wearing any outfit and accessories, and transform drift under rapid tapping is impossible.
