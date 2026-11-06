# story: e01s05
extends SceneTree
## Builds `res://scenes/titulo.tscn` from code and saves it as a real PackedScene.
##
## Usage: godot --headless --path game -s res://tools/build_titulo_scene.gd
##
## Layout is expressed as ratios of the canvas (ADR-008): the 16:9 frame is
## pixel-identical to the approved design, and the taller 4:3 `expand` canvas
## keeps QuiQui at 55–65 % of the height with her feet on the 92.6 % line and the
## Play button 72 px above the bottom edge, instead of stranding both in the
## top-left corner.

const SCENE_PATH: String = "res://scenes/titulo.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/titulo.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const BG_PATH: String = "res://assets/art/backgrounds/bg_titulo.jpg"
const PLAY_ART: String = "res://assets/art/ui/botao_play.png"

## Reference frame: QuiQui 700×620 with her feet at y=1000, Play 168² at y=840.
## Initial box width only: `QuiQuiRig._refit()` rewrites it from the
## opaque art aspect on every layout pass, so the packed value is a placeholder.
const RIG_WIDTH: float = 700.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 1000.0 / 1080.0
const PLAY_SIZE: float = 168.0
const PLAY_BOTTOM_INSET: float = 72.0


func _init() -> void:
	var root: Control = Control.new()
	root.name = "Titulo"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.set_script(load(SCENE_SCRIPT))
	_add_background(root)
	_add_rig(root)
	_add_play_button(root)
	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_titulo_scene")
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


func _add_rig(root: Control) -> void:
	var rig: Control = Control.new()
	rig.name = "QuiQuiRig"
	rig.set_script(load(RIG_SCRIPT))
	rig.mouse_filter = Control.MOUSE_FILTER_STOP
	rig.add_to_group("rig", true)
	var anchors: Vector4 = Vector4(0.5, FEET_RATIO - RIG_HEIGHT_RATIO, 0.5, FEET_RATIO)
	SceneBuilder.pin(rig, anchors, Vector4(-RIG_WIDTH * 0.5, 0.0, RIG_WIDTH * 0.5, 0.0))
	root.add_child(rig)


func _add_play_button(root: Control) -> void:
	var play: Control = Control.new()
	play.name = "PlayButton"
	play.set_script(load(BUTTON_SCRIPT))
	play.add_to_group("hit_target", true)
	var offsets: Vector4 = Vector4(
		-PLAY_SIZE * 0.5, -PLAY_BOTTOM_INSET - PLAY_SIZE, PLAY_SIZE * 0.5, -PLAY_BOTTOM_INSET
	)
	SceneBuilder.pin(play, Vector4(0.5, 1.0, 0.5, 1.0), offsets)
	root.add_child(play)
	_add_play_visual(play)


func _add_play_visual(play: Control) -> void:
	var visual: Control = Control.new()
	visual.name = "Visual"
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play.add_child(visual)
	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = load(PLAY_ART) as Texture2D
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(art)
