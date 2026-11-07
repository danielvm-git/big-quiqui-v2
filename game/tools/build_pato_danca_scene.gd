# story: e10s01
extends SceneTree
## Builds `res://scenes/pato_danca.tscn`. Run:
##   godot --headless --path game -s tools/build_pato_danca_scene.gd

const SCENE_PATH: String = "res://scenes/pato_danca.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/pato_danca.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_vila.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const DUCK_ART: String = "res://assets/art/amigos/pato.png"
const REPLAY_ART: String = "res://assets/art/efeitos/confete.png"
const CONFETTI_ART: String = "res://assets/art/efeitos/confete.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)
const HUD_INSET: float = 36.0

const DUCK_SIZE: float = 240.0
const DUCK_Y: float = 0.35
const PAD_SIZE: Vector2 = Vector2(200.0, 140.0)
const PAD_Y: float = 0.88
const PAD_XS: Array[float] = [0.2, 0.5, 0.8]
const PAD_LABELS: Array[String] = ["Left", "Centre", "Right"]
## Candy-warm pad colour; pure black is banned, so the rim uses a deep warm brown.
const PAD_COLOR: Color = Color(0.98, 0.72, 0.32, 0.92)


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_duck(root)
	_add_pads(root)
	_add_hud(root)
	_add_home(root)
	_add_replay(root)
	_add_confetti(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_pato_danca_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "PatoDanca"
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


func _add_duck(root: Control) -> void:
	var duck: TextureRect = TextureRect.new()
	duck.name = "Duck"
	duck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	duck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	duck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(DUCK_ART):
		duck.texture = load(DUCK_ART) as Texture2D
	var half: float = DUCK_SIZE * 0.5
	SceneBuilder.pin(duck, Vector4(0.5, DUCK_Y, 0.5, DUCK_Y), Vector4(-half, -half, half, half))
	root.add_child(duck)


func _add_pads(root: Control) -> void:
	for index: int in range(PAD_LABELS.size()):
		var pad: Control = Control.new()
		pad.name = "Pad" + PAD_LABELS[index]
		pad.set_script(load(BUTTON_SCRIPT))
		pad.add_to_group("hit_target", true)
		(
			SceneBuilder
			. pin(
				pad,
				Vector4(PAD_XS[index], PAD_Y, PAD_XS[index], PAD_Y),
				Vector4(-PAD_SIZE.x * 0.5, -PAD_SIZE.y * 0.5, PAD_SIZE.x * 0.5, PAD_SIZE.y * 0.5),
			)
		)
		pad.add_child(_pad_art())
		root.add_child(pad)


func _pad_art() -> ColorRect:
	var art: ColorRect = ColorRect.new()
	art.name = "Visual"
	art.color = PAD_COLOR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	return art


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


func _add_replay(root: Control) -> void:
	var replay: Control = Control.new()
	replay.name = "ReplayButton"
	replay.set_script(load(BUTTON_SCRIPT))
	replay.add_to_group("hit_target", true)
	replay.visible = false
	SceneBuilder.pin(replay, Vector4(0.93, 0.9, 0.93, 0.9), Vector4(-84.0, -84.0, 84.0, 84.0))
	replay.add_child(_full_rect_art("Art", REPLAY_ART, "", false))
	root.add_child(replay)


func _add_confetti(root: Control) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Confetti"
	particles.texture = load(CONFETTI_ART) as Texture2D if ResourceLoader.exists(CONFETTI_ART) else null
	particles.position = Vector2(960.0, 60.0)
	particles.z_index = 40
	particles.emitting = false
	particles.amount = 48
	particles.lifetime = 2.4
	particles.spread = 180.0
	particles.initial_velocity_min = 260.0
	particles.initial_velocity_max = 420.0
	particles.gravity = Vector2(0.0, 320.0)
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
