# story: e13s03
class_name PanPrimitive
extends RefCounted
## One-finger pan. Offset stays inside the world, and a long drag cancels a tap. One finger owns
## the gesture until it lifts. A press that starts on a tap target never pans: it only measures
## its travel, so a drag cancels the tap and nothing scrolls under it.

const IDLE: String = "IDLE"
const PANNING: String = "PANNING"
const HELD: String = "HELD"
const LEGAL_EDGES: Dictionary = {
	IDLE: [PANNING, HELD],
	PANNING: [IDLE],
	HELD: [IDLE],
}

var offset: Vector2 = Vector2.ZERO
var world_size: Vector2 = Vector2(1920.0, 1080.0)
var view_size: Vector2 = Vector2(1920.0, 1080.0)
var tolerance: float = 24.0

var _last: Vector2 = Vector2.ZERO
var _travel: float = 0.0
var _owner: int = -1
var _fsm: Fsm = Fsm.new(IDLE, LEGAL_EDGES)


func drag_by(delta: Vector2) -> void:
	offset = _clamp(offset + delta)


## Returns false when another finger already owns the gesture.
func begin(point: Vector2, index: int = 0, on_target: bool = false) -> bool:
	if _fsm.state != IDLE:
		return false
	_owner = index
	_last = point
	_travel = 0.0
	return _fsm.transition_to(HELD if on_target else PANNING)


func move_to(point: Vector2, index: int = 0) -> void:
	if _fsm.state == IDLE or index != _owner:
		return
	var delta: Vector2 = point - _last
	_travel += delta.length()
	_last = point
	if _fsm.state == PANNING:
		drag_by(-delta)  # the world follows the finger, so the camera goes the other way


## True only for the owner's lift, after a press on a target that moved less than the tolerance.
func end_allows_tap(index: int = 0) -> bool:
	if _fsm.state == IDLE or index != _owner:
		return false
	var allow: bool = _fsm.state == HELD and _travel <= tolerance
	_owner = -1
	_fsm.transition_to(IDLE)
	return allow


func state_id() -> String:
	return _fsm.state


func follow(target: Vector2) -> void:
	offset = _clamp(target - view_size * 0.5)


func _clamp(value: Vector2) -> Vector2:
	var limit: Vector2 = Vector2(maxf(world_size.x - view_size.x, 0.0), maxf(world_size.y - view_size.y, 0.0))
	return Vector2(clampf(value.x, 0.0, limit.x), clampf(value.y, 0.0, limit.y))
