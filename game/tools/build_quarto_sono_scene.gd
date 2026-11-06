# story: e07s01
extends SceneTree
## Generates `res://scenes/quarto_sono.tscn`.

const SCENE_PATH: String = "res://scenes/quarto_sono.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/quarto_sono.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const ITEM_SCRIPT: String = "res://scripts/components/touch_draggable.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_quarto.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const LAMP_ART: String = "res://assets/art/efeitos/zzz.png"
const PLUSH_ART: String = "res://assets/art/items/pelucia.png"
const ZZZ_ART: String = "res://assets/art/efeitos/zzz.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const PLUSH_SIZE: Vector2 = Vector2(132.0, 132.0)
const BUBBLE_SIZE: Vector2 = Vector2(220.0, 220.0)
const BUBBLE_GAP: float = 8.0


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_plush(root)
	_add_lamp(root)
	_add_home(root)
	_add_bubble(root)
	root.add_child(_zzz())
	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_quarto_sono_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "QuartoSono"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	return root


func _add_rig(root: Control) -> void:
	var rig: Control = Control.new()
	rig.name = "QuiQuiRig"
	rig.set_script(load(RIG_SCRIPT))
	rig.mouse_filter = Control.MOUSE_FILTER_STOP
	rig.add_to_group("rig", true)
	(
		SceneBuilder
		. pin(
			rig,
			Vector4(0.5, FEET_RATIO - RIG_HEIGHT_RATIO, 0.5, FEET_RATIO),
			Vector4(-RIG_WIDTH * 0.5, 0.0, RIG_WIDTH * 0.5, 0.0),
		)
	)
	root.add_child(rig)


func _add_plush(root: Control) -> void:
	var plush: Control = Control.new()
	plush.name = "Plush"
	plush.set_script(load(ITEM_SCRIPT))
	plush.add_to_group("hit_target", true)
	plush.set("mode", 2)
	(
		SceneBuilder
		. pin(
			plush,
			Vector4(0.0, 1.0, 0.0, 1.0),
			Vector4(INSET, -PLUSH_SIZE.y - INSET, INSET + PLUSH_SIZE.x, -INSET),
		)
	)
	plush.add_child(_full_rect_art("Art", PLUSH_ART, "", false))
	root.add_child(plush)


func _add_lamp(root: Control) -> void:
	var lamp: Control = Control.new()
	lamp.name = "LampButton"
	lamp.set_script(load(BUTTON_SCRIPT))
	lamp.add_to_group("hit_target", true)
	(
		SceneBuilder
		. pin(
			lamp,
			Vector4(1.0, 0.0, 1.0, 0.0),
			Vector4(-INSET - 120.0, INSET, -INSET, INSET + 120.0),
		)
	)
	lamp.add_child(_full_rect_art("Art", LAMP_ART, "", false))
	root.add_child(lamp)


func _add_home(root: Control) -> void:
	var home: Control = Control.new()
	home.name = "HomeButton"
	home.set_script(load(BUTTON_SCRIPT))
	home.add_to_group("hit_target", true)
	SceneBuilder.pin(home, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(INSET, INSET, INSET + 120.0, INSET + 120.0))
	home.add_child(_full_rect_art("Art", HOME_ART, "", false))
	root.add_child(home)


func _add_bubble(root: Control) -> void:
	var bubble: Control = Control.new()
	bubble.name = "WishBubble"
	bubble.set_script(load(BUBBLE_SCRIPT))
	bubble.add_to_group("wish_bubble", true)
	var head_ratio: float = FEET_RATIO - RIG_HEIGHT_RATIO
	(
		SceneBuilder
		. pin(
			bubble,
			Vector4(0.5, head_ratio, 0.5, head_ratio),
			Vector4(-BUBBLE_SIZE.x * 0.5, -BUBBLE_SIZE.y - BUBBLE_GAP, BUBBLE_SIZE.x * 0.5, -BUBBLE_GAP),
		)
	)
	root.add_child(bubble)


func _zzz() -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Zzz"
	particles.texture = load(ZZZ_ART) as Texture2D if ResourceLoader.exists(ZZZ_ART) else null
	particles.z_index = 30
	particles.emitting = false
	particles.one_shot = false
	particles.amount = 6
	particles.lifetime = 2.2
	particles.spread = 30.0
	particles.direction = Vector2(0.0, -1.0)
	particles.gravity = Vector2(0.0, -40.0)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	return particles


func _full_rect_art(node_name: String, path: String, group: String, covered: bool) -> TextureRect:
	var art: TextureRect = TextureRect.new()
	art.name = node_name
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_COVERED if covered else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(path):
		art.texture = load(path) as Texture2D
	if not group.is_empty():
		art.add_to_group(group, true)
	return art
