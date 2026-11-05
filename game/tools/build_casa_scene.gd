# story: e02s03
extends SceneTree
## Builds `res://scenes/casa.tscn` from code and saves it as a real PackedScene
## (same pattern as build_titulo_scene.gd: Godot authors the file, we never
## hand-write UIDs or sub-resources).
##
## Usage: godot --headless --path game -s res://tools/build_casa_scene.gd

const SCENE_PATH: String = "res://scenes/casa.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/casa.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"
const DOTS_SCRIPT: String = "res://scripts/components/care_dots_bar.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"
const BG_PATH: String = "res://assets/art/backgrounds/bg_sala.jpg"
const DOOR_ART: String = "res://assets/art/moveis/porta.png"

const DOOR_SIZE: Vector2 = Vector2(168.0, 168.0)
const LEFT_DOORS: Array[String] = ["FEED", "BATH", "DRESS"]
const RIGHT_DOORS: Array[String] = ["PLAY", "SLEEP", "VILA"]
const DOOR_X_LEFT: float = 64.0
const DOOR_X_RIGHT: float = 1688.0
const DOOR_YS: Array[float] = [220.0, 460.0, 700.0]


func _init() -> void:
	var root: Control = Control.new()
	root.name = "Casa"
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

	# QuiQui: ~57% of viewport height, centered, feet at 78% of stage height.
	var rig: Control = Control.new()
	rig.name = "QuiQuiRig"
	rig.set_script(load(RIG_SCRIPT))
	rig.size = Vector2(640.0, 620.0)
	rig.position = Vector2(640.0, 222.0)
	rig.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(rig)

	for column_index: int in range(DOOR_YS.size()):
		_add_door(root, LEFT_DOORS[column_index], Vector2(DOOR_X_LEFT, DOOR_YS[column_index]))
		_add_door(root, RIGHT_DOORS[column_index], Vector2(DOOR_X_RIGHT, DOOR_YS[column_index]))

	var bubble: Control = Control.new()
	bubble.name = "WishBubble"
	bubble.set_script(load(BUBBLE_SCRIPT))
	bubble.size = Vector2(220.0, 220.0)
	bubble.position = Vector2(850.0, 30.0)
	root.add_child(bubble)

	var dots: Control = Control.new()
	dots.name = "CareDotsBar"
	dots.set_script(load(DOTS_SCRIPT))
	dots.size = Vector2(456.0, 72.0)
	dots.position = Vector2(732.0, 972.0)
	root.add_child(dots)

	var hud: Control = Control.new()
	hud.name = "CoinTicketHud"
	hud.set_script(load(HUD_SCRIPT))
	hud.size = Vector2(380.0, 88.0)
	hud.position = Vector2(1504.0, 36.0)
	root.add_child(hud)

	# PackedScene only serialises nodes whose `owner` is the scene root; without this
	# every child is silently dropped and the .tscn contains just the root node.
	_set_owner_recursive(root, root)

	var packed: PackedScene = PackedScene.new()
	var pack_error: int = packed.pack(root)
	if pack_error != OK:
		printerr("build_casa_scene: pack failed (%s)" % error_string(pack_error))
		quit(1)
		return

	var save_error: int = ResourceSaver.save(packed, SCENE_PATH)
	if save_error != OK:
		printerr("build_casa_scene: save failed (%s)" % error_string(save_error))
		quit(1)
		return

	print("build_casa_scene: wrote %s (%d nodes)" % [SCENE_PATH, _count(root)])
	root.free()
	quit(0)


func _add_door(root: Control, step: String, at: Vector2) -> void:
	var door: Control = Control.new()
	door.name = "Door" + step
	door.set_script(load(BUTTON_SCRIPT))
	door.size = DOOR_SIZE
	door.position = at
	door.add_to_group("hit_target", true)
	root.add_child(door)

	var visual: Control = Control.new()
	visual.name = "Visual"
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(visual)

	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = load(DOOR_ART) as Texture2D
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(art)


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)


func _count(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += _count(child)
	return total
