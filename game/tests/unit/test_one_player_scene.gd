# story: e14s05
extends GutTest
## SC-e14s05-P0-01 — only scene_player.tscn ships in game/scenes.


func test_only_scene_player_tscn_remains() -> void:
	var paths: PackedStringArray = PackedStringArray()
	var dir: DirAccess = DirAccess.open("res://scenes")
	assert_not_null(dir)
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while not name.is_empty():
		if name.ends_with(".tscn"):
			paths.append("game/scenes/%s" % name)
		name = dir.get_next()
	dir.list_dir_end()
	assert_eq(paths, PackedStringArray(["game/scenes/scene_player.tscn"]))
