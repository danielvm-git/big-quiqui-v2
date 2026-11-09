# story: e01s02
extends GutTest
## SC-E01-P1-01/02 — SceneManager walks its declared FSM, never drops a rapid
## request (1-slot queue), and recovers from a stuck transition at 2.0 s.

const SCENE_A: String = "res://scenes/casa.tscn"
const SCENE_B: String = "res://scenes/cozinha.tscn"
const SCENE_C: String = "res://scenes/banheiro.tscn"
const SCENE_MISSING: String = "res://scenes/nao_existe_nunca.tscn"
var sm: Node = null
var loaded: Array[String] = []
var queued_signals: Array[bool] = []
var rejections: Array[String] = []
var recoveries: Array[String] = []
var production_swaps: Array[String] = []


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
	production_swaps = []
	sm.loader = func(path: String) -> void: loaded.append(path)
	sm.production_swap = func(path: String) -> void: production_swaps.append(path)


func after_each() -> void:
	sm.reset()
	sm.loader = Callable()
	sm.production_swap = Callable()
	sm.set_test_mode(false)
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


# e03s03: a double tap on a door must not reload the scene it is already opening.
func test_a_repeat_request_for_the_path_in_flight_does_not_reload() -> void:
	sm.request_scene(SCENE_A)
	assert_false(sm.request_scene(SCENE_A), "a second tap during the fade")
	assert_eq(sm.pending_scene, "", "nothing is parked")
	_drive(4.0)
	assert_eq(loaded, [SCENE_A], "one load")
	assert_eq(sm.fsm.state, "IDLE")


func test_a_repeat_request_during_the_fade_in_does_not_reload() -> void:
	sm.request_scene(SCENE_A)
	while sm.fsm.state != "FADING_IN":
		sm.advance(0.1)
	sm.request_scene(SCENE_A)
	_drive(4.0)
	assert_eq(loaded, [SCENE_A])


func test_a_repeat_request_leaves_a_parked_different_scene_alone() -> void:
	sm.request_scene(SCENE_A)
	sm.request_scene(SCENE_B)
	sm.request_scene(SCENE_A)
	assert_eq(sm.pending_scene, SCENE_B)
	_drive(4.0)
	assert_eq(loaded, [SCENE_A, SCENE_B])


func test_same_scene_request_is_rejected() -> void:
	sm.request_scene(SCENE_A)
	_drive(2.0)
	assert_false(sm.request_scene(SCENE_A), "already there")
	assert_eq(rejections, [sm.REASON_SAME_SCENE])


func test_empty_path_is_rejected() -> void:
	assert_false(sm.request_scene("   "))
	assert_eq(rejections, [sm.REASON_EMPTY_PATH])
	assert_false(sm.is_busy())


# Review H1: `current_scene` already names the target, so a recovery that did not
# swap left the manager naming a scene that never loaded.
func test_watchdog_during_the_fade_out_still_swaps_to_the_requested_scene() -> void:
	sm.fade_duration_sec = 10.0
	sm.request_scene(SCENE_A)
	assert_eq(sm.fsm.state, "FADING_OUT")
	sm.advance(2.1)
	assert_eq(sm.fsm.state, "IDLE", "the 2.0 s watchdog must force IDLE")
	assert_eq(recoveries, ["FADING_OUT"])
	assert_eq(loaded, [SCENE_A], "the requested scene loads, once")
	assert_eq(sm.current_scene, SCENE_A)


func test_watchdog_during_swapping_still_swaps_to_the_requested_scene() -> void:
	sm.fade_duration_sec = 0.1
	sm.request_scene(SCENE_A)
	sm.advance(0.2)
	assert_eq(sm.fsm.state, "SWAPPING")
	sm.advance(2.1)
	assert_eq(recoveries, ["SWAPPING"])
	assert_eq(sm.fsm.state, "IDLE")
	assert_eq(loaded, [SCENE_A])


func test_watchdog_during_the_fade_in_does_not_swap_again() -> void:
	sm.fade_duration_sec = 0.1
	sm.request_scene(SCENE_A)
	sm.advance(0.2)
	sm.advance(0.1)
	assert_eq(sm.fsm.state, "FADING_IN")
	sm.advance(2.1)
	assert_eq(recoveries, ["FADING_IN"])
	assert_eq(sm.fsm.state, "IDLE")
	assert_eq(loaded, [SCENE_A], "the swap already ran before the stall")


func test_a_watchdog_recovery_leaves_later_trips_working() -> void:
	sm.request_scene(SCENE_B)
	sm.advance(2.1)
	assert_eq(loaded, [SCENE_B], "the child is really in the room")

	assert_true(sm.request_scene(SCENE_A), "the way back starts")
	_drive(2.0)
	assert_true(sm.request_scene(SCENE_B), "and the door opens again")
	_drive(2.0)

	assert_eq(loaded, [SCENE_B, SCENE_A, SCENE_B])
	assert_eq(rejections, [])


func test_watchdog_then_pending_scene_starts() -> void:
	sm.fade_duration_sec = 10.0
	sm.request_scene(SCENE_A)
	sm.request_scene(SCENE_B)

	sm.advance(2.1)

	assert_eq(recoveries, ["FADING_OUT"])
	assert_eq(loaded, [SCENE_A], "the stuck scene loaded before the pending one starts")
	assert_eq(sm.fsm.state, "FADING_OUT", "the pending scene starts right after recovery")
	assert_eq(sm.current_scene, SCENE_B)


func test_watchdog_outside_test_mode_swaps_the_real_scene_once() -> void:
	sm.loader = Callable()
	sm.set_test_mode(false)

	sm.request_scene(SCENE_A)
	sm.advance(2.1)

	assert_eq(production_swaps, [SCENE_A])
	assert_eq(sm.production_swap_path, SCENE_A)


# T-E03-04: the recovery path keeps the guarantee of the normal path.
func test_watchdog_in_test_mode_never_swaps_the_real_scene() -> void:
	sm.loader = Callable()
	sm.set_test_mode(true)

	sm.request_scene(SCENE_A)
	sm.advance(2.1)

	assert_eq(sm.fsm.state, "IDLE")
	assert_eq(production_swaps, [])
	assert_eq(sm.production_swap_path, "")


# The real `change_scene_to_file` runs here: it fails on a path that does not
# exist and leaves the runner scene alone.
func test_a_missing_scene_during_a_watchdog_recovery_cannot_brick_the_app() -> void:
	sm.loader = Callable()
	sm.production_swap = Callable()
	sm.set_test_mode(false)

	sm.request_scene(SCENE_MISSING)
	sm.advance(2.1)

	assert_engine_error("Cannot open file", "the swap was really attempted")
	assert_engine_error("Failed loading resource")
	assert_eq(sm.fsm.state, "IDLE")
	assert_false(sm.is_busy())
	assert_eq(sm._curtain.alpha(), 0.0, "the curtain is not left over the screen")

	sm.production_swap = func(path: String) -> void: production_swaps.append(path)
	assert_true(sm.request_scene(SCENE_A), "navigation still works")
	_drive(2.0)
	assert_eq(production_swaps, [SCENE_A])


func test_reset_returns_a_busy_manager_to_idle() -> void:
	sm.request_scene(SCENE_A)
	sm.reset()

	assert_eq(sm.fsm.state, "IDLE")
	assert_false(sm.is_busy())
	assert_eq(sm.pending_scene, "")


func test_logged_paths_are_id_shaped() -> void:
	assert_eq(sm._slug("res://scenes/casa.tscn"), "scene.casa")
	assert_eq(sm._slug("res://scenes/quarto_sono.tscn"), "scene.quarto_sono")


# SC-E02-P0-09 — the production swap fires exactly once, outside test mode
func test_production_mode_swaps_the_real_scene_once() -> void:
	sm.loader = Callable()  # no injected loader: the production branch must run
	sm.set_test_mode(false)
	sm.production_swap_path = ""

	sm.request_scene(SCENE_A)
	_drive(2.0)

	assert_eq(sm.fsm.state, "IDLE")
	assert_eq(sm.production_swap_path, SCENE_A, "the swap is recorded")
	assert_eq(production_swaps, [SCENE_A], "change_scene_to_file is reached exactly once")
	assert_eq(loaded, [], "no test loader runs in production mode")


# SC-E02-P0-09b — an injected loader always wins over the production swap
func test_injected_loader_takes_precedence_over_the_production_swap() -> void:
	sm.set_test_mode(false)

	sm.request_scene(SCENE_A)
	_drive(2.0)

	assert_eq(loaded, [SCENE_A])
	assert_eq(sm.production_swap_path, "", "the production branch never runs beside a loader")


# SC-E02-P0-10 — test mode must never touch the real scene tree (T-E02-02)
func test_test_mode_never_swaps_the_real_scene() -> void:
	sm.loader = Callable()
	sm.set_test_mode(true)
	sm.production_swap_path = ""

	sm.request_scene(SCENE_A)
	_drive(2.0)

	assert_eq(sm.fsm.state, "IDLE")
	assert_true(production_swaps.is_empty(), "no production swap under TestReset")
	assert_eq(sm.production_swap_path, "")
	assert_eq(queued_signals, [false], "the request still flows — only the swap is suppressed")


func test_legacy_slug_for_cozinha_path_is_unchanged() -> void:
	assert_eq(sm._slug("res://scenes/cozinha.tscn"), "scene.cozinha")
