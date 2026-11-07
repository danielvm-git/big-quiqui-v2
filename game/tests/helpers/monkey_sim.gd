# story: e11s02
class_name MonkeySim
extends RefCounted
## Three-finger concurrent touch noise for the monkey fuzz gate.

const EVENT_COUNT: int = 1000
const FINGER_COUNT: int = 3
const MONKEY_SEED: int = 110702

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func reset() -> void:
	_rng.seed = MONKEY_SEED


func touch_event_at(target: Control, global_pos: Vector2, finger: int, pressed: bool) -> InputEventScreenTouch:
	var ev: InputEventScreenTouch = InputEventScreenTouch.new()
	ev.position = target.get_global_transform_with_canvas().affine_inverse() * global_pos
	ev.pressed = pressed
	ev.index = finger
	return ev


func random_point_in(rect: Rect2) -> Vector2:
	var x: float = _rng.randf_range(rect.position.x, rect.position.x + rect.size.x)
	var y: float = _rng.randf_range(rect.position.y, rect.position.y + rect.size.y)
	return Vector2(x, y)


func next_finger() -> int:
	return _rng.randi_range(0, FINGER_COUNT - 1)
