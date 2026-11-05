# story: e03s01
class_name TouchDraggable
extends Control
## The one drag surface (ADR-004): a prop picked up by one finger, which is either
## consumed on `drop_target` or flies back to its place.
##
## Godot hands `_gui_input` positions local to this control, so they are converted
## back per event: the control itself moves during a drag. Only `CONSUME_ON_DROP` is
## built; the other modes behave as if there were no target (e04, e06, e09).

signal drag_started
signal drag_moved(global_point: Vector2)
signal drag_ended
signal consumed

enum Mode { CONSUME_ON_DROP, CONTINUOUS_SCRUB, SNAP_TO_SLOT, FREE_PLACEMENT }

const MIN_HIT_SIZE: Vector2 = Vector2(120.0, 120.0)
const RETURN_SEC: float = 0.25

const STATE_REST: String = "REST"
const STATE_DRAGGING: String = "DRAGGING"
const STATE_RETURNING: String = "RETURNING"
const STATE_CONSUMED: String = "CONSUMED"
const LEGAL_EDGES: Dictionary = {
	STATE_REST: [STATE_DRAGGING],
	STATE_DRAGGING: [STATE_REST, STATE_RETURNING, STATE_CONSUMED],
	STATE_RETURNING: [STATE_REST, STATE_DRAGGING],
	STATE_CONSUMED: [],
}
const MAX_DWELL_SEC: Dictionary = {STATE_RETURNING: 1.0}
## Stands in for a touch index when a real mouse holds the prop.
const MOUSE_INDEX: int = -1

## The single-finger lock: the one prop held in the whole game (T-E03-01).
static var _holder: TouchDraggable = null

var mode: Mode = Mode.CONSUME_ON_DROP
## Null means nothing can consume it.
var drop_target: Control = null
## Grows the target rect, in canvas px.
var drop_margin: float = 0.0
var enabled: bool = true
## Test seam: when true, `_process` does nothing and only `advance()` runs.
var manual_step: bool = false
var fsm: Fsm = null

var _owner_touch_index: int = MOUSE_INDEX
var _grab_offset: Vector2 = Vector2.ZERO
var _rest_position: Vector2 = Vector2.ZERO
var _return_from: Vector2 = Vector2.ZERO
var _return_elapsed: float = 0.0


func _init() -> void:
	fsm = Fsm.new(STATE_REST, LEGAL_EDGES, MAX_DWELL_SEC)


func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(MIN_HIT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	size = size.max(MIN_HIT_SIZE)


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func _exit_tree() -> void:
	if _holder != self:
		return
	_holder = null
	fsm.transition_to(STATE_REST)
	position = _rest_position
	drag_ended.emit()


func _gui_input(event: InputEvent) -> void:
	# The echo carries device -1. An emulated touch that does not is the same
	# gesture on another index, and the owner check below makes it harmless.
	if event.device == -1:
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		_on_contact(touch.index, touch.pressed, touch.position)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		_on_motion(drag.index, drag.position)
	elif event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			_on_contact(MOUSE_INDEX, button.pressed, button.position)
	elif event is InputEventMouseMotion:
		_on_motion(MOUSE_INDEX, (event as InputEventMouseMotion).position)


func advance(delta: float) -> void:
	if fsm.state != STATE_RETURNING:
		return
	_return_elapsed += delta
	var progress: float = minf(_return_elapsed / RETURN_SEC, 1.0)
	position = _return_from.lerp(_rest_position, progress)
	if progress >= 1.0 or fsm.check_dwell():
		position = _rest_position
		fsm.transition_from(STATE_RETURNING, STATE_REST)


func state_id() -> String:
	return fsm.state


func _on_contact(index: int, pressed: bool, local_point: Vector2) -> void:
	if pressed:
		_press(index, local_point)
	elif _owns(index):
		_drop(_to_global(local_point))


func _press(index: int, local_point: Vector2) -> void:
	# `enabled` gates only the press: a held prop must still finish its gesture,
	# or the lock would wedge.
	if not enabled or _holder != null or not fsm.can_transition_to(STATE_DRAGGING):
		return
	if fsm.state == STATE_REST:
		_rest_position = position
	fsm.transition_to(STATE_DRAGGING)
	_holder = self
	_owner_touch_index = index
	_grab_offset = _to_global(local_point) - global_position
	drag_started.emit()
	_emit("drag.start")


func _on_motion(index: int, local_point: Vector2) -> void:
	if not _owns(index):
		return
	var point: Vector2 = _to_global(local_point)
	global_position = point - _grab_offset
	drag_moved.emit(point)


func _drop(point: Vector2) -> void:
	_holder = null
	if _is_on_target(point):
		fsm.transition_to(STATE_CONSUMED)
		drag_ended.emit()
		_emit("drag.drop", {"outcome": "consumed"})
		consumed.emit()
		_emit("drag.consume")
		return
	fsm.transition_to(STATE_RETURNING)
	_return_from = position
	_return_elapsed = 0.0
	drag_ended.emit()
	_emit("drag.drop", {"outcome": "returned"})


func _owns(index: int) -> bool:
	return _holder == self and index == _owner_touch_index


func _is_on_target(point: Vector2) -> bool:
	if mode != Mode.CONSUME_ON_DROP:
		return false
	if not is_instance_valid(drop_target) or not drop_target.is_inside_tree():
		return false
	var rect: Rect2 = drop_target.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, drop_target.size)
	return rect.grow(drop_margin).has_point(point)


func _to_global(local_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * local_point


func _emit(ev: String, extra: Dictionary = {}) -> void:
	LogSink.emit_from(self, ev, extra.merged({"item": name.to_lower()}))
