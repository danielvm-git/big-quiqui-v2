# story: e04s01
class_name QuiQuiScrubHull
extends RefCounted
## Elliptical scrub hull in rig-local coordinates.


static func local_polygon(seen_global: Rect2, rig_rect: Rect2, point_count: int, inset: float) -> PackedVector2Array:
	var origin: Vector2 = rig_rect.position
	var box: Rect2 = Rect2(seen_global.position - origin, seen_global.size).grow(-inset)
	if box.size.x <= 1.0 or box.size.y <= 1.0:
		return PackedVector2Array()
	var centre: Vector2 = box.get_center()
	var radii: Vector2 = box.size * 0.5
	var hull: PackedVector2Array = PackedVector2Array()
	for index: int in range(point_count):
		var angle: float = TAU * float(index) / float(point_count)
		hull.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return hull
