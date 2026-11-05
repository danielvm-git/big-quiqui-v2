# story: e01s04
class_name SquashSpring
extends RefCounted
## DESIGN §4.4 squash-and-stretch, shared by `TapButton` and `QuiQuiRig`:
## 1.14/0.88 (70 ms) → 0.94/1.07 (90 ms) → 1/1 (110 ms).
##
## Frame-drop safe: one `advance()` may cross several keyframes, so a long frame
## can never leave the spring stuck on an intermediate pose. Pure state, no node
## knowledge — the owner decides which transform it drives.

const STEPS: Array[Vector2] = [Vector2(1.14, 0.88), Vector2(0.94, 1.07), Vector2.ONE]
const STEP_SEC: Array[float] = [0.07, 0.09, 0.11]

var scale: Vector2 = Vector2.ONE
var step: int = -1

var _elapsed: float = 0.0


func is_running() -> bool:
	return step >= 0


func start() -> void:
	step = 0
	_elapsed = 0.0
	scale = STEPS[0]


func advance(delta: float) -> void:
	var remaining: float = maxf(delta, 0.0)
	while step >= 0 and remaining > 0.0:
		var limit: float = STEP_SEC[step]
		if _elapsed + remaining < limit:
			_elapsed += remaining
			return
		remaining -= limit - _elapsed
		_elapsed = 0.0
		step += 1
		if step >= STEPS.size():
			stop()
			return
		scale = STEPS[step]


func stop() -> void:
	step = -1
	_elapsed = 0.0
	scale = Vector2.ONE
