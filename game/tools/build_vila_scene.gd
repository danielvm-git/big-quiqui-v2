# story: e08s01
extends SceneTree
## Builds `res://scenes/vila.tscn`. Run:
##   godot --headless --path game -s tools/build_vila_scene.gd

const SCENE_PATH: String = "res://scenes/vila.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/vila.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_vila.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)
const HUD_INSET: float = 36.0
const BUBBLE_SIZE: Vector2 = Vector2(220.0, 220.0)
const BUBBLE_GAP: float = 8.0
const POI_SIZE: float = 168.0

## id -> { "x": anchor, "y": anchor, "art": path }
const POI_SPECS: Array[Dictionary] = [
	{"id": "CASA", "x": 0.12, "y": 0.44, "art": "res://assets/art/moveis/porta.png"},
	{"id": "RODA", "x": 0.86, "y": 0.40, "art": "res://assets/art/items/roda_fortuna.png"},
	{
		"id": "RECYCLING",
		"x": 0.16,
		"y": 0.70,
		"art": "res://assets/art/items/saquinho_lixo.png",
	},
	{"id": "MERCADO", "x": 0.84, "y": 0.68, "art": "res://assets/art/items/melancia.png"},
	{"id": "CASINHA", "x": 0.36, "y": 0.36, "art": "res://assets/art/items/patinho.png"},
	{"id": "FESTA", "x": 0.64, "y": 0.34, "art": "res://assets/art/items/coroa.png"},
]


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_hud(root)
	_add_home(root)
	_add_bubble(root)
	for spec: Dictionary in POI_SPECS:
		_add_poi(root, str(spec["id"]), float(spec["x"]), float(spec["y"]), str(spec["art"]))

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_vila_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Vila"
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


func _add_hud(root: Control) -> void:
	var hud: Control = Control.new()
	hud.name = "CoinTicketHud"
	hud.set_script(load(HUD_SCRIPT))
	hud.add_to_group("ui_top_right", true)
	(
		SceneBuilder
		. pin(
			hud,
			Vector4(1.0, 0.0, 1.0, 0.0),
			Vector4(-HUD_INSET - HUD_SIZE.x, HUD_INSET, -HUD_INSET, HUD_INSET + HUD_SIZE.y),
		)
	)
	root.add_child(hud)


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


func _add_poi(root: Control, poi_id: String, x: float, y: float, art_path: String) -> void:
	var poi: Control = Control.new()
	poi.name = "Poi" + poi_id
	poi.set_script(load(BUTTON_SCRIPT))
	poi.add_to_group("hit_target", true)
	var half: float = POI_SIZE * 0.5
	SceneBuilder.pin(poi, Vector4(x, y, x, y), Vector4(-half, -half, half, half))
	poi.add_child(_full_rect_art("Art", art_path, "", false))
	root.add_child(poi)


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
