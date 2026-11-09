# story: e13s03
class_name PanPrimitive
extends RefCounted
## One-finger pan. Offset stays inside the world, and a long drag cancels a tap.

var offset: Vector2 = Vector2.ZERO
var world_size: Vector2 = Vector2(1920.0, 1080.0)
var view_size: Vector2 = Vector2(1920.0, 1080.0)
var tolerance: float = 24.0

var _last: Vector2 = Vector2.ZERO
var _travel: float = 0.0
var _active: bool = false


func drag_by(delta: Vector2) -> void:
	offset = _clamp(offset + delta)


func begin(point: Vector2) -> void:
	_active = true
	_last = point
	_travel = 0.0


func move_to(point: Vector2) -> void:
	if not _active:
		return
	var delta: Vector2 = point - _last
	_travel += delta.length()
	_last = point
	drag_by(delta)


func end_allows_tap() -> bool:
	var allow: bool = _active and _travel <= tolerance
	_active = false
	return allow


func follow(target: Vector2) -> void:
	offset = _clamp(target - view_size * 0.5)


func _clamp(value: Vector2) -> Vector2:
	var limit: Vector2 = Vector2(maxf(world_size.x - view_size.x, 0.0), maxf(world_size.y - view_size.y, 0.0))
	return Vector2(clampf(value.x, 0.0, limit.x), clampf(value.y, 0.0, limit.y))
