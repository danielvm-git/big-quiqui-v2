# story: e01s04
class_name TapButton
extends Control
## The only tap surface in the game (ADR-004): fires exactly once per finger tap,
## never twice from the echo Godot synthesizes for the other input kind
## (`emulate_mouse_from_touch` and `emulate_touch_from_mouse` mark it `device == -1`).
##
## Squash-and-stretch happens on an inner `Visual` child so the button's own
## layout rect never moves — the hit target stays 120×120 for GeometryOracle
## while the art pops.

signal tapped

const MIN_HIT_SIZE: Vector2 = Vector2(120.0, 120.0)
## DESIGN §4.4 spring, owned by `SquashSpring` and shared with `QuiQuiRig`.
const SQUASH_STEPS: Array[Vector2] = SquashSpring.STEPS

var visual: Control = null
var enabled: bool = true
## Test seam: when true, `_process` does nothing and only `advance()` runs.
var manual_step: bool = false

var taps: int = 0

var _spring: SquashSpring = SquashSpring.new()


func _ready() -> void:
	custom_minimum_size = MIN_HIT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	if size.x < MIN_HIT_SIZE.x or size.y < MIN_HIT_SIZE.y:
		size = MIN_HIT_SIZE
	if visual == null:
		visual = get_node_or_null("Visual") as Control
	if visual == null:
		visual = Control.new()
		visual.name = "Visual"
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(visual)


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	# Device -1 is an echo in either direction: a mouse from a touch, or a touch from
	# a mouse. The real event reports its own device and is the one legitimate tap.
	if event.device == -1:
		return
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			_activate()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_activate()


## Programmatic press: same effect as a tap, used by scenes and tests.
func press() -> void:
	if enabled:
		_activate()


func is_squashing() -> bool:
	return _spring.is_running()


func advance(delta: float) -> void:
	if not _spring.is_running():
		return
	_spring.advance(delta)
	_apply_scale(_spring.scale)


func reset() -> void:
	taps = 0
	_spring.stop()
	_apply_scale(Vector2.ONE)


func _activate() -> void:
	taps += 1
	_spring.start()
	_apply_scale(_spring.scale)
	tapped.emit()
	_emit("ui.tap", {"widget": name.to_lower()})


func _apply_scale(value: Vector2) -> void:
	if visual != null:
		visual.scale = value
		visual.pivot_offset = size * 0.5


func _emit(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
