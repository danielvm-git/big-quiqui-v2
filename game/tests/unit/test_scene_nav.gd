# story: e13s03
# story: e14s02
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


func test_a_room_without_a_def_still_uses_the_legacy_scene() -> void:
	var manager: StubManager = StubManager.new()
	autofree(manager)
	assert_true(SceneNav.open(manager, "wheel"))
	assert_eq(manager.calls, ["scene:res://scenes/roda.tscn"])


func test_unknown_and_malformed_ids_open_nothing() -> void:
	var manager: StubManager = StubManager.new()
	autofree(manager)
	assert_false(SceneNav.open(manager, "not_a_room"))
	assert_false(SceneNav.open(manager, "res://scenes/casa.tscn"))
	assert_false(SceneNav.open(manager, "../home"))
	assert_false(SceneNav.open(null, "home"))
	assert_eq(manager.calls.size(), 0)
