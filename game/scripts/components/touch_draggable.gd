# story: e03s01
class_name TouchDraggable
extends Control
## The one drag surface (ADR-004): a prop picked up by one finger, which is either
## consumed on `drop_target` or flies back to its place.
##
## Godot hands `_gui_input` positions local to this control, so they are converted
## back per event: the control itself moves during a drag.
##
## `CONSUME_ON_DROP` is the eat/apply gesture (e03). `CONTINUOUS_SCRUB` is the e04
## gesture: the prop does not move, the finger does, and each move inside the
## target's hull becomes a `scrubbed` point. `SNAP_TO_SLOT` and `FREE_PLACEMENT`
## still behave as if there were no target (e06, e09).

signal drag_started
signal drag_moved(global_point: Vector2)
signal drag_ended
signal consumed
## CONTINUOUS_SCRUB only, and only while the finger is inside the hull.
signal scrubbed(global_point: Vector2)

enum Mode { CONSUME_ON_DROP, CONTINUOUS_SCRUB, SNAP_TO_SLOT, FREE_PLACEMENT }

const MIN_HIT_SIZE: Vector2 = Vector2(120.0, 120.0)
const RETURN_SEC: float = 0.25

const STATE_REST: String = "REST"
const STATE_DRAGGING: String = "DRAGGING"
const STATE_RETURNING: String = "RETURNING"
const STATE_CONSUMED: String = "CONSUMED"
const STATE_SCRUBBING: String = "SCRUBBING"
const STATE_ABORTED: String = "ABORTED"
const LEGAL_EDGES: Dictionary = {
	STATE_REST: [STATE_DRAGGING, STATE_SCRUBBING],
	STATE_DRAGGING: [STATE_REST, STATE_RETURNING, STATE_CONSUMED],
	STATE_RETURNING: [STATE_REST, STATE_DRAGGING],
	STATE_SCRUBBING: [STATE_REST, STATE_ABORTED],
	STATE_ABORTED: [STATE_REST],
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
## CONTINUOUS_SCRUB target: any Control exposing `scrub_hull_global()`. Duck-typed so
## the component never depends on `QuiQuiRig`.
var scrub_target: Control = null
## Optional loop that owns exactly one SFX channel for the length of the gesture
## (T-E04-05). Null means silence.
var scrub_loop_stream: AudioStream = null
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
var _scrub_count: int = 0
var _loop_player: AudioStreamPlayer = null


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
	_stop_loop()
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
		_on_contact(touch.index, touch.pressed, touch.position, touch.canceled)
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


## A cancelled touch is the system taking the finger back, not the child letting
## go, so it flies home even when the finger was over the target.
func _on_contact(index: int, pressed: bool, local_point: Vector2, cancelled: bool = false) -> void:
	if pressed:
		_press(index, local_point)
	elif _owns(index):
		_drop(_to_global(local_point), cancelled)


func _press(index: int, local_point: Vector2) -> void:
	# `enabled` gates only the press: a held prop must still finish its gesture,
	# or the lock would wedge.
	if not enabled or _holder != null:
		return
	if mode == Mode.CONTINUOUS_SCRUB:
		_press_scrub(index, local_point)
		return
	if not fsm.can_transition_to(STATE_DRAGGING):
		return
	if fsm.state == STATE_REST:
		_rest_position = position
	fsm.transition_to(STATE_DRAGGING)
	_holder = self
	_owner_touch_index = index
	_grab_offset = _to_global(local_point) - global_position
	drag_started.emit()
	_emit("drag.start")


## A scrub never moves the prop: the finger moves, the sponge stays under it.
func _press_scrub(index: int, _local_point: Vector2) -> void:
	if not fsm.can_transition_to(STATE_SCRUBBING):
		return
	fsm.transition_to(STATE_SCRUBBING)
	_holder = self
	_owner_touch_index = index
	_scrub_count = 0
	_start_loop()
	drag_started.emit()
	_emit("scrub.start", {"hull": _hull().size()})


func _on_motion(index: int, local_point: Vector2) -> void:
	if not _owns(index):
		return
	var point: Vector2 = _to_global(local_point)
	if fsm.state == STATE_SCRUBBING:
		_scrub_move(point)
		return
	global_position = point - _grab_offset
	drag_moved.emit(point)


## Only points inside the hull count; a finger that leaves her body and comes back
## resumes scrubbing without a new gesture.
func _scrub_move(point: Vector2) -> void:
	var hull: PackedVector2Array = _hull()
	if hull.size() < 3 or not Geometry2D.is_point_in_polygon(point, hull):
		return
	_scrub_count += 1
	scrubbed.emit(point)


func _drop(point: Vector2, cancelled: bool) -> void:
	_holder = null
	if fsm.state == STATE_SCRUBBING:
		_stop_loop()
		fsm.transition_to(STATE_REST)
		drag_ended.emit()
		_emit("scrub.end", {"scrubbed": _scrub_count})
		return
	if not cancelled and _is_on_target(point):
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


## Scene changes and stage resets call this: it releases the shared owner, stops the
## loop and returns to rest, so an interrupted gesture can never wedge the next one
## (T-E04-04).
func abort() -> void:
	if fsm.state != STATE_SCRUBBING:
		_stop_loop()
		return
	_stop_loop()
	fsm.transition_to(STATE_ABORTED)
	fsm.transition_to(STATE_REST)
	_holder = null
	drag_ended.emit()
	_emit("scrub.end", {"scrubbed": _scrub_count, "aborted": true})


func scrub_points_seen() -> int:
	return _scrub_count


func is_scrub_loop_playing() -> bool:
	return _loop_player != null and _loop_player.playing


func scrub_loop_player_count() -> int:
	return 0 if _loop_player == null else 1


func _start_loop() -> void:
	if scrub_loop_stream == null:
		return
	if _loop_player == null:
		_loop_player = AudioStreamPlayer.new()
		_loop_player.name = "ScrubLoop"
		_loop_player.bus = "SFX"
		add_child(_loop_player)
	_loop_player.stream = scrub_loop_stream
	_loop_player.play()


func _stop_loop() -> void:
	if _loop_player != null and _loop_player.playing:
		_loop_player.stop()


## The target's hull, transformed at call time. A missing or non-polygon target
## means "no hull, no scrubs" rather than an error.
func _hull() -> PackedVector2Array:
	if scrub_target == null or not is_instance_valid(scrub_target) or not scrub_target.is_inside_tree():
		return PackedVector2Array()
	if not scrub_target.has_method("scrub_hull_global"):
		return PackedVector2Array()
	var hull: Variant = scrub_target.call("scrub_hull_global")
	return hull if hull is PackedVector2Array else PackedVector2Array()


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
