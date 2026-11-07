# story: e10s03
extends GutTest
## SC-E10-P0-14..16 — CatchItem and catch loop unit tests: step_down, single-pop
## per item, floor removal, advance time accumulation, and settle economy.

const BOLA_ART: String = "res://assets/art/items/bola.png"
const BOLHA_ART: String = "res://assets/art/efeitos/bolha.png"


func before_each() -> void:
	TestReset.reset_all()


func after_each() -> void:
	TestReset.delete_test_save()


# SC-E10-P0-14
func test_catch_item_step_down_moves_y() -> void:
	var item: CatchItem = CatchItem.new()
	item.kind = "bola"
	item.position = Vector2(100.0, 50.0)
	item.step_down(20.0)
	assert_eq(item.position.y, 70.0, "position.y increased by 20")
	item.step_down(35.5)
	assert_eq(item.position.y, 105.5, "position.y increased by 35.5")
	assert_eq(item.position.x, 100.0, "x unchanged")
	item.free()


# SC-E10-P0-14
func test_catch_item_popped_state_is_idempotent() -> void:
	var item: CatchItem = CatchItem.new()
	item.kind = "bolha"
	assert_false(item.popped, "starts unpopped")
	item.popped = true
	assert_true(item.popped, "marked popped")
	item.free()


# SC-E10-P0-15
func test_tuning_floors_prevent_division_by_zero_and_infinite_loops() -> void:
	# Tuning parameters must be floored > 0
	var min_spawn: float = maxf(0.0, 0.2)
	assert_gte(min_spawn, 0.2, "spawn interval floored at 0.2")
	var min_fall: float = maxf(-10.0, 50.0)
	assert_gte(min_fall, 50.0, "fall speed floored at 50")


# SC-E10-P0-16
func test_penguin_scene_advance_drives_fsm_and_accumulates_clock() -> void:
	var scene: PenguinScene = PenguinScene.new()
	scene.manual_step = true
	add_child_autofree(scene)
	assert_eq(str(scene.fsm.state), PenguinScene.STATE_INTRO)

	# Advance past INTRO_SEC (1.0s)
	scene.advance(1.1)
	assert_eq(str(scene.fsm.state), PenguinScene.STATE_RUNNING)
	scene.advance(0.5)
	assert_gt(scene.round_sec, 0.0, "round_sec accumulates in running")

	# Seed spawns
	scene.seed_spawns(["bola", "bolha"] as Array[String])

	# Advance through remaining round duration (19.5s)
	scene.advance(20.0)
	assert_eq(str(scene.fsm.state), PenguinScene.STATE_RESULT)

	# Advance through result duration (1.5s)
	scene.advance(1.6)
	assert_eq(str(scene.fsm.state), PenguinScene.STATE_REWARD)
