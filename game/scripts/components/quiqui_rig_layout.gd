# story: e01s04
class_name QuiQuiRigLayout
extends RefCounted


static func update(rig: QuiQuiRig) -> void:
	if rig.expression == null or rig.expression.texture == null:
		return
	var art: Vector2 = rig.expression.texture.get_size()
	var used: Rect2 = rig.opaque_rect(rig.expression.texture)
	var seen: Vector2 = used.size if used.has_area() else art
	var factor: float = (rig.size.y if rig.size.y > 1.0 else seen.y) / seen.y if seen.y > 0.0 else 1.0
	var shift: Vector2 = (art - used.size) * Vector2(0.5, 1.0) - used.position if used.has_area() else Vector2.ZERO
	for sprite: Sprite2D in [rig.body, rig.outfit, rig.expression, rig.headwear, rig.neck, rig.glasses]:
		if sprite != null:
			sprite.scale = Vector2.ONE * factor
			sprite.position = (Vector2(0.0, -art.y * 0.5) + shift) * factor
	rig._rebuild_scrub_hull(rig.get_visual_global_rect())
	if rig.mouth_zone != null:
		rig.mouth_zone.size = seen * factor * 0.18
		rig.mouth_zone.position = Vector2(
			rig.size.x * 0.5 - rig.mouth_zone.size.x * 0.5, rig.size.y - seen.y * factor * 0.62
		)
