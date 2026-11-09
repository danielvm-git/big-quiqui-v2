# story: e13s03
class_name PanPrimitive
extends RefCounted
## One-finger pan. Offset stays inside the world, and a long drag cancels a tap. One finger owns
## the gesture until it lifts. A press that starts on a tap target never pans: it only measures
## its travel, so a drag cancels the tap and nothing scrolls under it.

const STATE_IDLE: String = "IDLE"
const STATE_PANNING: String = "PANNING"
const STATE_HELD: String = "HELD"
## No state times out: the gesture belongs to the child's finger and lasts as long as it does.
const MAX_DWELL_SEC: Dictionary = {}
const LEGAL_EDGES: Dictionary = {
	STATE_IDLE: [STATE_PANNING, STATE_HELD],
	STATE_PANNING: [STATE_IDLE],
	STATE_HELD: [STATE_IDLE],
}

var offset: Vector2 = Vector2.ZERO
var world_size: Vector2 = Vector2(1920.0, 1080.0)
var view_size: Vector2 = Vector2(1920.0, 1080.0)
var tolerance: float = 24.0

var _last: Vector2 = Vector2.ZERO
var _travel: float = 0.0
var _owner: int = -1
var _fsm: Fsm = Fsm.new(STATE_IDLE, LEGAL_EDGES, MAX_DWELL_SEC)


func drag_by(delta: Vector2) -> void:
	offset = _clamp(offset + delta)


## Returns false when another finger already owns the gesture.
func begin(point: Vector2, index: int = 0, on_target: bool = false) -> bool:
	if _fsm.state != STATE_IDLE:
		return false
	_owner = index
	_last = point
	_travel = 0.0
	return _fsm.transition_to(STATE_HELD if on_target else STATE_PANNING)


func move_to(point: Vector2, index: int = 0) -> void:
	if _fsm.state == STATE_IDLE or index != _owner:
		return
	var delta: Vector2 = point - _last
	_travel += delta.length()
	_last = point
	if _fsm.state == STATE_PANNING:
		drag_by(-delta)  # the world follows the finger, so the camera goes the other way


## True only for the owner's lift, after a press on a target that moved less than the tolerance.
func end_allows_tap(index: int = 0) -> bool:
	if _fsm.state == STATE_IDLE or index != _owner:
		return false
	var allow: bool = _fsm.state == STATE_HELD and _travel <= tolerance
	_owner = -1
	_fsm.transition_to(STATE_IDLE)
	return allow


## True while `index` is the finger that owns the gesture.
func owns(index: int) -> bool:
	return _fsm.state != STATE_IDLE and index == _owner


func state_id() -> String:
	return _fsm.state


func follow(target: Vector2) -> void:
	offset = _clamp(target - view_size * 0.5)


func _clamp(value: Vector2) -> Vector2:
	var limit: Vector2 = Vector2(maxf(world_size.x - view_size.x, 0.0), maxf(world_size.y - view_size.y, 0.0))
	return Vector2(clampf(value.x, 0.0, limit.x), clampf(value.y, 0.0, limit.y))
