# story: e08s03
extends SceneTree
## Builds `res://scenes/roda.tscn`. Run:
##   godot --headless --path game -s tools/build_roda_scene.gd

const SCENE_PATH: String = "res://scenes/roda.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/roda.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_vila.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const WHEEL_ART: String = "res://assets/art/items/roda_fortuna.png"
const BADGE_ART: String = "res://assets/art/ui/estrela.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)
const HUD_INSET: float = 36.0
## BUG-061: the wheel used to be a 440 px decoration pinned at the centre — half of it
## behind her head — plus a second, small wheel in the corner as the spin button. Two
## wheels is not a readable screen for a four-year-old, so the big wheel *is* the spin
## target now and the corner duplicate is gone. It sits right of her painted rect
## (813..1106 px at 16:9), clear on both aspects, above every rig layer.
const WHEEL_SIZE: float = 440.0
const WHEEL_ANCHOR: Vector2 = Vector2(0.80, 0.46)
## The badge hangs just above the wheel it points at.
const BADGE_ANCHOR: Vector2 = Vector2(0.80, 0.205)
const BADGE_SIZE: float = 48.0


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_hud(root)
	_add_home(root)
	_add_badge(root)
	_add_spin(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_roda_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Roda"
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


func _add_badge(root: Control) -> void:
	var badge: Control = Control.new()
	badge.name = "WheelBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SceneBuilder.pin(
		badge,
		Vector4(BADGE_ANCHOR.x, BADGE_ANCHOR.y, BADGE_ANCHOR.x, BADGE_ANCHOR.y),
		Vector4(-BADGE_SIZE, -BADGE_SIZE, BADGE_SIZE, BADGE_SIZE)
	)
	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(BADGE_ART):
		art.texture = load(BADGE_ART) as Texture2D
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(art)
	root.add_child(badge)


func _add_spin(root: Control) -> void:
	var spin: Control = Control.new()
	spin.name = "SpinButton"
	spin.set_script(load(BUTTON_SCRIPT))
	spin.add_to_group("hit_target", true)
	# BUG-061: the spin affordance is the wheel itself — one wheel, 440 px, ≥ 90 % visible.
	# z 100 keeps it above every rig layer (BUG-060/BUG-061 closure).
	var half: Vector2 = Vector2(WHEEL_SIZE, WHEEL_SIZE) * 0.5
	(
		SceneBuilder
		. pin(
			spin,
			Vector4(WHEEL_ANCHOR.x, WHEEL_ANCHOR.y, WHEEL_ANCHOR.x, WHEEL_ANCHOR.y),
			Vector4(-half.x, -half.y, half.x, half.y),
		)
	)
	spin.z_index = 100
	spin.add_child(_full_rect_art("Art", WHEEL_ART, "", false))
	root.add_child(spin)


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
