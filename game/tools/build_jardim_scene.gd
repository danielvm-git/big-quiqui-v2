# story: e06s02
extends SceneTree
## Generates `res://scenes/jardim.tscn`. Run:
##   godot --headless --path game -s tools/build_jardim_scene.gd
##
## A garden with three toys the child can tap and one tickle zone on QuiQui. Props sit
## in a shallow arc so they read as a scene, not a toolbar, and every one is a
## `GardenProp` with its own bounded motion.

const SCENE_PATH: String = "res://scenes/jardim.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/jardim.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const PROP_SCRIPT: String = "res://scripts/components/garden_prop.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_playroom.jpg"
const HOME_ART: String = "res://assets/art/ui/home_button.png"
const CONFETTI_ART: String = "res://assets/art/effects/confetti.png"
## kind, art, interaction id, x anchor ratio, y anchor ratio
const PROPS: Array[Dictionary] = [
	{"kind": 0, "art": "res://assets/art/items/ball.png", "id": "ball", "x": 0.12, "y": 0.80},
	{"kind": 1, "art": "res://assets/art/items/pinwheel.png", "id": "pinwheel", "x": 0.86, "y": 0.78},
	{"kind": 2, "art": "res://assets/art/items/plush.png", "id": "plush", "x": 0.30, "y": 0.90},
]

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const PROP_SIZE: Vector2 = Vector2(148.0, 148.0)
const TICKLE_SIZE: Vector2 = Vector2(200.0, 200.0)
const BUBBLE_SIZE: Vector2 = Vector2(220.0, 220.0)
const BUBBLE_GAP: float = 8.0


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_props(root)
	_add_tickle_zone(root)
	_add_home(root)
	_add_bubble(root)
	root.add_child(_confetti())

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_jardim_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Jardim"
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


## Three toys, ratio-anchored so the arc survives both canvases. Each is a hit target
## and a `GardenProp`; the scene wires the interaction ids.
func _add_props(root: Control) -> void:
	for index: int in range(PROPS.size()):
		var spec: Dictionary = PROPS[index]
		var prop: Control = _prop_node(index, float(spec["x"]), float(spec["y"]))
		# kind and interaction are wired by GardenScene._ready: a property set before
		# the node enters the tree is dropped by PackedScene.pack.
		prop.add_child(_full_rect_art("Art", str(spec["art"]), "", false))
		root.add_child(prop)


func _prop_node(index: int, x: float, y: float) -> Control:
	var prop: Control = Control.new()
	prop.name = "Prop%d" % index
	prop.set_script(load(PROP_SCRIPT))
	prop.add_to_group("hit_target", true)
	(
		SceneBuilder
		. pin(
			prop,
			Vector4(x, y, x, y),
			Vector4(-PROP_SIZE.x * 0.5, -PROP_SIZE.y * 0.5, PROP_SIZE.x * 0.5, PROP_SIZE.y * 0.5),
		)
	)
	return prop


## The tickle zone sits on her belly: repeatable play that never advances the step.
func _add_tickle_zone(root: Control) -> void:
	var zone: Control = Control.new()
	zone.name = "TickleZone"
	zone.set_script(load(BUTTON_SCRIPT))
	zone.add_to_group("hit_target", true)
	(
		SceneBuilder
		. pin(
			zone,
			Vector4(0.5, FEET_RATIO - 0.28, 0.5, FEET_RATIO - 0.28),
			Vector4(-TICKLE_SIZE.x * 0.5, -TICKLE_SIZE.y * 0.5, TICKLE_SIZE.x * 0.5, TICKLE_SIZE.y * 0.5),
		)
	)
	root.add_child(zone)


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


func _confetti() -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Confetti"
	particles.texture = load(CONFETTI_ART) as Texture2D if ResourceLoader.exists(CONFETTI_ART) else null
	particles.z_index = 30
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 16
	particles.lifetime = 1.0
	particles.spread = 60.0
	particles.direction = Vector2(0.0, -1.0)
	particles.gravity = Vector2(0.0, 400.0)
	particles.initial_velocity_min = 220.0
	particles.initial_velocity_max = 420.0
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
