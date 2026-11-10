# story: e03s01
class_name TouchDraggableGeom
extends RefCounted


static func rect_of(control: Variant, margin: float, no_rect: Rect2) -> Rect2:
	if typeof(control) != TYPE_OBJECT or not is_instance_valid(control):
		return no_rect
	var target: Control = control as Control
	if target == null or not target.is_inside_tree():
		return no_rect
	return (target.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, target.size)).grow(margin)


static func normalized_of(global_point: Vector2, placement_area: Variant, no_rect: Rect2) -> Vector2:
	var rect: Rect2 = rect_of(placement_area, 0.0, no_rect)
	if rect == no_rect or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2.ZERO
	var ratio: Vector2 = (global_point - rect.position) / rect.size
	return Vector2(clampf(ratio.x, 0.0, 1.0), clampf(ratio.y, 0.0, 1.0))
