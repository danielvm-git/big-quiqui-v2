# story: e13s08
class_name SteerPrimitive
extends RefCounted
## Free follows the finger. Lanes snap only when the finger lifts.

var mode: String = "lanes"
var bounds: Rect2 = Rect2(0.0, 0.0, 1920.0, 1080.0)
var lane_count: int = 3
var position: Vector2 = Vector2.ZERO

var _dragging: bool = false


func begin(point: Vector2) -> void:
	_dragging = true
	position = _clamp(point)


func move_to(point: Vector2) -> void:
	if not _dragging:
		return
	position = _clamp(point)


func release() -> void:
	_dragging = false
	if mode != "lanes":
		return
	position.x = _nearest(position.x)


func dragging() -> bool:
	return _dragging


func lane_center(index: int) -> float:
	var width: float = bounds.size.x / float(maxi(lane_count, 1))
	return bounds.position.x + width * (float(index) + 0.5)


func lane_index() -> int:
	var best: int = 0
	var best_dist: float = 100000.0
	for index: int in range(maxi(lane_count, 1)):
		var dist: float = absf(position.x - lane_center(index))
		if dist < best_dist:
			best = index
			best_dist = dist
	return best


func _clamp(point: Vector2) -> Vector2:
	return Vector2(clampf(point.x, bounds.position.x, bounds.end.x), clampf(point.y, bounds.position.y, bounds.end.y))


func _nearest(x: float) -> float:
	var best: float = lane_center(0)
	var best_dist: float = absf(x - best)
	for index: int in range(maxi(lane_count, 1)):
		var center: float = lane_center(index)
		var dist: float = absf(x - center)
		if dist < best_dist:
			best = center
			best_dist = dist
	return best
