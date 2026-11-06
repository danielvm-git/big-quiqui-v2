# story: e02s03
extends SceneTree
## Builds `res://scenes/casa.tscn` from code and saves it as a real PackedScene
## (same pattern as build_titulo_scene.gd: Godot authors the file, we never
## hand-write UIDs or sub-resources).
##
## Usage: godot --headless --path game -s res://tools/build_casa_scene.gd
##
## Layout is expressed as ratios of the canvas (ADR-008). Reference frame is the
## approved 1920×1080 design from e02s03: QuiQui 640×620 with her feet at 78 %,
## doors 168² on the edges at rows 304/544/784, dots 36 px above the bottom,
## HUD 36 px from the top-right corner, wish bubble on the feet line.

const SCENE_PATH: String = "res://scenes/casa.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/casa.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"
const DOTS_SCRIPT: String = "res://scripts/components/care_dots_bar.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"
const BG_PATH: String = "res://assets/art/backgrounds/bg_sala.jpg"
const DOOR_ART: String = "res://assets/art/moveis/porta.png"

## Initial box width only: `QuiQuiRig._refit()` rewrites it from the
## opaque art aspect on every layout pass, so the packed value is a placeholder.
const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const DOOR_SIZE: float = 168.0
const DOOR_INSET: float = 64.0
const DOOR_ROWS: Array[float] = [304.0 / 1080.0, 544.0 / 1080.0, 784.0 / 1080.0]
const DOTS_SIZE: Vector2 = Vector2(456.0, 72.0)
const DOTS_BOTTOM_INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)
const HUD_INSET: float = 36.0
const BUBBLE_SIZE: Vector2 = Vector2(220.0, 220.0)
## The bubble hangs above the character's head line (`FEET_RATIO - RIG_HEIGHT_RATIO`),
## not at a fixed distance from the floor: an absolute offset was tuned for a 620 px
## character and covered her face on 4:3 once she was correctly sized (round 3, BUG-013).
const BUBBLE_GAP: float = 8.0
const VILA: String = "VILA"


func _init() -> void:
	var root: Control = Control.new()
	root.name = "Casa"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	_add_background(root)
	_add_rig(root)
	_add_door_columns(root)
	_add_bubble(root)
	_add_dots(root)
	_add_hud(root)
	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_casa_scene")
	root.free()
	quit(0 if saved else 1)


func _add_background(root: Control) -> void:
	var background: TextureRect = TextureRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = load(BG_PATH) as Texture2D
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_to_group("background", true)
	root.add_child(background)


## QuiQui: 55–65 % of the canvas height, centred, feet on the 78 % line.
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


## Three care doors down each edge; the Vila door rides the right column.
func _add_door_columns(root: Control) -> void:
	var right_steps: Array[String] = []
	for index: int in range(DOOR_ROWS.size(), CareSteps.ORDER.size()):
		right_steps.append(CareSteps.ORDER[index])
	right_steps.append(VILA)
	for row: int in range(DOOR_ROWS.size()):
		_add_door(root, CareSteps.ORDER[row], DOOR_ROWS[row], true)
		_add_door(root, right_steps[row], DOOR_ROWS[row], false)


func _add_door(root: Control, step: String, row_ratio: float, on_left: bool) -> void:
	var door: Control = Control.new()
	door.name = "Door" + step
	door.set_script(load(BUTTON_SCRIPT))
	door.add_to_group("hit_target", true)
	var x_anchor: float = 0.0 if on_left else 1.0
	var left: float = DOOR_INSET if on_left else -DOOR_INSET - DOOR_SIZE
	var offsets: Vector4 = Vector4(left, -DOOR_SIZE * 0.5, left + DOOR_SIZE, DOOR_SIZE * 0.5)
	SceneBuilder.pin(door, Vector4(x_anchor, row_ratio, x_anchor, row_ratio), offsets)
	root.add_child(door)
	_add_door_visual(door)


func _add_door_visual(door: Control) -> void:
	var visual: Control = Control.new()
	visual.name = "Visual"
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(visual)
	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = load(DOOR_ART) as Texture2D
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(art)


## The bubble hangs above the character's head on every aspect: anchored to the
## head line (`FEET_RATIO - RIG_HEIGHT_RATIO`), not to a pixel offset from the floor.
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


## Five cycle dots, centred, 36 px above the bottom edge.
func _add_dots(root: Control) -> void:
	var dots: Control = Control.new()
	dots.name = "CareDotsBar"
	dots.set_script(load(DOTS_SCRIPT))
	dots.add_to_group("ui_bottom", true)
	(
		SceneBuilder
		. pin(
			dots,
			Vector4(0.5, 1.0, 0.5, 1.0),
			Vector4(
				-DOTS_SIZE.x * 0.5,
				-DOTS_BOTTOM_INSET - DOTS_SIZE.y,
				DOTS_SIZE.x * 0.5,
				-DOTS_BOTTOM_INSET,
			),
		)
	)
	root.add_child(dots)


## Coins and tickets, 36 px from the top-right corner.
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
