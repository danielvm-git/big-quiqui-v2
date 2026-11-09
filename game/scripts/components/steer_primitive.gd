# story: e13s08
class_name SteerPrimitive
extends RefCounted
## Free follows the finger. Lanes snap only when the finger lifts.

const STATE_IDLE: String = "IDLE"
const STATE_DRAGGING: String = "DRAGGING"
const LEGAL_EDGES: Dictionary = {
	STATE_IDLE: [STATE_DRAGGING],
	STATE_DRAGGING: [STATE_IDLE],
}

var mode: String = "lanes"
var bounds: Rect2 = Rect2(0.0, 0.0, 1920.0, 1080.0)
var lane_count: int = 3
var position: Vector2 = Vector2.ZERO

var _owner: int = -1
var _fsm: Fsm = Fsm.new(STATE_IDLE, LEGAL_EDGES)


## Returns false when another finger already owns the steering.
func begin(point: Vector2, index: int = 0) -> bool:
	if _fsm.state != STATE_IDLE:
		return false
	_owner = index
	position = _clamp(point)
	return _fsm.transition_to(STATE_DRAGGING)


func move_to(point: Vector2, index: int = 0) -> void:
	if _fsm.state != STATE_DRAGGING or index != _owner:
		return
	position = _clamp(point)


## Only the owner's lift ends the steering; in lanes it snaps to the nearest lane.
func release(index: int = 0) -> bool:
	if _fsm.state != STATE_DRAGGING or index != _owner:
		return false
	_owner = -1
	_fsm.transition_to(STATE_IDLE)
	if mode == "lanes":
		position.x = _nearest(position.x)
	return true


func dragging() -> bool:
	return _fsm.state == STATE_DRAGGING


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
