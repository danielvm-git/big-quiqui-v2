# story: e01s02
extends GutTest
## SC-E01-P1-01/02 — SceneManager walks its declared FSM, never drops a rapid
## request (1-slot queue), and recovers from a stuck transition at 2.0 s.

const SCENE_A: String = "res://scenes/casa.tscn"
const SCENE_B: String = "res://scenes/cozinha.tscn"
const SCENE_C: String = "res://scenes/banheiro.tscn"

var sm: Node = null
var loaded: Array[String] = []
var queued_signals: Array[bool] = []
var rejections: Array[String] = []
var recoveries: Array[String] = []


func before_all() -> void:
	# Connect once: the autoload outlives the test, so per-test connections would
	# stack and every signal would be recorded N times.
	sm = get_node_or_null("/root/SceneManager")
	assert_not_null(sm, "SceneManager must be an autoload")
	sm.scene_requested.connect(func(_path: String, queued: bool) -> void: queued_signals.append(queued))
	sm.transition_rejected.connect(func(_path: String, reason: String) -> void: rejections.append(reason))
	sm.watchdog_recovered.connect(func(state: String) -> void: recoveries.append(state))


func before_each() -> void:
	TestReset.reset_all()
	sm.manual_step = true
	sm.reset()
	sm.fade_duration_sec = 0.4
	loaded = []
	queued_signals = []
	rejections = []
	recoveries = []
	sm.loader = func(path: String) -> void: loaded.append(path)


func after_each() -> void:
	sm.reset()
	sm.loader = Callable()
	sm.manual_step = false


func _drive(seconds: float, step: float = 0.1) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds and sm.is_busy():
		sm.advance(step)
		elapsed += step


func test_request_starts_the_declared_transition() -> void:
	var started: bool = sm.request_scene(SCENE_A)

	assert_true(started, "an idle manager starts immediately")
	assert_eq(sm.fsm.state, "FADING_OUT")
	assert_true(sm.is_busy())
	assert_eq(queued_signals, [false])


func test_full_transition_loads_once_and_returns_to_idle() -> void:
	var probe: FsmProbe = FsmProbe.new().attach(sm.fsm)

	sm.request_scene(SCENE_A)
	_drive(2.0)

	assert_eq(loaded, [SCENE_A], "the loader is called exactly once")
	assert_eq(sm.fsm.state, "IDLE")
	assert_false(sm.is_busy())
	assert_true(probe.is_clean(), "no illegal transition and no dwell timeout: %s" % probe.summary())
	probe.detach()


func test_one_slot_queue_keeps_the_latest_request() -> void:
	sm.request_scene(SCENE_A)
	assert_false(sm.request_scene(SCENE_B), "second request is parked")
	assert_false(sm.request_scene(SCENE_C), "third request replaces the parked one")

	_drive(4.0)

	assert_eq(loaded, [SCENE_A, SCENE_C], "B must never load: the slot keeps the latest")
	assert_eq(queued_signals, [false, true, true])


func test_duplicate_pending_request_is_not_queued_twice() -> void:
	sm.request_scene(SCENE_A)
	sm.request_scene(SCENE_B)
	sm.request_scene(SCENE_B)

	_drive(4.0)

	assert_eq(loaded, [SCENE_A, SCENE_B], "B loads once, not twice")


func test_same_scene_request_is_rejected() -> void:
	sm.request_scene(SCENE_A)
	_drive(2.0)

	assert_false(sm.request_scene(SCENE_A), "already there")
	assert_eq(rejections, [sm.REASON_SAME_SCENE])


func test_empty_path_is_rejected() -> void:
	assert_false(sm.request_scene("   "))
	assert_eq(rejections, [sm.REASON_EMPTY_PATH])
	assert_false(sm.is_busy())


func test_watchdog_recovers_a_stuck_fade() -> void:
	sm.fade_duration_sec = 10.0
	sm.request_scene(SCENE_A)
	assert_eq(sm.fsm.state, "FADING_OUT")

	sm.advance(2.1)

	assert_eq(sm.fsm.state, "IDLE", "the 2.0 s watchdog must force IDLE")
	assert_eq(recoveries, ["FADING_OUT"])
	assert_true(loaded.is_empty(), "a stuck fade must not load anything")


func test_watchdog_then_pending_scene_starts() -> void:
	sm.fade_duration_sec = 10.0
	sm.request_scene(SCENE_A)
	sm.request_scene(SCENE_B)

	sm.advance(2.1)

	assert_eq(recoveries, ["FADING_OUT"])
	assert_eq(sm.fsm.state, "FADING_OUT", "the pending scene starts right after recovery")
	assert_eq(sm.current_scene, SCENE_B)


func test_reset_returns_a_busy_manager_to_idle() -> void:
	sm.request_scene(SCENE_A)
	sm.reset()

	assert_eq(sm.fsm.state, "IDLE")
	assert_false(sm.is_busy())
	assert_eq(sm.pending_scene, "")


func test_logged_paths_are_id_shaped() -> void:
	assert_eq(sm._slug("res://scenes/casa.tscn"), "scene.casa")
	assert_eq(sm._slug("res://scenes/quarto_sono.tscn"), "scene.quarto_sono")
