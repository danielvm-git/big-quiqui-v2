# story: e12s02
extends SceneTree

const SCENE_PATH: String = "res://scenes/scene_player.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/scene_player.gd"


func _init() -> void:
	var root: Control = Control.new()
	root.name = "ScenePlayer"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	var background: TextureRect = TextureRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_to_group("background", true)
	root.add_child(background)
	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_scene_player_scene")
	root.free()
	quit(0 if saved else 1)
