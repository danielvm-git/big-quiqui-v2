# ADR-008: Edge-Anchored Responsive Composition (replaces absolute pixel placement)

<!-- story: e02s03 -->
- **Status:** Accepted
- **Date:** 2026-11-04
- **Supersedes:** nothing (clarifies ADR-002 and `DESIGN.md` §layout, which offered two options)
- **Closes:** BUG-001, BUG-002

## Context

ADR-002 fixed the *viewport* contract (`canvas_items` + `expand`, `Control` roots, full-bleed
background) but not the *composition* contract. `DESIGN.md` §layout allows either edge anchoring
(`MarginContainer`, 36 px safe inset) or a centred `SafeStage` (1680×960); e01s05 and e02s03
implemented neither — every node was placed with absolute `position`/`size` in a 1920×1080
coordinate space. On the 4:3 `expand` canvas (1920×1440 logical) that left QuiQui's feet at 58 %
of the height instead of 78 %, the rig at 43 % of the height instead of 55–65 %, and a 396 px dead
band under the dots bar on the project's primary device.

Two further defects compounded it:

1. `Control.set_anchors_preset(PRESET_FULL_RECT)` followed by `size = Vector2(1920, 1080)` keeps the
   rect by rewriting offsets, so the scene roots packed at **2× the canvas** (3840×2160) and the
   full-bleed background rendered as a 2× zoom crop of its top-left quadrant.
2. `GeometryOracle` asserted only that the background **covered** the canvas (`≥`), so an oversized
   root passed, and it had no aspect-aware assertion at all.

## Decision

**Compose with anchors expressed as ratios of the canvas.** No `SafeStage` container is introduced;
the design's first option (edge anchoring) is used, because it keeps the approved 16:9 frame
pixel-identical and needs no new node in the tree.

- `QuiQuiRig`: `anchor_left = anchor_right = 0.5` with a fixed width, `anchor_top = feet - height`,
  `anchor_bottom = 0.78` (care rooms) so the box grows with the canvas and the feet stay on the line.
- Doors: fixed 168×168 boxes, edge columns (`anchor_left = 0`/`1`), row centres as ratios.
- `CareDotsBar`: bottom edge, 36 px inset, horizontally centred.
- `CoinTicketHud`: top-right, 36 px inset.
- `WishBubble`: pinned to the feet line, so it stays above QuiQui's head on every aspect.
- Scene roots use `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` and never assign `size`.
- Builders pin ratios through `SceneBuilder.pin(node, anchors, offsets)`.

`GeometryOracle` now checks the contract in both directions and takes a **spec** at the call site
(`CARE_ROOM_SPEC`, `TITLE_SPEC`): background size == canvas (letterbox *and* oversized), hit targets
≥120×120 inside the canvas, `rig` height ratio 0.55–0.65 and feet on the declared line and
horizontally centred, `ui_bottom` within 60 px of the bottom, `ui_top_right` within 60 px of the
top-right corner. A product requirement is only "verified" if the assertion can fail for it.

## Consequences

- The 16:9 composition is unchanged to the pixel (measured: root 1920×1080, background 1920×1080,
  rig feet 0.780, dots 36 px, HUD 36/36). The 4:3 canvas now composes: rig 0.574 of the height,
  feet 0.780, dots 36 px, doors on the edges, bubble on the feet line.
- Every future scene (e03–e10) inherits a mechanical layout gate: declare the groups, pass the spec,
  and a regression fails Preflight instead of shipping to a child's iPad.
- `QuiQuiRig` re-anchors its pivot on `NOTIFICATION_RESIZED`, so a responsive box actually grows the
  art instead of stranding it at the first frame's scale.
- Cost: layout constants live in the builders (per scene) and in the oracle (the product ratios).
  That duplication is deliberate — it makes the gate independent of the thing it grades.
