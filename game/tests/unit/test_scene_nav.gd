# story: e13s03
# story: e14s02
# story: e14s04
extends GutTest
## SceneNav opens a catalogue id as a data scene or a legacy scene, and nothing else.


class StubManager:
	extends Node
	var calls: Array[String] = []

	func request_def(scene_id: String) -> bool:
		calls.append("def:%s" % scene_id)
		return true

	func request_scene(path: String) -> bool:
		calls.append("scene:%s" % path)
		return true


func test_a_data_scene_goes_through_request_def() -> void:
	var manager: StubManager = StubManager.new()
	autofree(manager)
	assert_true(SceneNav.open(manager, "kitchen"))
	assert_eq(manager.calls, ["def:kitchen"])


func test_home_opens_as_data_when_a_def_exists() -> void:
	var manager: StubManager = StubManager.new()
	autofree(manager)
	assert_true(SceneNav.open(manager, "home"))
	assert_eq(manager.calls, ["def:home"], "SC-e14s02 e14s02 home is data on the player")


func test_wheel_and_penguin_open_as_data_when_defs_exist() -> void:
	var manager: StubManager = StubManager.new()
	autofree(manager)
	assert_true(SceneNav.open(manager, "wheel"))
	assert_eq(manager.calls, ["def:wheel"], "SC-e14s04 wheel is data")
	manager.calls.clear()
	assert_true(SceneNav.open(manager, "penguin_lanes"))
	assert_eq(manager.calls, ["def:penguin_lanes"])


func test_unknown_and_malformed_ids_open_nothing() -> void:
	var manager: StubManager = StubManager.new()
	autofree(manager)
	assert_false(SceneNav.open(manager, "not_a_room"))
	assert_false(SceneNav.open(manager, "res://scenes/casa.tscn"))
	assert_false(SceneNav.open(manager, "../home"))
	assert_false(SceneNav.open(null, "home"))
	assert_eq(manager.calls.size(), 0)
