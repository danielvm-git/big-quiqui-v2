# story: e11s02
class_name MonkeyStream
extends RefCounted
## FZ-01 — a deterministic, device-legal three-finger touch stream.
##
## A real four-year-old presses three fingers, drags off-target and releases out of order.
## The stream is *data*: the same seed yields the same events, so any finding reproduces
## from the printed seed instead of from a video of the tablet.

const MAX_FINGERS: int = 3
const ECHO_DEVICE: int = -1


## One entry per event: `finger` (0..2), `kind` (`press`/`drag`/`release`), and `at`
## as a canvas ratio so the caller can aim it at any control rect.
static func finger_script(seed: int, count: int) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	var down: Array[bool] = [false, false, false]
	var script: Array[Dictionary] = []
	for _i: int in range(count):
		var finger: int = rng.randi_range(0, MAX_FINGERS - 1)
		var kind: String = _next_kind(rng, down[finger])
		down[finger] = kind != "release"
		(
			script
			. append(
				{
					"finger": finger,
					"kind": kind,
					"at": Vector2(rng.randf_range(0.02, 0.98), rng.randf_range(0.02, 0.98)),
				}
			)
		)
	return script


static func _next_kind(rng: RandomNumberGenerator, is_down: bool) -> String:
	if not is_down:
		return "press"
	return "release" if rng.randf() < 0.35 else "drag"


## The stream as Godot events, paired with the finger that owns them.
static func events(seed: int, count: int, canvas: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in finger_script(seed, count):
		out.append({"finger": entry["finger"], "event": _event(entry, canvas)})
	return out


static func _event(entry: Dictionary, canvas: Vector2) -> InputEvent:
	var point: Vector2 = Vector2(entry["at"] as Vector2) * canvas
	match str(entry["kind"]):
		"press":
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.index = int(entry["finger"])
			touch.position = point
			touch.pressed = true
			return touch
		"release":
			var up: InputEventScreenTouch = InputEventScreenTouch.new()
			up.index = int(entry["finger"])
			up.position = point
			up.pressed = false
			return up
		_:
			var drag: InputEventScreenDrag = InputEventScreenDrag.new()
			drag.index = int(entry["finger"])
			drag.position = point
			drag.relative = point * 0.01
			return drag


## The synthesized mouse a touch produces (`device == -1`), so a handler that forgets the
## filter fires twice under concurrency, not only under `TouchSim.tap_control`.
static func echo_of(event: InputEvent) -> InputEventMouse:
	if event is InputEventScreenTouch:
		var mouse: InputEventMouseButton = InputEventMouseButton.new()
		mouse.device = ECHO_DEVICE
		mouse.position = (event as InputEventScreenTouch).position
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = (event as InputEventScreenTouch).pressed
		return mouse
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.device = ECHO_DEVICE
	motion.position = (event as InputEventScreenDrag).position
	return motion
