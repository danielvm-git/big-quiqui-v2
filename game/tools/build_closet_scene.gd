# story: e05s02
extends SceneTree
## Generates `res://scenes/closet.tscn`. Run:
##   godot --headless --path game -s tools/build_closet_scene.gd
##
## A wardrobe rail on the left (four outfits), a shelf of accessories on the right
## (six), the character in the middle and the home button in the top-left inset. The
## items are `SNAP_TO_SLOT` draggables wired by `ClosetScene._wire_items()`.

const SCENE_PATH: String = "res://scenes/closet.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/closet.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const ITEM_SCRIPT: String = "res://scripts/components/touch_draggable.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_quarto.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const SPARKLE_ART: String = "res://assets/art/efeitos/brilho.png"
const OUTFIT_ART_ROOT: String = "res://assets/art/quiqui/quiqui_%s.png"
const ACCESSORY_ART_ROOT: String = "res://assets/art/items/%s.png"
const OUTFITS: Array[String] = ["vestido_florido", "vestido_vermelho", "macacao_verde", "pijama"]
const ACCESSORIES: Array[String] = [
	"tiara_flores", "coroa", "chapeu_amarelo", "cachecol_azul", "laco_roxo", "oculos_coracao"
]

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const ITEM_SIZE: Vector2 = Vector2(132.0, 132.0)
const ITEM_GAP: float = 20.0
const BUBBLE_SIZE: Vector2 = Vector2(220.0, 220.0)
const BUBBLE_GAP: float = 8.0


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_outfits(root)
	_add_accessories(root)
	_add_home(root)
	_add_bubble(root)
	root.add_child(_sparkles())

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_closet_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Closet"
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


## Four outfits down the left rail: one column, so a four-year-old swipes a vertical
## list instead of hunting a grid.
func _add_outfits(root: Control) -> void:
	for index: int in range(OUTFITS.size()):
		var path: String = OUTFIT_ART_ROOT % OUTFITS[index]
		var at: Vector2 = Vector2(INSET, INSET + float(index) * (ITEM_SIZE.y + ITEM_GAP))
		root.add_child(_item("Outfit%d" % index, path, at))


## Six accessories down the right rail, in slot order: hats, then neck, then eyes.
func _add_accessories(root: Control) -> void:
	for index: int in range(ACCESSORIES.size()):
		var path: String = ACCESSORY_ART_ROOT % ACCESSORIES[index]
		var at: Vector2 = Vector2(-INSET - ITEM_SIZE.x, INSET + float(index) * (ITEM_SIZE.y + ITEM_GAP))
		root.add_child(_item("Accessory%d" % index, path, at))


func _item(node_name: String, art_path: String, at: Vector2) -> Control:
	var item: Control = Control.new()
	item.name = node_name
	item.set_script(load(ITEM_SCRIPT))
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.add_to_group("hit_target", true)
	item.set("mode", 2)  # TouchDraggable.Mode.SNAP_TO_SLOT
	var pinned_left: bool = at.x >= 0.0
	(
		SceneBuilder
		. pin(
			item,
			Vector4(0.0 if pinned_left else 1.0, 0.0, 0.0 if pinned_left else 1.0, 0.0),
			Vector4(at.x, at.y, at.x + ITEM_SIZE.x, at.y + ITEM_SIZE.y),
		)
	)
	item.add_child(_full_rect_art("Art", art_path, "", false))
	return item


func _add_home(root: Control) -> void:
	var home: Control = Control.new()
	home.name = "HomeButton"
	home.set_script(load(BUTTON_SCRIPT))
	home.add_to_group("hit_target", true)
	(
		SceneBuilder
		. pin(
			home,
			Vector4(0.5, 0.0, 0.5, 0.0),
			Vector4(-60.0, INSET, 60.0, INSET + 120.0),
		)
	)
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


func _sparkles() -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Sparkles"
	particles.texture = load(SPARKLE_ART) as Texture2D if ResourceLoader.exists(SPARKLE_ART) else null
	particles.z_index = 30
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.8
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, -120.0)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 180.0
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
