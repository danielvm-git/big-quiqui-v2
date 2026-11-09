# story: e04s02
extends SceneTree
## Generates `res://scenes/banheiro.tscn`. Run:
##   godot --headless --path game -s tools/build_banheiro_scene.gd
##
## Composition follows ADR-008 (ratio anchors, absolute pixel offsets) and the
## reference benchmark: the character is the hero at 55-65 % of the height, the
## controls live inside the 36 px inset, and the foam patches are *placed by the
## scene at runtime* from the rig's scrub hull, so the builder only needs to create
## the nodes and their art.

const SCENE_PATH: String = "res://scenes/banheiro.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/banheiro.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const SPONGE_SCRIPT: String = "res://scripts/components/touch_draggable.gd"
const BLOB_SCRIPT: String = "res://scripts/components/foam_blob.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_bathroom.jpg"
const SPONGE_ART: String = "res://assets/art/items/sponge.png"
const SOAP_ART: String = "res://assets/art/items/soap.png"
const SHOWER_ART: String = "res://assets/art/items/shower_head.png"
const TOWEL_ART: String = "res://assets/art/items/towel.png"
const BLOB_ART: String = "res://assets/art/effects/foam_medium.png"
const HOME_ART: String = "res://assets/art/ui/home_button.png"
const GOTA_ART: String = "res://assets/art/effects/droplet.png"
const BOLHA_ART: String = "res://assets/art/effects/bubble.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const BUBBLE_SIZE: Vector2 = Vector2(220.0, 220.0)
const BUBBLE_GAP: float = 8.0
const SPONGE_SIZE: Vector2 = Vector2(148.0, 148.0)
const SOAP_SIZE: Vector2 = Vector2(120.0, 120.0)
const HOME_SIZE: Vector2 = Vector2(120.0, 120.0)
const INSET: float = 36.0
const BLOB_SIZE: float = 120.0


func _init() -> void:
	var root: Control = _make_root()
	_add_background(root)
	_add_rig(root)
	_add_blobs(root)
	_add_sponge(root)
	_add_device(root, "Shower", SHOWER_ART, 0)
	_add_device(root, "Towel", TOWEL_ART, 2)
	_add_soaps(root)
	_add_home(root)
	_add_bubble(root)
	_add_particles(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_banheiro_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Banheiro"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	return root


## Two one-shot bursts, used by the rinse and the dry pass.
func _add_particles(root: Control) -> void:
	root.add_child(_make_particles("Gota", GOTA_ART, 12, 0.6, 700.0, Vector2(0.05, 0.09)))
	root.add_child(_make_particles("Bolhas", BOLHA_ART, 10, 0.9, -200.0, Vector2(0.06, 0.12)))


func _add_background(root: Control) -> void:
	var background: TextureRect = _make_art("Background", BG_PATH)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.add_to_group("background", true)
	root.add_child(background)


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


## Eight patches, positioned by `BathScene.project_blobs()` from the hull. The packed
## positions are placeholders on the 16:9 body so the scene is valid before the first
## layout pass.
func _add_blobs(root: Control) -> void:
	for index: int in range(8):
		var blob: Control = Control.new()
		blob.name = "Foam%d" % index
		blob.set_script(load(BLOB_SCRIPT))
		blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blob.add_to_group("foam", true)
		blob.size = Vector2(BLOB_SIZE, BLOB_SIZE)
		blob.add_child(_framed_art("Art", BLOB_ART))
		root.add_child(blob)


## The sponge is the child's hand: it never leaves its place, the finger rubs with it.
func _add_sponge(root: Control) -> void:
	var sponge: Control = Control.new()
	sponge.name = "Sponge"
	sponge.set_script(load(SPONGE_SCRIPT))
	sponge.add_to_group("hit_target", true)
	sponge.set("mode", 1)  # TouchDraggable.Mode.CONTINUOUS_SCRUB
	_pin_device(sponge, 0)
	sponge.add_child(_framed_art("Art", SPONGE_ART))
	root.add_child(sponge)


## A child node whose art fills it, used by every button-shaped node.
func _framed_art(node_name: String, art_path: String) -> TextureRect:
	var art: TextureRect = _make_art(node_name, art_path)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return art


## Stage devices share one shape: a scrub target parked at an edge, disabled until its
## stage starts. `BathScene._set_device` shows and enables them in turn.
## `side`: 0 centre-bottom, 1 left-bottom, 2 right-bottom. The offsets follow the
## anchor, so an edge device stays inside the 36 px inset on every canvas.
func _add_device(root: Control, node_name: String, art_path: String, side: int) -> void:
	var device: Control = Control.new()
	device.name = node_name
	device.set_script(load(SPONGE_SCRIPT))
	device.add_to_group("hit_target", true)
	device.set("mode", 1)  # TouchDraggable.Mode.CONTINUOUS_SCRUB
	device.set("enabled", false)
	device.visible = false
	_pin_device(device, side)
	var art: TextureRect = _make_art("Art", art_path)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	device.add_child(art)
	root.add_child(device)


## `side`: 0 centre-bottom, 1 left-bottom, 2 right-bottom. The offsets follow the
## anchor, so an edge device stays inside the 36 px inset on every canvas.
func _pin_device(device: Control, side: int) -> void:
	var anchor_x: float = 0.5 if side == 0 else (0.0 if side == 1 else 1.0)
	var left: float = -SPONGE_SIZE.x * 0.5 if side == 0 else (INSET if side == 1 else -INSET - SPONGE_SIZE.x)
	var right: float = SPONGE_SIZE.x * 0.5 if side == 0 else (INSET + SPONGE_SIZE.x if side == 1 else -INSET)
	(
		SceneBuilder
		. pin(
			device,
			Vector4(anchor_x, 1.0, anchor_x, 1.0),
			Vector4(left, -SPONGE_SIZE.y - INSET, right, -INSET),
		)
	)


## Three soaps along the bottom-left; tapping one recolours the foam.
func _add_soaps(root: Control) -> void:
	for index: int in range(3):
		var soap: Control = Control.new()
		soap.name = "Soap%d" % index
		soap.set_script(load(BUTTON_SCRIPT))
		soap.add_to_group("hit_target", true)
		var left: float = INSET + float(index) * (SOAP_SIZE.x + 24.0)
		(
			SceneBuilder
			. pin(
				soap,
				Vector4(0.0, 1.0, 0.0, 1.0),
				Vector4(left, -SOAP_SIZE.y - INSET, left + SOAP_SIZE.x, -INSET),
			)
		)
		soap.add_child(_framed_art("Art", SOAP_ART))
		root.add_child(soap)


func _add_home(root: Control) -> void:
	var home: Control = Control.new()
	home.name = "HomeButton"
	home.set_script(load(BUTTON_SCRIPT))
	home.add_to_group("hit_target", true)
	(
		SceneBuilder
		. pin(
			home,
			Vector4(0.0, 0.0, 0.0, 0.0),
			Vector4(INSET, INSET, INSET + HOME_SIZE.x, INSET + HOME_SIZE.y),
		)
	)
	home.add_child(_framed_art("Art", HOME_ART))
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


func _make_art(node_name: String, path: String) -> TextureRect:
	var art: TextureRect = TextureRect.new()
	art.name = node_name
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		art.texture = load(path) as Texture2D
	return art


func _make_particles(
	node_name: String, path: String, amount: int, lifetime: float, gravity_y: float, scale_range: Vector2
) -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = node_name
	particles.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	particles.z_index = 30
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = lifetime
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, gravity_y)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = scale_range.x
	particles.scale_amount_max = scale_range.y
	return particles
