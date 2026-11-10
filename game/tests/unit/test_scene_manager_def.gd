# story: e12s02
# story: e14s05
extends GutTest
## SC-e12s02-P0-05/06 — SceneManager opens the player and hands off the def once.

const SCENE_C: String = SceneCatalog.PLAYER_SCENE
const DEF_DEV_SMOKE: String = "dev_smoke"
const DEF_MISSING: String = "room_missing"

var sm: Node = null
var loaded: Array[String] = []


func before_all() -> void:
	sm = get_node_or_null("/root/SceneManager")
	assert_not_null(sm, "SceneManager must be an autoload")


func before_each() -> void:
	TestReset.reset_all()
	sm.manual_step = true
	sm.reset()
	sm.fade_duration_sec = 0.4
	loaded = []
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


func test_request_def_drives_the_same_fsm_as_request_scene() -> void:
	var probe: FsmProbe = FsmProbe.new().attach(sm.fsm)
	var started: bool = sm.request_def(DEF_DEV_SMOKE)
	assert_true(started)
	assert_eq(sm.fsm.state, "FADING_OUT")
	_drive(2.0)
	assert_eq(loaded, [SceneManager.SCENE_PLAYER_PATH])
	assert_eq(sm.fsm.state, "IDLE")
	assert_true(probe.is_clean(), probe.summary())
	probe.detach()


func test_request_def_uses_the_one_slot_pending_queue() -> void:
	sm.request_def(DEF_DEV_SMOKE)
	assert_false(sm.request_def("kitchen"), "second def is parked")
	_drive(4.0)
	assert_eq(loaded, [SceneManager.SCENE_PLAYER_PATH, SceneManager.SCENE_PLAYER_PATH])


func test_consume_def_returns_the_def_once() -> void:
	sm.request_def(DEF_DEV_SMOKE)
	_drive(2.0)
	var first: SceneDef = sm.consume_def()
	var second: SceneDef = sm.consume_def()
	assert_not_null(first)
	assert_eq(first.id, DEF_DEV_SMOKE)
	assert_null(second, "a second read must be empty")


func test_request_def_for_a_missing_tres_is_rejected_without_swap() -> void:
	assert_false(sm.request_def(DEF_MISSING))
	assert_eq(loaded, [] as Array[String])
	assert_false(sm.is_busy())


func test_def_navigation_logs_scene_kitchen_slug() -> void:
	assert_eq(sm.scene_slug_for_id("kitchen"), "scene.kitchen")
