# story: e03s01
# story: e08s02
# story: e09s02
class_name TouchDraggable
extends Control
## The one drag surface (ADR-004): a prop picked up by one finger, which is either
## consumed on `drop_target` or flies back to its place.
##
## Godot hands `_gui_input` positions local to this control, so they are converted
## back per event: the control itself moves during a drag.
##
## `CONSUME_ON_DROP` is the eat/apply gesture (e03). `CONTINUOUS_SCRUB` is the e04
## gesture, whose hull state `ScrubGesture` owns. `SNAP_TO_SLOT` is e05: drop it on the
## character and it *replaces* what is in that slot, then flies home. `FREE_PLACEMENT`
## keeps the prop where it lands inside `placement_area` and reports that ratio (e09).

signal drag_started
signal drag_moved(global_point: Vector2)
signal drag_ended
signal consumed
## CONTINUOUS_SCRUB only, and only while the finger is inside the hull.
signal scrubbed(global_point: Vector2)
## SNAP_TO_SLOT only, and only when the drop lands on the target.
signal snapped(slot: String, id: String)
## FREE_PLACEMENT only, and only when the drop lands inside `placement_area`.
signal placed(normalized: Vector2)

enum Mode { CONSUME_ON_DROP, CONTINUOUS_SCRUB, SNAP_TO_SLOT, FREE_PLACEMENT }

const MIN_HIT_SIZE: Vector2 = Vector2(120.0, 120.0)
const RETURN_SEC: float = 0.25

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
## SNAP_TO_SLOT target and payload: what this item puts on, and into which slot.
var snap_target: Control = null
var snap_margin: float = 0.0
## FREE_PLACEMENT destination: the room the piece is dropped into.
var placement_area: Control = null
var payload_slot: String = ""
var payload_id: String = ""
## Grows the target rect, in canvas px.
var drop_margin: float = 0.0
var enabled: bool = true
## Test seam: when true, `_process` does nothing and only `advance()` runs.
var manual_step: bool = false
var fsm: Fsm = null

var _owner_touch_index: int = TouchDraggableStates.MOUSE_INDEX
var _grab_offset: Vector2 = Vector2.ZERO
var _rest_position: Vector2 = Vector2.ZERO
var _return_from: Vector2 = Vector2.ZERO
var _return_elapsed: float = 0.0
var _scrub: ScrubGesture = ScrubGesture.new()


func _init() -> void:
	fsm = Fsm.new(TouchDraggableStates.STATE_REST, TouchDraggableStates.LEGAL_EDGES, TouchDraggableStates.MAX_DWELL_SEC)


func _ready() -> void:
	custom_minimum_size = custom_minimum_size.max(MIN_HIT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	size = size.max(MIN_HIT_SIZE)
	_rest_position = position


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func _exit_tree() -> void:
	_stop_loop()
	if _holder != self:
		return
	_holder = null
	fsm.transition_to(TouchDraggableStates.STATE_REST)
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
			_on_contact(TouchDraggableStates.MOUSE_INDEX, button.pressed, button.position)
	elif event is InputEventMouseMotion:
		_on_motion(TouchDraggableStates.MOUSE_INDEX, (event as InputEventMouseMotion).position)


func advance(delta: float) -> void:
	if fsm.state != TouchDraggableStates.STATE_RETURNING:
		return
	_return_elapsed += delta
	var progress: float = minf(_return_elapsed / RETURN_SEC, 1.0)
	position = _return_from.lerp(_rest_position, progress)
	if progress >= 1.0 or fsm.check_dwell():
		position = _rest_position
		fsm.transition_from(TouchDraggableStates.STATE_RETURNING, TouchDraggableStates.STATE_REST)


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
	# `enabled` gates only the press: a held prop must finish, or the lock wedges.
	if not enabled or _holder != null:
		return
	if mode == Mode.CONTINUOUS_SCRUB:
		_press_scrub(index)
		return
	if not fsm.can_transition_to(TouchDraggableStates.STATE_DRAGGING):
		return
	if fsm.state == TouchDraggableStates.STATE_REST:
		_rest_position = position
	fsm.transition_to(TouchDraggableStates.STATE_DRAGGING)
	_holder = self
	_owner_touch_index = index
	_grab_offset = _to_global(local_point) - global_position
	drag_started.emit()
	_emit("drag.start")


## A scrub never moves the prop: the finger moves, the sponge stays under it.
func _press_scrub(index: int) -> void:
	if not fsm.can_transition_to(TouchDraggableStates.STATE_SCRUBBING):
		return
	fsm.transition_to(TouchDraggableStates.STATE_SCRUBBING)
	_holder = self
	_owner_touch_index = index
	_scrub.target = scrub_target
	_scrub.loop_stream = scrub_loop_stream
	_scrub.begin(self)
	drag_started.emit()
	_emit("scrub.start", {"hull": _scrub.hull_points().size()})


func _on_motion(index: int, local_point: Vector2) -> void:
	if not _owns(index):
		return
	var point: Vector2 = _to_global(local_point)
	if fsm.state == TouchDraggableStates.STATE_SCRUBBING:
		_scrub_move(point)
		return
	global_position = point - _grab_offset
	drag_moved.emit(point)


## Only points inside the hull count; leaving her body and coming back resumes.
func _scrub_move(point: Vector2) -> void:
	if _scrub.consume(point):
		scrubbed.emit(point)


func _drop(point: Vector2, cancelled: bool) -> void:
	_holder = null
	if fsm.state == TouchDraggableStates.STATE_SCRUBBING:
		_end_scrub()
		return
	if not cancelled and mode == Mode.CONSUME_ON_DROP and _rect_of(drop_target, drop_margin).has_point(point):
		_consume()
		return
	if not cancelled and mode == Mode.SNAP_TO_SLOT and _rect_of(snap_target, snap_margin).has_point(point):
		_snap()
		return
	if not cancelled and _place(point):
		return
	_begin_return()
	_emit("drag.drop", {"outcome": "returned"})


func _end_scrub() -> void:
	_stop_loop()
	fsm.transition_to(TouchDraggableStates.STATE_REST)
	drag_ended.emit()
	_emit("scrub.end", {"scrubbed": _scrub.points})


## Scene changes and resets call this: release the shared owner, stop the loop and
## return to rest, so an interrupted gesture can never wedge the next one (T-E04-04).
func abort() -> void:
	if fsm.state != TouchDraggableStates.STATE_SCRUBBING:
		_stop_loop()
		return
	_stop_loop()
	fsm.transition_to(TouchDraggableStates.STATE_ABORTED)
	fsm.transition_to(TouchDraggableStates.STATE_REST)
	_holder = null
	drag_ended.emit()
	_emit("scrub.end", {"scrubbed": _scrub.points, "aborted": true})


func scrub_points_seen() -> int:
	return _scrub.points


func is_scrub_loop_playing() -> bool:
	return _scrub.is_playing()


func scrub_loop_player_count() -> int:
	return _scrub.loop_player_count()


func _stop_loop() -> void:
	_scrub.stop()


func _consume() -> void:
	fsm.transition_to(TouchDraggableStates.STATE_CONSUMED)
	drag_ended.emit()
	_emit("drag.drop", {"outcome": "consumed"})
	consumed.emit()
	_emit("drag.consume")


## The item flies home afterwards: the wardrobe keeps its contents, the character
## takes the look.
func _snap() -> void:
	_begin_return()
	_emit("drag.drop", {"outcome": "snapped"})
	snapped.emit(payload_slot, payload_id)


func _begin_return() -> void:
	fsm.transition_to(TouchDraggableStates.STATE_RETURNING)
	_return_from = position
	_return_elapsed = 0.0
	drag_ended.emit()


func _owns(index: int) -> bool:
	return _holder == self and index == _owner_touch_index


## The target's rect on the canvas, grown by `margin`: one owner for every mode.
func _rect_of(control: Variant, margin: float) -> Rect2:
	return TouchDraggableGeom.rect_of(control, margin, TouchDraggableStates.NO_RECT)


## FREE_PLACEMENT: the piece stays where she let go and reports the room ratio (e09).
func _place(point: Vector2) -> bool:
	if mode != Mode.FREE_PLACEMENT or not _rect_of(placement_area, 0.0).has_point(point):
		return false
	fsm.transition_to(TouchDraggableStates.STATE_REST)
	drag_ended.emit()
	_emit("drag.drop", {"outcome": "placed"})
	placed.emit(normalized_of(get_global_rect().get_center()))
	return true


func normalized_of(global_point: Vector2) -> Vector2:
	return TouchDraggableGeom.normalized_of(global_point, placement_area, TouchDraggableStates.NO_RECT)


func _to_global(local_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas() * local_point


func _emit(ev: String, extra: Dictionary = {}) -> void:
	LogSink.emit_from(self, ev, extra.merged({"item": name.to_lower()}))
