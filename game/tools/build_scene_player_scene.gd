# story: e12s02
# story: e12s03
extends SceneTree

const SCENE_PATH: String = "res://scenes/scene_player.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/scene_player.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const DOTS_SCRIPT: String = "res://scripts/components/care_dots_bar.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"
const HINT_MGR_SCRIPT: String = "res://scripts/components/hint_manager.gd"
const DRAG_HINT_SCRIPT: String = "res://scripts/components/drag_hint.gd"
const BG_PLACEHOLDER: String = "res://assets/art/backgrounds/bg_kitchen.jpg"
const TRAY_ART: String = "res://assets/art/ui/tray.png"
const HOME_ART: String = "res://assets/art/ui/home_button.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const TRAY_BOX: float = 620.0
const TRAY_CENTRE_ABOVE_BOTTOM: float = 156.0
const HOME_SIZE: float = 148.0
const HOME_INSET: float = 36.0


func _init() -> void:
	var root: Control = Control.new()
	root.name = "ScenePlayer"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	_add_background(root)
	_add_tray(root)
	_add_rig(root)
	_add_dots(root)
	_add_hud(root)
	_add_home(root)
	_add_hints(root)
	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_scene_player_scene")
	root.free()
	quit(0 if saved else 1)


func _add_background(root: Control) -> void:
	var bg: TextureRect = TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture = load(BG_PLACEHOLDER) as Texture2D
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_to_group("background", true)
	root.add_child(bg)


func _add_tray(root: Control) -> void:
	var tray: Control = Control.new()
	tray.name = "TrayZone"
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.texture = load(TRAY_ART) as Texture2D
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(art)
	(
		SceneBuilder
		. pin(
			tray,
			Vector4(0.5, 1.0, 0.5, 1.0),
			Vector4(
				-TRAY_BOX * 0.5,
				-TRAY_CENTRE_ABOVE_BOTTOM - TRAY_BOX * 0.5,
				TRAY_BOX * 0.5,
				-TRAY_CENTRE_ABOVE_BOTTOM + TRAY_BOX * 0.5
			),
		)
	)
	root.add_child(tray)


func _add_rig(root: Control) -> void:
	var rig: Control = Control.new()
	rig.name = "QuiQuiRig"
	rig.set_script(load(RIG_SCRIPT))
	rig.mouse_filter = Control.MOUSE_FILTER_STOP
	rig.add_to_group("rig", true)
	SceneBuilder.pin(
		rig,
		Vector4(0.5, FEET_RATIO - RIG_HEIGHT_RATIO, 0.5, FEET_RATIO),
		Vector4(-RIG_WIDTH * 0.5, 0.0, RIG_WIDTH * 0.5, 0.0)
	)
	root.add_child(rig)


func _add_dots(root: Control) -> void:
	var dots: Control = Control.new()
	dots.name = "StepDots"
	dots.set_script(load(DOTS_SCRIPT))
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.add_to_group("ui_bottom", true)
	SceneBuilder.pin(dots, Vector4(0.5, 1.0, 0.5, 1.0), Vector4(-228.0, -96.0, 228.0, -24.0))
	root.add_child(dots)


func _add_hud(root: Control) -> void:
	var hud: Control = Control.new()
	hud.name = "CoinHud"
	hud.set_script(load(HUD_SCRIPT))
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_to_group("ui_top_right", true)
	SceneBuilder.pin(hud, Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-200.0, 24.0, -24.0, 120.0))
	root.add_child(hud)


func _add_home(root: Control) -> void:
	var button: Control = Control.new()
	button.name = "HomeButton"
	button.set_script(load(BUTTON_SCRIPT))
	button.add_to_group("hit_target", true)
	var edge: float = HOME_INSET + HOME_SIZE
	SceneBuilder.pin(button, Vector4.ZERO, Vector4(HOME_INSET, HOME_INSET, edge, edge))
	root.add_child(button)
	var visual: Control = Control.new()
	visual.name = "Visual"
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(visual)
	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.texture = load(HOME_ART) as Texture2D
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(art)


func _add_hints(root: Control) -> void:
	var mgr: Node = Node.new()
	mgr.name = "HintManager"
	mgr.set_script(load(HINT_MGR_SCRIPT))
	root.add_child(mgr)
	var hand: Control = Control.new()
	hand.name = "DragHint"
	hand.set_script(load(DRAG_HINT_SCRIPT))
	hand.visible = false
	root.add_child(hand)
