# story: e10s03
class_name IceLane
extends Control
## The ice lane where Pinguim slides (e10s03). Exposes scrub_hull_global() for
## TouchDraggable CONTINUOUS_SCRUB.


func scrub_hull_global() -> PackedVector2Array:
	var rect: Rect2 = get_global_rect()
	return PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		]
	)


func clamp_penguin_x(global_x: float, penguin_w: float) -> float:
	var rect: Rect2 = get_global_rect()
	var half_w: float = penguin_w * 0.5
	return clampf(global_x, rect.position.x + half_w, rect.end.x - half_w) - half_w
