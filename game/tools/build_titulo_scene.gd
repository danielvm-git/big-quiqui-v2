# story: e01s05
extends SceneTree
## Builds `res://scenes/titulo.tscn` from code and saves it as a real PackedScene.
##
## Hand-writing a .tscn is fragile (UIDs, sub-resources, layout flags); packing a
## tree the engine already built yields a file Godot authored itself.
##
## Usage: godot --headless --path game -s res://tools/build_titulo_scene.gd

const SCENE_PATH: String = "res://scenes/titulo.tscn"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const SCENE_SCRIPT: String = "res://scripts/scenes/titulo.gd"
const BG_PATH: String = "res://assets/art/backgrounds/bg_titulo.jpg"
const PLAY_ART: String = "res://assets/art/ui/botao_play.png"


func _init() -> void:
	var root: Control = Control.new()
	root.name = "Titulo"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size = Vector2(1920.0, 1080.0)
	root.set_script(load(SCENE_SCRIPT))

	var background: TextureRect = TextureRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = load(BG_PATH) as Texture2D
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_to_group("background", true)
	root.add_child(background)

	var rig: Control = Control.new()
	rig.name = "QuiQuiRig"
	rig.set_script(load(RIG_SCRIPT))
	rig.size = Vector2(700.0, 620.0)
	rig.position = Vector2(610.0, 380.0)
	rig.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(rig)

	var play: Control = Control.new()
	play.name = "PlayButton"
	play.set_script(load(BUTTON_SCRIPT))
	play.size = Vector2(168.0, 168.0)
	play.position = Vector2(876.0, 840.0)
	play.add_to_group("hit_target", true)
	root.add_child(play)

	var visual: Control = Control.new()
	visual.name = "Visual"
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play.add_child(visual)

	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = load(PLAY_ART) as Texture2D
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(art)

	# PackedScene only serialises nodes whose `owner` is the scene root; without this
	# every child is silently dropped and the .tscn contains just the root node.
	_set_owner_recursive(root, root)

	var packed: PackedScene = PackedScene.new()
	var pack_error: int = packed.pack(root)
	if pack_error != OK:
		printerr("build_titulo_scene: pack failed (%s)" % error_string(pack_error))
		quit(1)
		return

	var save_error: int = ResourceSaver.save(packed, SCENE_PATH)
	if save_error != OK:
		printerr("build_titulo_scene: save failed (%s)" % error_string(save_error))
		quit(1)
		return

	print("build_titulo_scene: wrote %s (%d nodes)" % [SCENE_PATH, _count(root)])
	root.free()
	quit(0)


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)


func _count(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += _count(child)
	return total
