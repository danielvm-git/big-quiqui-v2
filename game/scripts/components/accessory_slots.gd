# story: e05s01
class_name AccessorySlots
extends RefCounted
## Slot vocabulary and placement maths for the rig's accessory layers (ADR-003).
##
## Kept out of `QuiQuiRig` because it is a pure function of the mouth zone and the
## art: no scene state, no scene graph, testable on its own.
##
## An accessory is placed relative to the **mouth zone**, offset by its own art height
## plus a margin, so "an accessory never covers the mouth" is true by construction
## rather than by tuning per canvas (T-E05-06).

const SLOT_BODY: String = "body"
const SLOT_HEAD: String = "head"
const SLOT_NECK: String = "neck"
const SLOT_EYES: String = "eyes"
const NAMES: Array[String] = [SLOT_HEAD, SLOT_NECK, SLOT_EYES]

## Accessory width as a share of the character height. Small on purpose: an accessory
## that reads as a blob is worse than none (DESIGN §4.5).
const SIZES: Dictionary = {SLOT_HEAD: 0.34, SLOT_NECK: 0.26, SLOT_EYES: 0.22}
## Multipliers applied to the half-art margin, so a tall hat clears the eyes below it.
const CLEARANCE: Dictionary = {SLOT_HEAD: 0.06, SLOT_NECK: -0.02, SLOT_EYES: 0.02}


## Where the accessory's centre goes, in the pivot's local space (negative = up).
static func position_for(
	slot: String, art: Vector2, scale_factor: float, character: float, mouth_from_feet: float
) -> Vector2:
	var half_height: float = art.y * scale_factor * 0.5
	var margin: float = character * float(CLEARANCE.get(slot, 0.02))
	return Vector2(0.0, -(mouth_from_feet + half_height + margin))


## Uniform scale that makes the item `SIZES[slot]` of the character height wide.
static func scale_for(slot: String, art_width: float, character: float) -> float:
	return character * float(SIZES.get(slot, 0.3)) / maxf(art_width, 1.0)
