# story: e02s01
# story: e13s05
extends Node
## The care cycle as an explicit machine (ADR-001 / EXPLICIT_STATE_MACHINES §2):
## IDLE -> FEED -> BATH -> DRESS -> PLAY -> SLEEP -> CELEBRATE -> IDLE, where
## every step may legally bail back to IDLE (a detour never soft-locks the hub).
##
## Detour guard: entering CELEBRATE pays the cycle reward (+5 coins, +1 ticket)
## exactly once per cycle id, so leaving CELEBRATE to IDLE by any path keeps
## the reward and closes the cycle.

signal loop_state_changed(from_state: String, to_state: String)

## Vocabulary comes from `CareSteps`, so a rename cannot desynchronise the
## machine from the hub that reports on it.
const STATE_IDLE: String = CareSteps.IDLE
const STATE_FEED: String = CareSteps.FEED
const STATE_BATH: String = CareSteps.BATH
const STATE_DRESS: String = CareSteps.DRESS
const STATE_PLAY: String = CareSteps.PLAY
const STATE_SLEEP: String = CareSteps.SLEEP
const STATE_CELEBRATE: String = CareSteps.CELEBRATE

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
const STEP_ORDER: Array[String] = CareSteps.ORDER

var fsm: Fsm = null
var cycle_id: int = 0

var _rewarded_cycle_id: int = -1


func _ready() -> void:
	_build_fsm()


## Enters the first care step. Only IDLE -> FEED is legal; every other call is
## rejected by the FSM's edge table.
func begin_step(step: String) -> bool:
	if fsm == null:
		return false
	var started: bool = fsm.transition_to(step)
	if started:
		_emit("care.begin", {"step": step.to_lower()})
	return started


## Completes the step the caller expects to be in, using transition_from so a
## duplicate (stale) call after the transition already happened returns false.
func complete_step(expected_state: String) -> bool:
	if fsm == null:
		return false
	var next_state: String = _successor(expected_state)
	if next_state.is_empty():
		return false
	var completed: bool = fsm.transition_from(expected_state, next_state)
	if completed:
		_emit("care.complete", {"step": expected_state.to_lower(), "next": next_state.to_lower()})
	return completed


## Bails out of any step to IDLE (the detour path). A no-op when already IDLE.
func abandon_step() -> bool:
	if fsm == null or fsm.state == STATE_IDLE:
		return false
	# Capture the step before the transition: reading it afterwards always
	# logged "idle", which made the diary useless for exactly this event.
	var abandoned_step: String = fsm.state
	var abandoned: bool = fsm.transition_to(STATE_IDLE)
	if abandoned:
		_emit("care.abandon", {"step": abandoned_step.to_lower()})
	return abandoned


func state_id() -> String:
	return "" if fsm == null else fsm.state


## How many of the five steps are done in the current cycle (0..5).
func completed_steps() -> int:
	if fsm == null:
		return 0
	var index: int = STEP_ORDER.find(fsm.state)
	if index >= 0:
		return index
	if fsm.state == STATE_CELEBRATE:
		return STEP_ORDER.size()
	return 0


## The step the child should be playing now ("" while celebrating).
func next_step() -> String:
	if fsm == null:
		return ""
	if fsm.state == STATE_CELEBRATE:
		return ""
	var done: int = completed_steps()
	if done >= STEP_ORDER.size():
		return ""
	return STEP_ORDER[done]


## True when this cycle id already paid. The reward screen reads this on entry.
func reward_paid() -> bool:
	return _rewarded_cycle_id == cycle_id


## Pays through the same once-per-cycle ledger as entering CELEBRATE.
func collect_reward() -> bool:
	if reward_paid():
		return false
	_grant_cycle_reward()
	return true


## TestReset entry point. The reward ledger is in-memory and per-session, so a reset in play would
## replay a cycle; nothing but tests calls this (ADR-009).
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


## The successor of an in-cycle step. IDLE is not a step: completing it would
## silently begin the cycle, so it has no successor.
func _successor(state: String) -> String:
	if state == STATE_IDLE:
		return ""
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
	var sink: Node = _progress_manager()
	if sink != null and sink.has_method("complete_cycle"):
		sink.call("complete_cycle")
	_emit("care.reward", {"cycle": cycle_id})


## A manager that is not in the tree yet has no siblings: degrade, do not crash.
func _progress_manager() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/ProgressManager")


func _emit(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)


## A child can leave CELEBRATE by a detour (album, vila, home). Without this the loop
## stays in CELEBRATE and every care door refuses, so the hub is bricked (T-E07-05).
## Idempotent: closing twice is a no-op, and it never pays — the reward was granted on
## entry to CELEBRATE.
func close_celebrate_if_needed() -> bool:
	if fsm == null or fsm.state != STATE_CELEBRATE:
		return false
	if not fsm.transition_from(STATE_CELEBRATE, STATE_IDLE):
		return false
	_emit("care.celebrate_detour_closed", {"cycle": cycle_id})
	return true
