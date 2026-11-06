# story: e01s01
class_name TouchSim
extends RefCounted
## Deterministic finger input (ADR-004).
##
## Godot synthesizes an `InputEventMouse` with `device == -1` for every touch when
## `input_devices/pointing/emulate_touch_from_mouse` is on. This helper pushes the
## touch *and* that echo, so a handler that forgets the filter fires twice and the
## test fails — the regression this project cares about most.

const DEFAULT_STEPS: int = 12


## The tap as data: press, optional synthesized mouse echo, release.
## Tests assert this list directly — Godot's headless viewport does not dispatch
## GUI input through `push_input` (verified), so the contract is proven on the
## event sequence and on the handler, not on the windowing layer.
static func tap_events(control: Control, with_mouse_echo: bool = true) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	var point: Vector2 = control.get_global_rect().get_center()
	events.append(_touch(point, true))
	if with_mouse_echo:
		events.append(_mouse(point, true))
		events.append(_mouse(point, false))
	events.append(_touch(point, false))
	return events


## One tap: press, optional synthesized mouse echo, release.
static func tap_control(control: Control, with_mouse_echo: bool = true) -> void:
	var viewport: Viewport = control.get_viewport()
	if viewport == null:
		return
	for event: InputEvent in tap_events(control, with_mouse_echo):
		viewport.push_input(event)


## The drag as data: press, motion steps, release.
static func drag_events(
	control: Control,
	target_global_pos: Vector2,
	steps: int = DEFAULT_STEPS,
	with_mouse_echo: bool = true,
) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	var total: int = maxi(steps, 1)
	var start: Vector2 = control.get_global_rect().get_center()
	events.append(_touch(start, true))
	if with_mouse_echo:
		events.append(_mouse(start, true))
	for step: int in range(1, total + 1):
		var point: Vector2 = start.lerp(target_global_pos, float(step) / float(total))
		events.append(_touch_drag(point))
		if with_mouse_echo:
			events.append(_mouse_motion(point))
	events.append(_touch(target_global_pos, false))
	if with_mouse_echo:
		events.append(_mouse(target_global_pos, false))
	return events


## A continuous drag from the control's centre to `target_global_pos`.
static func drag_control_to(
	control: Control,
	target_global_pos: Vector2,
	steps: int = DEFAULT_STEPS,
	with_mouse_echo: bool = true,
) -> void:
	var viewport: Viewport = control.get_viewport()
	if viewport == null:
		return
	for event: InputEvent in drag_events(control, target_global_pos, steps, with_mouse_echo):
		viewport.push_input(event)


## One real mouse click as the engine delivers it: for each button event,
## `emulate_touch_from_mouse` first sends a touch with device -1, then the real mouse
## event arrives with device 0.
static func mouse_click_events(control: Control) -> Array[InputEvent]:
	var point: Vector2 = control.get_global_rect().get_center()
	var events: Array[InputEvent] = [
		_touch(point, true, -1),
		_mouse(point, true, 0),
		_touch(point, false, -1),
		_mouse(point, false, 0),
	]
	return events


## The same pairing for a real mouse drag: motion also sends a device -1 screen drag.
static func mouse_drag_events(
	control: Control,
	target_global_pos: Vector2,
	steps: int = DEFAULT_STEPS,
) -> Array[InputEvent]:
	var start: Vector2 = control.get_global_rect().get_center()
	var events: Array[InputEvent] = [_touch(start, true, -1), _mouse(start, true, 0)]
	var total: int = maxi(steps, 1)
	for step: int in range(1, total + 1):
		var point: Vector2 = start.lerp(target_global_pos, float(step) / float(total))
		events.append(_touch_drag(point, -1))
		events.append(_mouse_motion(point, 0))
	events.append(_touch(target_global_pos, false, -1))
	events.append(_mouse(target_global_pos, false, 0))
	return events


## A copy of `event` with the local position GUI dispatch would give `control`.
## Call it at delivery time: the control moves during a drag.
static func gui_event(control: Control, event: InputEvent) -> InputEvent:
	return event.xformed_by(control.get_global_transform_with_canvas().affine_inverse())


static func _touch(point: Vector2, pressed: bool, device: int = 0) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.device = device
	event.index = 0
	event.position = point
	event.pressed = pressed
	return event


static func _touch_drag(point: Vector2, device: int = 0) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.device = device
	event.index = 0
	event.position = point
	event.relative = Vector2.ZERO
	return event


static func _mouse(point: Vector2, pressed: bool, device: int = -1) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = point
	event.global_position = point
	event.pressed = pressed
	# By default -1: the event Godot synthesized from the touch above.
	event.device = device
	return event


static func _mouse_motion(point: Vector2, device: int = -1) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = Vector2.ZERO
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.device = device
	return event
