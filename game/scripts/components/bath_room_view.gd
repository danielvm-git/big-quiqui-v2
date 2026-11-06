# story: e04s04
class_name BathRoomView
extends RefCounted
## Geometry and device plumbing for the bath room, kept out of `BathScene` so the
## scene reads as a stage machine and this file reads as the layout rules.
##
## Everything here is a pure function of the nodes it is handed: no scene state, no
## ownership, so it can be unit-tested without mounting a scene.

## Rings the patches sit on, as a fraction of the hull radius. Two rings read as a
## pattern on her body instead of a grid on her face.
const RING_FRACTIONS: Array[float] = [0.55, 0.85]
## Patch diameter as a share of the painted character height.
const BLOB_RATIO: float = 0.11
const MIN_BLOB_PX: float = 24.0


## Normalised slots: (ring fraction, angle). Stable across resizes, so a patch keeps
## its place on her body instead of re-randomising (T-E04-07).
static func slots(count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for index: int in range(count):
		var ring: float = RING_FRACTIONS[index % RING_FRACTIONS.size()]
		out.append(Vector2(ring, TAU * float(index) / float(maxi(count, 1))))
	return out


## Places the patches inside the rig's scrub hull. The hull is the contract: a patch
## whose centre is outside it would be scrubbed on the wallpaper (T-E04-01).
static func project_blobs(rig: Control, blobs: Array[FoamBlob], slot_list: Array[Vector2]) -> void:
	if rig == null or blobs.is_empty() or slot_list.size() < blobs.size():
		return
	var hull: PackedVector2Array = _hull_of(rig)
	if hull.size() < 3:
		return
	var box: Rect2 = bounds(hull)
	var centre: Vector2 = box.get_center()
	var radii: Vector2 = box.size * 0.5
	var diameter: float = maxf(_painted_height(rig) * BLOB_RATIO, MIN_BLOB_PX)
	for index: int in range(blobs.size()):
		var slot: Vector2 = slot_list[index]
		var point: Vector2 = centre + Vector2(cos(slot.y) * radii.x * slot.x, sin(slot.y) * radii.y * slot.x)
		var blob: FoamBlob = blobs[index]
		blob.size = Vector2(diameter, diameter)
		blob.global_position = point - blob.size * 0.5


static func bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var box: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		box = box.expand(point)
	return box


static func contains(hull: PackedVector2Array, point: Vector2) -> bool:
	return hull.size() >= 3 and Geometry2D.is_point_in_polygon(point, hull)


## One device in hand at a time: the others are invisible and disabled, because a
## hidden-but-enabled target still steals the finger latch.
static func set_device(device: TouchDraggable, active: bool) -> void:
	if device == null:
		return
	device.enabled = active
	device.visible = active


static func tint(blobs: Array[FoamBlob], colour: Color) -> void:
	for blob: FoamBlob in blobs:
		blob.self_modulate = colour


static func _hull_of(rig: Control) -> PackedVector2Array:
	if not rig.has_method("scrub_hull_global"):
		return PackedVector2Array()
	var hull: Variant = rig.call("scrub_hull_global")
	return hull if hull is PackedVector2Array else PackedVector2Array()


static func _painted_height(rig: Control) -> float:
	if not rig.has_method("get_visual_global_rect"):
		return 0.0
	var painted: Variant = rig.call("get_visual_global_rect")
	return (painted as Rect2).size.y if painted is Rect2 else 0.0
