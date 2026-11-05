# story: e03s03
extends SceneTree
## Builds `res://scenes/cozinha.tscn` from code and saves it as a real PackedScene
## (same pattern as build_casa_scene.gd: Godot authors the file).
##
## Usage: godot --headless --path game -s res://tools/build_cozinha_scene.gd
##
## Layout uses canvas ratios (ADR-008). QuiQui stands as in the Casa, with her feet
## at 78 %. The tray and foods ride the bottom edge, inside the lower 22 %.
## `bandeja.png` is a 1024 px square with 912x400 visible around its centre, so a
## 620 px box centred 156 px above the bottom leaves about 36 px of safe inset.

const SCENE_PATH: String = "res://scenes/cozinha.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/cozinha.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const FOOD_SCRIPT: String = "res://scripts/components/touch_draggable.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"
const BG_PATH: String = "res://assets/art/backgrounds/bg_cozinha.jpg"
const TRAY_ART: String = "res://assets/art/ui/bandeja.png"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const CRUMBS_ART: String = "res://assets/art/efeitos/farelos.png"
const HEARTS_ART: String = "res://assets/art/efeitos/coracao.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const TRAY_BOX: float = 620.0
const TRAY_CENTRE_ABOVE_BOTTOM: float = 156.0
const FOOD_COUNT: int = 3
const FOOD_SIZE: float = 148.0
const FOOD_GAP: float = 24.0
const HOME_SIZE: float = 148.0
const HOME_INSET: float = 36.0
const BUBBLE_SIZE: Vector2 = Vector2(220.0, 220.0)
## The bubble hangs above the character's head line (`FEET_RATIO - RIG_HEIGHT_RATIO`),
## never at a fixed pixel offset from the floor (BUG-013).
const BUBBLE_GAP: float = 8.0
## QuiQui's top sprite layer is 50: a held food and the bursts must draw above her.
const ABOVE_RIG_Z: int = 60


func _init() -> void:
	var root: Control = Control.new()
	root.name = "Cozinha"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))

	var background: TextureRect = _make_art("Background", BG_PATH)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.add_to_group("background", true)
	root.add_child(background)

	_add_tray(root)
	_add_rig(root)
	_add_foods(root)
	_add_home_button(root)
	_add_bubble(root)
	root.add_child(_make_particles("Crumbs", CRUMBS_ART, 14, 0.7, 900.0, Vector2(0.05, 0.09)))
	root.add_child(_make_particles("Hearts", HEARTS_ART, 8, 0.9, -300.0, Vector2(0.08, 0.14)))

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_cozinha_scene")
	root.free()
	quit(0 if saved else 1)


func _make_art(node_name: String, path: String) -> TextureRect:
	var art: TextureRect = TextureRect.new()
	art.name = node_name
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = load(path) as Texture2D if not path.is_empty() else null
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


func _add_tray(root: Control) -> void:
	var tray: TextureRect = _make_art("Tray", TRAY_ART)
	(
		SceneBuilder
		. pin(
			tray,
			Vector4(0.5, 1.0, 0.5, 1.0),
			Vector4(
				-TRAY_BOX * 0.5,
				-TRAY_CENTRE_ABOVE_BOTTOM - TRAY_BOX * 0.5,
				TRAY_BOX * 0.5,
				-TRAY_CENTRE_ABOVE_BOTTOM + TRAY_BOX * 0.5,
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
	(
		SceneBuilder
		. pin(
			rig,
			Vector4(0.5, FEET_RATIO - RIG_HEIGHT_RATIO, 0.5, FEET_RATIO),
			Vector4(-RIG_WIDTH * 0.5, 0.0, RIG_WIDTH * 0.5, 0.0),
		)
	)
	root.add_child(rig)


func _add_foods(root: Control) -> void:
	var pitch: float = FOOD_SIZE + FOOD_GAP
	for index: int in range(FOOD_COUNT):
		var food: Control = Control.new()
		food.name = "Food%d" % index
		food.set_script(load(FOOD_SCRIPT))
		food.z_index = ABOVE_RIG_Z
		food.add_to_group("hit_target", true)
		var centre_x: float = pitch * (index - (FOOD_COUNT - 1) * 0.5)
		(
			SceneBuilder
			. pin(
				food,
				Vector4(0.5, 1.0, 0.5, 1.0),
				Vector4(
					centre_x - FOOD_SIZE * 0.5,
					-TRAY_CENTRE_ABOVE_BOTTOM - FOOD_SIZE * 0.5,
					centre_x + FOOD_SIZE * 0.5,
					-TRAY_CENTRE_ABOVE_BOTTOM + FOOD_SIZE * 0.5,
				),
			)
		)
		root.add_child(food)
		var art: TextureRect = _make_art("Art", "")
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		food.add_child(art)


func _add_home_button(root: Control) -> void:
	var button: Control = Control.new()
	button.name = "HomeButton"
	button.set_script(load(BUTTON_SCRIPT))
	button.add_to_group("hit_target", true)
	(
		SceneBuilder
		. pin(
			button,
			Vector4.ZERO,
			Vector4(HOME_INSET, HOME_INSET, HOME_INSET + HOME_SIZE, HOME_INSET + HOME_SIZE),
		)
	)
	root.add_child(button)

	var visual: Control = Control.new()
	visual.name = "Visual"
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(visual)

	var art: TextureRect = _make_art("Art", HOME_ART)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.add_child(art)


## Same place as in the Casa: anchored to QuiQui's head line (`FEET_RATIO - RIG_HEIGHT_RATIO`)
## so it stays above her head on every aspect (BUG-013).
func _add_bubble(root: Control) -> void:
	var bubble: Control = Control.new()
	bubble.name = "WishBubble"
	bubble.set_script(load(BUBBLE_SCRIPT))
	var head_ratio: float = FEET_RATIO - RIG_HEIGHT_RATIO
	bubble.add_to_group("wish_bubble", true)
	(
		SceneBuilder
		. pin(
			bubble,
			Vector4(0.5, head_ratio, 0.5, head_ratio),
			Vector4(
				-BUBBLE_SIZE.x * 0.5,
				-BUBBLE_SIZE.y - BUBBLE_GAP,
				BUBBLE_SIZE.x * 0.5,
				-BUBBLE_GAP,
			),
		)
	)
	root.add_child(bubble)


func _make_particles(
	node_name: String,
	path: String,
	amount: int,
	lifetime: float,
	gravity_y: float,
	scale_range: Vector2,
) -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = node_name
	particles.texture = load(path) as Texture2D
	particles.z_index = ABOVE_RIG_Z
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = lifetime
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, gravity_y)
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 260.0
	particles.scale_amount_min = scale_range.x
	particles.scale_amount_max = scale_range.y
	return particles
