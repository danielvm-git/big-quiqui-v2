# story: e01s02
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

const CASA_PATH: String = "res://scenes/casa.tscn"
## The celebration is the legitimate target of a CELEBRATE cycle, not a detour.
const CELEBRACAO_PATH: String = "res://scenes/celebracao.tscn"
const REASON_SAME_SCENE: String = "same_scene"
const REASON_EMPTY_PATH: String = "empty_path"

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

const CURTAIN_LAYER: int = 128

var fsm: Fsm = null
## Test seam: when true, `_process` does nothing and only `advance()` steps the
## machine, so a test's timeline is the only timeline.
var manual_step: bool = false
var fade_duration_sec: float = 0.4
var pending_scene: String = ""
var current_scene: String = ""
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
var _curtain_layer: CanvasLayer = null
var _curtain: ColorRect = null


func _ready() -> void:
	fsm = Fsm.new(STATE_IDLE, LEGAL_EDGES, MAX_DWELL_SEC, Callable(self, "_clock"))
	_build_curtain()


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


## Requests a scene. Returns true when the transition started immediately,
## false when it was parked in the single pending slot.
func request_scene(path: String) -> bool:
	if path.strip_edges().is_empty():
		reject(path, REASON_EMPTY_PATH)
		return false
	# A detour out of the celebration must not leave the care cycle stuck in CELEBRATE
	# (T-E07-05): closing it here means every door, from every scene, is covered.
	if path != CASA_PATH and path != CELEBRACAO_PATH:
		var care: Node = get_node_or_null("/root/CareLoopManager")
		if care != null and care.has_method("close_celebrate_if_needed"):
			care.call("close_celebrate_if_needed")
	# Also while busy: a double tap must not queue a reload of the scene in flight.
	if path == current_scene:
		reject(path, REASON_SAME_SCENE)
		return false
	if path == pending_scene:
		scene_requested.emit(path, true)
		return false
	if fsm.state != STATE_IDLE:
		pending_scene = path
		scene_requested.emit(path, true)
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
	_progress = 0.0
	production_swap_path = ""
	_set_curtain_alpha(0.0)


func _start(path: String) -> void:
	current_scene = path
	_progress = 0.0
	fsm.transition_to(STATE_FADING_OUT)
	_emit("scene.fade_out", {"path": _slug(path)})


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
	_emit("scene.changed", {"path": _slug(current_scene)})


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
	_emit("scene.idle", {"path": _slug(current_scene)})
	_start_pending()


func _start_pending() -> void:
	if pending_scene.is_empty():
		return
	var next_scene: String = pending_scene
	pending_scene = ""
	_start(next_scene)


func _build_curtain() -> void:
	_curtain_layer = CanvasLayer.new()
	_curtain_layer.name = "SceneCurtainLayer"
	_curtain_layer.layer = CURTAIN_LAYER
	add_child(_curtain_layer)

	_curtain = ColorRect.new()
	_curtain.name = "SceneCurtain"
	_curtain.color = Color(0.0, 0.0, 0.0, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_curtain_layer.add_child(_curtain)


func _clock() -> int:
	return _clock_ms


func _set_curtain_alpha(alpha: float) -> void:
	if _curtain == null:
		return
	var colour: Color = _curtain.color
	colour.a = clampf(alpha, 0.0, 1.0)
	_curtain.color = colour


## Log values must be id-shaped: a scene path becomes `scene.titulo`.
func _slug(path: String) -> String:
	var base: String = path.get_file().get_basename().to_lower()
	var out: String = ""
	for character: String in base:
		out += character if character.is_valid_identifier() or character.is_valid_int() else "_"
	return "scene." + (out if not out.is_empty() else "unknown")


func _emit(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
