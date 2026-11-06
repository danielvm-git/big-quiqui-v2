# story: e07s02
extends SceneTree
## Generates `res://scenes/celebracao.tscn`.

const SCENE_PATH: String = "res://scenes/celebracao.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/celebracao.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_celebracao.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const CONFETTI_ART: String = "res://assets/art/efeitos/confete.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0


func _init() -> void:
	var root: Control = Control.new()
	root.name = "Celebracao"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	root.add_child(_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_home(root)
	root.add_child(_confetti())
	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_celebracao_scene")
	root.free()
	quit(0 if saved else 1)


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


func _add_home(root: Control) -> void:
	var home: Control = Control.new()
	home.name = "HomeButton"
	home.set_script(load(BUTTON_SCRIPT))
	home.add_to_group("hit_target", true)
	SceneBuilder.pin(home, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(INSET, INSET, INSET + 120.0, INSET + 120.0))
	home.add_child(_art("Art", HOME_ART, "", false))
	root.add_child(home)


func _confetti() -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Confetti"
	particles.texture = load(CONFETTI_ART) as Texture2D if ResourceLoader.exists(CONFETTI_ART) else null
	particles.z_index = 30
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 24
	particles.lifetime = 1.6
	particles.spread = 70.0
	particles.direction = Vector2(0.0, -1.0)
	particles.gravity = Vector2(0.0, 380.0)
	particles.initial_velocity_min = 260.0
	particles.initial_velocity_max = 520.0
	return particles


func _art(node_name: String, path: String, group: String, covered: bool) -> TextureRect:
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
