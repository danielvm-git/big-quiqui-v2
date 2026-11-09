# story: e12s03
class_name StepRunner
extends RefCounted
## Table-driven room rhythm: LOAD through EXIT. Steps end on template progress, never on a timer.

const STATE_LOAD: String = "LOAD"
const STATE_INTRO: String = "INTRO"
const STATE_STEP: String = "STEP"
const STATE_STEP_DONE: String = "STEP_DONE"
const STATE_OUTRO: String = "OUTRO"
const STATE_EXIT: String = "EXIT"

const LEGAL_EDGES: Dictionary = {
	STATE_LOAD: [STATE_INTRO, STATE_EXIT],
	STATE_INTRO: [STATE_STEP, STATE_EXIT],
	STATE_STEP: [STATE_STEP_DONE, STATE_EXIT],
	STATE_STEP_DONE: [STATE_STEP, STATE_OUTRO, STATE_EXIT],
	STATE_OUTRO: [STATE_EXIT],
	STATE_EXIT: [],
}
const MAX_DWELL_SEC: Dictionary = {
	STATE_LOAD: 2.0,
	STATE_INTRO: 30.0,
	STATE_OUTRO: 2.0,
}

var fsm: Fsm = null
var manual_step: bool = false
var step_index: int = 0
var step_count: int = 0
var idle_sec: float = 0.0
var input_seen: bool = false

var _clock_ms: Callable = Callable()
var _template_progress: float = 0.0
var _home_penalty: bool = false
var _step_done_pending: bool = false


func _init(clock: Callable = Callable()) -> void:
	_clock_ms = clock
	fsm = Fsm.new(STATE_LOAD, LEGAL_EDGES, MAX_DWELL_SEC, _clock_ms)


func reset(step_total: int) -> void:
	step_count = maxi(step_total, 0)
	step_index = 0
	_template_progress = 0.0
	_home_penalty = false
	_step_done_pending = false
	idle_sec = 0.0
	input_seen = false
	fsm.reset(STATE_LOAD)


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_tick_idle(step)
	match fsm.state:
		STATE_LOAD:
			_advance_load(step)
		STATE_INTRO:
			_advance_intro(step)
		STATE_STEP:
			pass
		STATE_STEP_DONE:
			if _step_done_pending:
				_step_done_pending = false
				_advance_step_done()
		STATE_OUTRO:
			_advance_outro(step)
		STATE_EXIT:
			pass


func request_home() -> bool:
	_home_penalty = false
	return fsm.transition_to(STATE_EXIT)


func report_template_progress(value: float) -> void:
	if fsm.state != STATE_STEP:
		return
	_template_progress = clampf(value, 0.0, 1.0)
	if _template_progress >= 1.0:
		fsm.transition_to(STATE_STEP_DONE)
		_step_done_pending = true


func template_progress() -> float:
	return _template_progress


func home_penalty() -> bool:
	return _home_penalty


func note_input() -> void:
	input_seen = true
	idle_sec = 0.0


func _advance_load(_delta: float) -> void:
	if fsm.check_dwell() or fsm.elapsed_sec() >= 0.05:
		fsm.transition_to(STATE_INTRO)


func _advance_intro(_delta: float) -> void:
	if fsm.check_dwell():
		fsm.transition_to(STATE_STEP)
		_enter_step()


func finish_intro() -> void:
	if fsm.state != STATE_INTRO:
		return
	fsm.transition_to(STATE_STEP)
	_enter_step()


func _enter_step() -> void:
	_template_progress = 0.0
	idle_sec = 0.0
	input_seen = false


func _advance_step_done() -> void:
	step_index += 1
	if step_index >= step_count:
		fsm.transition_to(STATE_OUTRO)
		return
	fsm.transition_to(STATE_STEP)
	_enter_step()


func _advance_outro(_delta: float) -> void:
	if fsm.check_dwell() or fsm.elapsed_sec() >= 0.05:
		fsm.transition_to(STATE_EXIT)


func _tick_idle(delta: float) -> void:
	if fsm.state != STATE_STEP or input_seen:
		return
	idle_sec += delta


func _clock() -> int:
	if _clock_ms.is_valid():
		return int(_clock_ms.call())
	return Time.get_ticks_msec()
