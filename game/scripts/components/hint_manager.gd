# story: e08s02
class_name HintManager
extends Node
## One hint at a time, with a cooldown between shows (FIX-02).

var manual_step: bool = false

var _queue: Array[Node] = []
var _current: Node = null
var _cooldown_sec: float = 0.0
var _cool_remaining: float = 0.0


func enqueue(hint: Node) -> void:
	if hint == null:
		return
	_queue.append(hint)


## Shows the front of the queue when not cooling down. Returns true when a hint owns the stage.
func try_show_next() -> bool:
	if _current != null:
		return true
	if _cool_remaining > 0.0:
		return false
	if _queue.is_empty():
		return false
	_current = _queue.pop_front() as Node
	if _current == null:
		return false
	_current.visible = true
	return true


func stop_current() -> void:
	if _current == null:
		return
	if _current.has_method("stop"):
		_current.call("stop")
	_current.visible = false
	_current = null


func begin_cooldown(sec: float) -> void:
	_cool_remaining = maxf(sec, 0.0)


func cooling_down() -> bool:
	return _cool_remaining > 0.0


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	if manual_step:
		return
	if _cool_remaining > 0.0:
		_cool_remaining = maxf(_cool_remaining - step, 0.0)
	if _current != null and _current.has_method("advance"):
		_current.call("advance", step)
		if _current.has_method("done") and bool(_current.call("done")):
			stop_current()
