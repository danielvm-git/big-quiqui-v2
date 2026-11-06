# story: e01s01
class_name TestReset
extends RefCounted
## Test isolation (ADR-005): no test may read or write the production save file.
##
## `ProgressManager` and friends arrive in e01s02/e01s03, so every lookup here is
## optional. Adding a manager later requires no change to existing tests — the
## reset simply reaches it once it exists.

const TEST_SAVE_PATH: String = "user://test_progress.json"
const MANAGERS: Array[String] = ["ProgressManager", "CareLoopManager", "SceneManager", "AudioManager"]


static func reset_all() -> void:
	if not OS.is_debug_build():
		push_warning("TestReset is only meaningful in debug builds (T-E01-02)")
		return
	delete_test_save()
	VilaScene.reset_session()
	for manager: String in MANAGERS:
		var node: Node = manager_node(manager)
		if node == null:
			continue
		if node.has_method("set_test_mode"):
			node.call("set_test_mode", true)
		if node.has_method("reset"):
			node.call("reset")


static func delete_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


static func manager_node(manager: String) -> Node:
	if Engine.get_main_loop() is not SceneTree:
		return null
	return (Engine.get_main_loop() as SceneTree).root.get_node_or_null(manager)


static func paint_the_diary_red() -> String:
	## Reference value the PII tests feed the writer; must never be stored verbatim.
	return "Maria Clara /Users/daniel/segredo.gd mae@email.com 123456789"
