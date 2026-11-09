# story: e09s02
extends SceneTree
## Builds `res://scenes/casinha.tscn`. Run:
##   godot --headless --path game -s tools/build_casinha_scene.gd

const SCENE_PATH: String = "res://scenes/casinha.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/casinha.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"
const HINT_MGR_SCRIPT: String = "res://scripts/components/hint_manager.gd"
const DRAG_HINT_SCRIPT: String = "res://scripts/components/drag_hint.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_playhouse.jpg"
const HOME_ART: String = "res://assets/art/ui/home_button.png"
const TRAY_ART: String = "res://assets/art/ui/tray.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)
const HUD_INSET: float = 36.0

## The room is the drop area and the tray is where her pieces wait (e09s02).
const ROOM_ANCHORS: Vector4 = Vector4(0.20, 0.28, 0.80, 0.74)
const TRAY_ANCHORS: Vector4 = Vector4(0.12, 0.82, 0.88, 0.96)
## The rig reaches the bottom (feet 0.78) while the tray sits at 0.82, so she stays on
## the centre line: `QuiQuiRig._refit` only fits the box to the art when `left == right`.
const RIG_CENTER: float = 0.5


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	root.add_child(_region("PlacementArea", ROOM_ANCHORS, false))
	root.add_child(_tray())
	root.add_child(_decor("TrayArt", TRAY_ART, TRAY_ANCHORS))
	_add_rig(root)
	_add_hud(root)
	_add_home(root)
	_add_hint_layer(root)
	_add_hint_manager(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_casinha_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Casinha"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	return root


func _region(node_name: String, anchors: Vector4, stop_mouse: bool) -> Control:
	var region: Control = Control.new()
	region.name = node_name
	region.mouse_filter = Control.MOUSE_FILTER_STOP if stop_mouse else Control.MOUSE_FILTER_IGNORE
	SceneBuilder.pin(region, anchors, Vector4.ZERO)
	return region


func _tray() -> Control:
	var tray: Control = _region("Tray", TRAY_ANCHORS, false)
	return tray


func _decor(node_name: String, path: String, anchors: Vector4) -> TextureRect:
	var art: TextureRect = _full_rect_art(node_name, path, "", false)
	SceneBuilder.pin(art, anchors, Vector4.ZERO)
	return art


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
			Vector4(RIG_CENTER, FEET_RATIO - RIG_HEIGHT_RATIO, RIG_CENTER, FEET_RATIO),
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


func _add_hint_layer(root: Control) -> void:
	var layer: Control = Control.new()
	layer.name = "HintLayer"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint: Control = Control.new()
	hint.name = "DragHint"
	hint.set_script(load(DRAG_HINT_SCRIPT))
	hint.visible = false
	layer.add_child(hint)
	root.add_child(layer)


func _add_hint_manager(root: Control) -> void:
	var mgr: Node = Node.new()
	mgr.name = "HintManager"
	mgr.set_script(load(HINT_MGR_SCRIPT))
	root.add_child(mgr)


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
