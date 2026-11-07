# story: e09s03
# story: e10s01
extends SceneTree
## Builds `res://scenes/festa.tscn`. Run:
##   godot --headless --path game -s tools/build_festa_scene.gd

const SCENE_PATH: String = "res://scenes/festa.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/festa.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_casinha.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const CASINHA_ART: String = "res://assets/art/ui/botao_voltar.png"
const LOCK_ART: String = "res://assets/art/ui/bolinha_progresso_vazia.png"
const CONFETTI_ART: String = "res://assets/art/efeitos/confete.png"
const FRIEND_ART: String = "res://assets/art/amigos/"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)
const HUD_INSET: float = 36.0
const FRIEND_SIZE: float = 200.0
const LOCK_SIZE: float = 120.0

## Three friends flank her, clear of the 640 px rig box in the centre column.
const FRIENDS: Array[Dictionary] = [
	{"id": "pato", "x": 0.16, "y": 0.58},
	{"id": "urso", "x": 0.84, "y": 0.58},
	{"id": "pinguim", "x": 0.28, "y": 0.34},
]


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	for friend: Dictionary in FRIENDS:
		_add_friend(root, friend)
	_add_rig(root)
	_add_hud(root)
	_add_home(root)
	_add_casinha(root)
	_add_lock(root)
	_add_confetti(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_festa_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Festa"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	return root


func _add_friend(root: Control, spec: Dictionary) -> void:
	var x: float = float(spec["x"])
	var y: float = float(spec["y"])
	var holder: Control = Control.new()
	holder.name = "Friend_" + str(spec["id"])
	holder.set_script(load(BUTTON_SCRIPT))
	holder.add_to_group("hit_target", true)
	holder.visible = false
	var half: float = FRIEND_SIZE * 0.5
	SceneBuilder.pin(holder, Vector4(x, y, x, y), Vector4(-half, -half, half, half))
	holder.add_child(_full_rect_art("Art", FRIEND_ART + str(spec["id"]) + ".png", "", false))
	root.add_child(holder)


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


func _button(node_name: String, art_path: String, left: float) -> Control:
	var button: Control = Control.new()
	button.name = node_name
	button.set_script(load(BUTTON_SCRIPT))
	button.add_to_group("hit_target", true)
	var right: float = left + 120.0
	SceneBuilder.pin(button, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(left, INSET, right, INSET + 120.0))
	button.add_child(_full_rect_art("Art", art_path, "", false))
	return button


func _add_home(root: Control) -> void:
	root.add_child(_button("HomeButton", HOME_ART, INSET))


func _add_casinha(root: Control) -> void:
	root.add_child(_button("CasinhaButton", CASINHA_ART, INSET + 140.0))


func _add_lock(root: Control) -> void:
	var badge: Control = Control.new()
	badge.name = "LockBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var half: float = LOCK_SIZE * 0.5
	SceneBuilder.pin(badge, Vector4(0.5, 0.30, 0.5, 0.30), Vector4(-half, -half, half, half))
	badge.add_child(_full_rect_art("Art", LOCK_ART, "", false))
	root.add_child(badge)


func _add_confetti(root: Control) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Confetti"
	particles.texture = load(CONFETTI_ART) as Texture2D if ResourceLoader.exists(CONFETTI_ART) else null
	particles.position = Vector2(960.0, 60.0)
	particles.z_index = 40
	particles.emitting = false
	particles.amount = 48
	particles.lifetime = 2.4
	particles.spread = 30.0
	particles.direction = Vector2(0.0, 1.0)
	particles.gravity = Vector2(0.0, 160.0)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 180.0
	root.add_child(particles)


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
