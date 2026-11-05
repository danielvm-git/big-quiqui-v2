# story: e02s01
extends Node
## The care cycle as an explicit machine (ADR-001 / EXPLICIT_STATE_MACHINES §2):
## IDLE -> FEED -> BATH -> DRESS -> PLAY -> SLEEP -> CELEBRATE -> IDLE, where
## every step may legally bail back to IDLE (a detour never soft-locks the hub).
##
## Detour guard: entering CELEBRATE pays the cycle reward (+5 coins, +1 ticket)
## exactly once per cycle id, so leaving CELEBRATE to IDLE by any path keeps
## the reward and closes the cycle.

signal loop_state_changed(from_state: String, to_state: String)

const STATE_IDLE: String = "IDLE"
const STATE_FEED: String = "FEED"
const STATE_BATH: String = "BATH"
const STATE_DRESS: String = "DRESS"
const STATE_PLAY: String = "PLAY"
const STATE_SLEEP: String = "SLEEP"
const STATE_CELEBRATE: String = "CELEBRATE"

const LEGAL_EDGES: Dictionary = {
	STATE_IDLE: [STATE_FEED],
	STATE_FEED: [STATE_BATH, STATE_IDLE],
	STATE_BATH: [STATE_DRESS, STATE_IDLE],
	STATE_DRESS: [STATE_PLAY, STATE_IDLE],
	STATE_PLAY: [STATE_SLEEP, STATE_IDLE],
	STATE_SLEEP: [STATE_CELEBRATE, STATE_IDLE],
	STATE_CELEBRATE: [STATE_IDLE],
}

## The five in-cycle care steps, in order. Care states carry no dwell limit:
## a child may take as long as they like inside a step.
const STEP_ORDER: Array[String] = [
	STATE_FEED,
	STATE_BATH,
	STATE_DRESS,
	STATE_PLAY,
	STATE_SLEEP,
]

var fsm: Fsm = null
var cycle_id: int = 0
var test_mode: bool = false

var _rewarded_cycle_id: int = -1


func _ready() -> void:
	_build_fsm()


## Enters the first care step. Only IDLE -> FEED is legal; every other call is
## rejected by the FSM's edge table.
func begin_step(step: String) -> bool:
	var started: bool = fsm.transition_to(step)
	if started:
		_emit("care.begin", {"step": step.to_lower()})
	return started


## Completes the step the caller expects to be in, using transition_from so a
## duplicate (stale) call after the transition already happened returns false.
func complete_step(expected_state: String) -> bool:
	var next_state: String = _successor(expected_state)
	if next_state.is_empty():
		return false
	var completed: bool = fsm.transition_from(expected_state, next_state)
	if completed:
		_emit("care.complete", {"step": expected_state.to_lower(), "next": next_state.to_lower()})
	return completed


## Bails out of any step to IDLE (the detour path). A no-op when already IDLE.
func abandon_step() -> bool:
	if fsm.state == STATE_IDLE:
		return false
	var abandoned: bool = fsm.transition_to(STATE_IDLE)
	if abandoned:
		_emit("care.abandon", {"step": fsm.state.to_lower()})
	return abandoned


func state_id() -> String:
	return fsm.state


## How many of the five steps are done in the current cycle (0..5).
func completed_steps() -> int:
	var index: int = STEP_ORDER.find(fsm.state)
	if index >= 0:
		return index
	if fsm.state == STATE_CELEBRATE:
		return STEP_ORDER.size()
	return 0


## The step the child should be playing now ("" while celebrating).
func next_step() -> String:
	if fsm.state == STATE_CELEBRATE:
		return ""
	var done: int = completed_steps()
	if done >= STEP_ORDER.size():
		return ""
	return STEP_ORDER[done]


## TestReset seam. The manager writes nothing itself; ProgressManager owns the
## test-path redirect, so this only records the mode for diagnostics.
func set_test_mode(enabled: bool) -> void:
	test_mode = enabled


func reset() -> void:
	cycle_id = 0
	_rewarded_cycle_id = -1
	_build_fsm()


func _build_fsm() -> void:
	fsm = Fsm.new(STATE_IDLE, LEGAL_EDGES, {})
	fsm.transitioned.connect(_on_transitioned)


## Both invariants live on the transition itself, so every legal path into or
## out of CELEBRATE is covered, not just the ones the API methods take.
func _on_transitioned(from_state: String, to_state: String) -> void:
	loop_state_changed.emit(from_state, to_state)
	if to_state == STATE_CELEBRATE:
		_grant_cycle_reward()
	if from_state == STATE_CELEBRATE and to_state == STATE_IDLE:
		cycle_id += 1
		_emit("care.cycle_closed", {"cycle": cycle_id})


func _successor(state: String) -> String:
	var targets: Array = LEGAL_EDGES.get(state, [])
	for candidate: String in targets:
		if candidate != STATE_IDLE:
			return candidate
	if targets.has(STATE_IDLE):
		return STATE_IDLE
	return ""


## Pays +5 coins / +1 ticket through ProgressManager exactly once per cycle id.
## The ledger advances even if ProgressManager is unreachable so a late reward
## is never double-paid.
func _grant_cycle_reward() -> void:
	if _rewarded_cycle_id == cycle_id:
		return
	_rewarded_cycle_id = cycle_id
	var sink: Node = get_node_or_null("/root/ProgressManager")
	if sink != null and sink.has_method("complete_cycle"):
		sink.call("complete_cycle")
	_emit("care.reward", {"cycle": cycle_id})


func _emit(ev: String, data: Dictionary) -> void:
	var sink: Node = get_node_or_null("/root/Log")
	if sink != null and sink.has_method("event"):
		sink.call("event", ev, data)
