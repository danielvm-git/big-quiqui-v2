# story: e01s02
# story: e12s02
# story: e14s05
extends Node
## Scene transitions as an explicit machine (ADR-001): IDLE → FADING_OUT →
## SWAPPING → FADING_IN → IDLE, with a 2.0 s watchdog and a 1-slot pending queue
## so rapid navigation is never dropped.
##
## Determinism: all progress is driven by `advance(delta)` from `_process`, never
## by tweens, so a test can step the machine without waiting real time.

signal scene_changed(path: String)
signal scene_requested(path: String, queued: bool)
signal transition_rejected(path: String, reason: String)
signal watchdog_recovered(state: String)

const STATE_IDLE: String = "IDLE"
const STATE_FADING_OUT: String = "FADING_OUT"
const STATE_SWAPPING: String = "SWAPPING"
const STATE_FADING_IN: String = "FADING_IN"

const REASON_SAME_SCENE: String = "same_scene"
const REASON_EMPTY_PATH: String = "empty_path"
const REASON_DEF_REJECTED: String = "def_rejected"
const SCENE_PLAYER_PATH: String = "res://scenes/scene_player.tscn"
## Home and celebration load through the player; detour logic keys off catalogue ids.
const CASA_PATH: String = SCENE_PLAYER_PATH
const CELEBRACAO_PATH: String = SCENE_PLAYER_PATH
const ID_HOME: String = "home"
const ID_CELEBRATION: String = "celebration"

const LEGAL_EDGES: Dictionary = {
	STATE_IDLE: [STATE_FADING_OUT],
	STATE_FADING_OUT: [STATE_SWAPPING],
	STATE_SWAPPING: [STATE_FADING_IN],
	STATE_FADING_IN: [STATE_IDLE],
}
# No state may outlive the watchdog; the FSM's own dwell timer is the recovery.
const MAX_DWELL_SEC: Dictionary = {
	STATE_FADING_OUT: 2.0,
	STATE_SWAPPING: 2.0,
	STATE_FADING_IN: 2.0,
}

var fsm: Fsm = null
## Test seam: when true, `_process` does nothing and only `advance()` steps the
## machine, so a test's timeline is the only timeline.
var manual_step: bool = false
var fade_duration_sec: float = 0.4
var pending_scene: String = ""
var current_scene: String = ""
var _def_nav: SceneManagerDefNav = SceneManagerDefNav.new()
## Injected so tests never swap the scene under GUT; the game sets `change_scene`.
var loader: Callable = Callable()
## Test seam for the production swap itself: when set, it is called instead of
## `change_scene_to_file` (same injection discipline as `loader`).
var production_swap: Callable = Callable()
## The path of the last production swap — test observable (stays "" under GUT).
var production_swap_path: String = ""
## TestReset seam: when true, the manager never touches the real scene tree,
## so a GUT run can complete a transition without swapping the runner scene.
var test_mode: bool = false

var _progress: float = 0.0
## Test-stepped clock: the FSM's dwell watchdog reads this instead of wall time,
## so `advance(2.1)` in a test means the same thing as 2.1 s in the game.
var _clock_ms: int = 0
var _curtain: SceneCurtain = SceneCurtain.new()


func _ready() -> void:
	fsm = Fsm.new(STATE_IDLE, LEGAL_EDGES, MAX_DWELL_SEC, Callable(self, "_clock"))
	_curtain.build(self)


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


## Parks a request that cannot start now: an identical pending path, or a machine that
## is mid-transition. Both are normal, not errors.
func _park(path: String) -> bool:
	if path == pending_scene:
		scene_requested.emit(path, true)
		return true
	if fsm.state != STATE_IDLE:
		pending_scene = path
		_def_nav.clear_pending_def()
		scene_requested.emit(path, true)
		return true
	return false


## Requests a scene. Returns true when the transition started immediately,
## false when it was parked in the single pending slot.
func request_def(scene_id: String) -> bool:
	if not Ids.is_valid(scene_id):
		reject(scene_id, REASON_DEF_REJECTED)
		return false
	var def: SceneDef = SceneManagerDefNav.load_def(scene_id)
	if def == null:
		reject(scene_id, REASON_DEF_REJECTED)
		return false
	if scene_id == _def_nav.current_def_id and current_scene == SCENE_PLAYER_PATH:
		reject(scene_id, REASON_SAME_SCENE)
		return false
	CareLoopDetour.close_unless(self, SceneManagerDefNav.celebrate_may_continue(scene_id, ID_HOME, ID_CELEBRATION))
	var parked_path: String = _def_nav.park_def(scene_id, def, fsm.state == STATE_IDLE, SCENE_PLAYER_PATH)
	if not parked_path.is_empty():
		pending_scene = parked_path
		var queued: bool = fsm.state != STATE_IDLE
		scene_requested.emit(SCENE_PLAYER_PATH, queued)
		return not queued
	_def_nav.stage(scene_id, def)
	_start(SCENE_PLAYER_PATH)
	scene_requested.emit(SCENE_PLAYER_PATH, false)
	return true


func consume_def() -> SceneDef:
	return _def_nav.consume_def()


func scene_slug_for_id(scene_id: String) -> String:
	return SceneManagerDefNav.scene_slug_for_id(scene_id)


func request_scene(path: String) -> bool:
	if path.strip_edges().is_empty():
		reject(path, REASON_EMPTY_PATH)
		return false
	# Also while busy: a double tap must not queue a reload of the scene in flight.
	if path == current_scene:
		reject(path, REASON_SAME_SCENE)
		return false
	# After validation: a request that is refused is not a detour, so it must not close
	# the cycle (e07 post-epic, review B consider 10).
	CareLoopDetour.close_unless(self, path == CASA_PATH or path == CELEBRACAO_PATH)
	if _park(path):
		return false
	_start(path)
	scene_requested.emit(path, false)
	return true


## Steps the machine. Returns the state after the step.
func advance(delta: float) -> String:
	_clock_ms += int(maxf(delta, 0.0) * 1000.0)
	if fsm.state == STATE_IDLE:
		return fsm.state
	if fsm.check_dwell():
		recover_from_watchdog()
		return fsm.state
	_progress += delta
	var ratio: float = 1.0 if fade_duration_sec <= 0.0 else clampf(_progress / fade_duration_sec, 0.0, 1.0)
	_step_active(ratio)
	return fsm.state


func _step_active(ratio: float) -> void:
	match fsm.state:
		STATE_FADING_OUT:
			_set_curtain_alpha(ratio)
			if ratio >= 1.0:
				_enter_swapping()
		STATE_SWAPPING:
			_load_pending_or_current()
		STATE_FADING_IN:
			_set_curtain_alpha(1.0 - ratio)
			if ratio >= 1.0:
				_finish()


## Forces the machine back to IDLE after a stuck transition (2.0 s watchdog). A long
## frame during a fade lands here too. `current_scene` already names the target, so
## a swap that has not run must still run, or the manager names a scene never loaded.
func recover_from_watchdog() -> void:
	var stuck: String = fsm.state
	watchdog_recovered.emit(stuck)
	_emit("scene.watchdog", {"stuck_state": stuck.to_lower()})
	if stuck == STATE_FADING_OUT or stuck == STATE_SWAPPING:
		_swap_to_current()
	_progress = 0.0
	_set_curtain_alpha(0.0)
	fsm.reset(STATE_IDLE)
	_start_pending()


func reject(path: String, reason: String) -> void:
	transition_rejected.emit(path, reason)
	_emit("scene.rejected", {"reason": reason, "path": _slug(path)})


func is_busy() -> bool:
	return fsm != null and fsm.state != STATE_IDLE


func set_test_mode(enabled: bool) -> void:
	test_mode = enabled


func reset() -> void:
	_clock_ms = 0
	fsm = Fsm.new(STATE_IDLE, LEGAL_EDGES, MAX_DWELL_SEC, Callable(self, "_clock"))
	pending_scene = ""
	current_scene = ""
	_def_nav.reset()
	_progress = 0.0
	production_swap_path = ""
	_set_curtain_alpha(0.0)


func _start(path: String) -> void:
	current_scene = path
	if path != SCENE_PLAYER_PATH:
		_def_nav.clear_current_def()
	_progress = 0.0
	fsm.transition_to(STATE_FADING_OUT)
	_emit("scene.fade_out", {"path": _diary_slug(path)})


func _enter_swapping() -> void:
	fsm.transition_to(STATE_SWAPPING)
	_progress = 0.0


func _load_pending_or_current() -> void:
	_swap_to_current()
	fsm.transition_to(STATE_FADING_IN)
	_progress = 0.0


func _swap_to_current() -> void:
	if loader.is_valid():
		loader.call(current_scene)
	elif not test_mode:
		_swap_production(current_scene)
	scene_changed.emit(current_scene)
	_emit("scene.changed", {"path": _diary_slug(current_scene)})


## The real navigation: swaps the running scene. Reached only outside test mode
## and only when no loader was injected.
func _swap_production(path: String) -> void:
	production_swap_path = path
	if production_swap.is_valid():
		production_swap.call(path)
		return
	var err: Error = get_tree().change_scene_to_file(path)
	if err != OK:
		_emit("scene.swap_failed", {"path": _slug(path)})


func _finish() -> void:
	fsm.transition_to(STATE_IDLE)
	_progress = 0.0
	_set_curtain_alpha(0.0)
	_emit("scene.idle", {"path": _diary_slug(current_scene)})
	_start_pending()


func _start_pending() -> void:
	if pending_scene.is_empty():
		return
	var next_scene: String = pending_scene
	pending_scene = ""
	_def_nav.apply_pending()
	_start(next_scene)


func _clock() -> int:
	return _clock_ms


func _set_curtain_alpha(alpha: float) -> void:
	_curtain.set_alpha(alpha)


func _diary_slug(path: String) -> String:
	return SceneDiarySlug.for_player_def(SCENE_PLAYER_PATH, path, _def_nav.current_def_id)


func _slug(path: String) -> String:
	return SceneDiarySlug.from_path(path)


func _emit(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
