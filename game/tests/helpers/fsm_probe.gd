# story: e01s01
class_name FsmProbe
extends RefCounted
## Records what an `Fsm` actually did, so a test asserts behaviour instead of
## trusting the machine's own opinion (ADR-001 / TEST_PLAN §1.2).

const MAX_HISTORY: int = 64

var transitions: Array[String] = []
var rejections: Array[Dictionary] = []
var timeouts: Array[String] = []

var _fsm: Fsm = null


func attach(fsm: Fsm) -> FsmProbe:
	if _fsm != null:
		detach()
	_fsm = fsm
	_fsm.transitioned.connect(_on_transitioned)
	_fsm.rejected.connect(_on_rejected)
	_fsm.dwell_timeout.connect(_on_timeout)
	return self


func detach() -> void:
	if _fsm == null:
		return
	if _fsm.transitioned.is_connected(_on_transitioned):
		_fsm.transitioned.disconnect(_on_transitioned)
	if _fsm.rejected.is_connected(_on_rejected):
		_fsm.rejected.disconnect(_on_rejected)
	if _fsm.dwell_timeout.is_connected(_on_timeout):
		_fsm.dwell_timeout.disconnect(_on_timeout)
	_fsm = null


func is_clean() -> bool:
	return rejections.is_empty() and timeouts.is_empty()


func transition_count() -> int:
	return transitions.size()


func last_transition() -> String:
	return transitions.back() if not transitions.is_empty() else ""


func summary() -> String:
	var parts: Array[String] = [
		"transitions=%d" % transitions.size(),
		"rejections=%d" % rejections.size(),
		"timeouts=%d" % timeouts.size(),
	]
	if not rejections.is_empty():
		parts.append("first_rejection=%s" % rejections[0].get("reason", "?"))
	if not timeouts.is_empty():
		parts.append("first_timeout=%s" % timeouts[0])
	return " ".join(parts)


func _on_transitioned(from_state: String, to_state: String) -> void:
	_push(transitions, "%s->%s" % [from_state, to_state])


func _on_rejected(from_state: String, to_state: String, reason: String) -> void:
	_push(rejections, {"from": from_state, "to": to_state, "reason": reason})


func _on_timeout(state: String) -> void:
	_push(timeouts, state)


func _push(into: Array, value: Variant) -> void:
	into.append(value)
	if into.size() > MAX_HISTORY:
		into.pop_front()
