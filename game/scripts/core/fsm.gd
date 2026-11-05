# story: e01s01
class_name Fsm
extends RefCounted
## Table-driven finite state machine (ADR-001).
##
## Transitions are declared as data, never as boolean flag clusters:
##   legal_edges   { "IDLE": ["FEED", "BATH"], ... }
##   max_dwell_sec { "FADING_OUT": 2.0, ... }
##
## The machine is pure: it emits signals and stores nothing about the outside
## world. Telemetry is forwarded to the `Log` autoload when one is present, so a
## unit test needs no autoload and the game gets JSONL for free.

signal transitioned(from_state: String, to_state: String)
signal rejected(from_state: String, to_state: String, reason: String)
signal dwell_timeout(state: String)

const REASON_ILLEGAL: String = "illegal_transition"
const REASON_STALE: String = "stale_expected_state"

var state: String = ""
var legal_edges: Dictionary = {}
var max_dwell_sec: Dictionary = {}

var _now: Callable = Callable()
var _state_since_ms: int = 0
var _timed_out: Dictionary = {}
var _log_sink: Object = null
var _log_resolved: bool = false


func _init(
	initial_state: String = "",
	edges: Dictionary = {},
	dwell: Dictionary = {},
	clock: Callable = Callable(),
) -> void:
	legal_edges = edges
	max_dwell_sec = dwell
	if clock.is_valid():
		_now = clock
	state = initial_state
	_state_since_ms = _now_ms()
	_timed_out[state] = false


## Moves to `next_state` when the edge is declared. Returns true when the state changed.
func transition_to(next_state: String) -> bool:
	var previous: String = state
	if next_state == previous:
		return false
	if not can_transition_to(next_state):
		_emit(
			"fsm.illegal_transition",
			{
				"from_state": _id(previous),
				"to_state": _id(next_state),
			}
		)
		rejected.emit(previous, next_state, REASON_ILLEGAL)
		return false
	return _apply(previous, next_state)


## Moves to `next_state` only when the machine is still in `expected_state`.
## Use after an `await`: the world may have moved on while the coroutine waited.
func transition_from(expected_state: String, next_state: String) -> bool:
	if state != expected_state:
		_emit(
			"fsm.stale_transition",
			{
				"expected": _id(expected_state),
				"actual": _id(state),
				"to_state": _id(next_state),
			}
		)
		rejected.emit(state, next_state, REASON_STALE)
		return false
	return transition_to(next_state)


func can_transition_to(next_state: String) -> bool:
	if next_state == state:
		return false
	var edges: Variant = legal_edges.get(state, [])
	if not edges is Array:
		return false
	return (edges as Array).has(next_state)


func elapsed_sec() -> float:
	return float(_now_ms() - _state_since_ms) / 1000.0


## Fires `dwell_timeout` once per visit to a state whose max dwell was exceeded.
func check_dwell() -> bool:
	if not max_dwell_sec.has(state):
		return false
	if bool(_timed_out.get(state, false)):
		return false
	var limit: float = float(max_dwell_sec[state])
	if elapsed_sec() < limit:
		return false
	_timed_out[state] = true
	_emit("fsm.dwell_timeout", {"state": _id(state), "limit_sec": int(limit * 1000)})
	dwell_timeout.emit(state)
	return true


func reset(initial_state: String = "") -> void:
	state = initial_state
	_state_since_ms = _now_ms()
	_timed_out.clear()
	_timed_out[state] = false


func _apply(previous: String, next_state: String) -> bool:
	state = next_state
	_state_since_ms = _now_ms()
	_timed_out[next_state] = false
	_emit("fsm.transition", {"from_state": _id(previous), "to_state": _id(next_state)})
	transitioned.emit(previous, next_state)
	return true


func _now_ms() -> int:
	if _now.is_valid():
		return int(_now.call())
	return Time.get_ticks_msec()


## Values reach the diary only in id form; anything else would fail the PII audit.
func _id(value: String) -> String:
	var lowered: String = value.strip_edges().to_lower()
	if lowered.is_empty():
		return "none"
	if lowered.length() > 64:
		lowered = lowered.substr(0, 64)
	return lowered


## Optional coupling: the game registers `Log` as an autoload, a unit test does not.
func _emit(ev: String, data: Dictionary) -> void:
	if not _log_resolved:
		_log_resolved = true
		if Engine.get_main_loop() is SceneTree:
			_log_sink = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Log")
	if _log_sink != null and _log_sink.has_method("event"):
		_log_sink.call("event", ev, data)
