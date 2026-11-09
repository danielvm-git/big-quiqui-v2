# story: e12s02
extends GutTest
## SC-e12s02-P0-07 — the player scene boots from a def headlessly.

const PLAYER_PATH: String = "res://scenes/scene_player.tscn"


func before_each() -> void:
	TestReset.reset_all()


func test_the_player_boots_from_a_consumed_def() -> void:
	var sm: Node = get_node("/root/SceneManager")
	sm.manual_step = true
	sm.reset()
	sm.fade_duration_sec = 0.1
	sm.loader = Callable()
	sm.production_swap = Callable()
	sm.set_test_mode(true)
	assert_true(sm.request_def("dev_smoke"))
	while sm.is_busy():
		sm.advance(0.1)
	var packed: PackedScene = load(PLAYER_PATH) as PackedScene
	assert_not_null(packed)
	var player: Control = packed.instantiate() as Control
	assert_not_null(player)
	add_child_autofree(player)
	if player.has_method("boot_from_manager"):
		player.call("boot_from_manager")
	assert_true(player.is_node_ready())
	var def: SceneDef = player.get("loaded_def") as SceneDef
	assert_not_null(def)
	assert_eq(def.id, "dev_smoke")
	sm.reset()
	sm.manual_step = false
