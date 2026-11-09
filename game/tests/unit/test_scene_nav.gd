# story: e13s03
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


func test_a_legacy_scene_goes_through_request_scene_with_its_catalogue_path() -> void:
	var manager: StubManager = StubManager.new()
	autofree(manager)
	assert_true(SceneNav.open(manager, "home"))
	assert_eq(manager.calls, ["scene:res://scenes/casa.tscn"])


func test_unknown_and_malformed_ids_open_nothing() -> void:
	var manager: StubManager = StubManager.new()
	autofree(manager)
	assert_false(SceneNav.open(manager, "not_a_room"))
	assert_false(SceneNav.open(manager, "res://scenes/casa.tscn"))
	assert_false(SceneNav.open(manager, "../home"))
	assert_false(SceneNav.open(null, "home"))
	assert_eq(manager.calls.size(), 0)
