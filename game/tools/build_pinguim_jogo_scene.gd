# story: e10s03
extends SceneTree
## Builds `res://scenes/pinguim_jogo.tscn`. Run:
##   godot --headless --path game -s tools/build_pinguim_jogo_scene.gd

const SCENE_PATH: String = "res://scenes/pinguim_jogo.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/pinguim_jogo.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"
const DRAGGABLE_SCRIPT: String = "res://scripts/components/touch_draggable.gd"
const LANE_SCRIPT: String = "res://scripts/components/ice_lane.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_village.jpg"
const HOME_ART: String = "res://assets/art/ui/home_button.png"
const PENGUIN_ART: String = "res://assets/art/friends/penguin.png"
const REPLAY_ART: String = "res://assets/art/effects/confetti.png"
const CONFETTI_ART: String = "res://assets/art/effects/confetti.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)

const LANE_Y: float = 0.78
const LANE_HEIGHT: float = 140.0
const PENGUIN_SIZE: Vector2 = Vector2(160.0, 160.0)
## BUG-061: the basket rides the lane at her feet, and the rig's top sprite layer is 50, so
## half of it was drawn behind her. Raising the basket above every rig layer is the
## closure option the bug allows: it is the thing she must drag, so it must never be the
## thing she cannot see. The lane and the balls keep their own order behind her.
const BASKET_Z: int = 60


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_lane(root)
	_add_items_container(root)
	_add_penguin(root)
	_add_hud(root)
	_add_home(root)
	_add_replay(root)
	_add_confetti(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_pinguim_jogo_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "PinguimJogo"
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


func _add_lane(root: Control) -> void:
	var lane: Control = Control.new()
	lane.name = "IceLane"
	lane.set_script(load(LANE_SCRIPT))
	lane.mouse_filter = Control.MOUSE_FILTER_PASS
	lane.add_to_group("hit_target", true)
	var half_h: float = LANE_HEIGHT * 0.5
	(
		SceneBuilder
		. pin(
			lane,
			Vector4(0.15, LANE_Y, 0.85, LANE_Y),
			Vector4(0.0, -half_h, 0.0, half_h),
		)
	)
	var visual: ColorRect = ColorRect.new()
	visual.name = "Visual"
	visual.color = Color(0.82, 0.92, 0.98, 0.88)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lane.add_child(visual)
	root.add_child(lane)


func _add_items_container(root: Control) -> void:
	var container: Control = Control.new()
	container.name = "ItemsContainer"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(container)


func _add_penguin(root: Control) -> void:
	var penguin: Control = Control.new()
	penguin.name = "Penguin"
	penguin.mouse_filter = Control.MOUSE_FILTER_PASS
	penguin.z_index = BASKET_Z
	var half: Vector2 = PENGUIN_SIZE * 0.5
	(
		SceneBuilder
		. pin(
			penguin,
			Vector4(0.5, LANE_Y, 0.5, LANE_Y),
			Vector4(-half.x, -half.y, half.x, half.y),
		)
	)
	penguin.add_child(_full_rect_art("Art", PENGUIN_ART, "", false))
	var draggable: Control = Control.new()
	draggable.name = "Draggable"
	draggable.set_script(load(DRAGGABLE_SCRIPT))
	draggable.size = PENGUIN_SIZE
	draggable.position = Vector2.ZERO
	draggable.mouse_filter = Control.MOUSE_FILTER_STOP
	draggable.add_to_group("hit_target", true)
	penguin.add_child(draggable)
	root.add_child(penguin)


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
			Vector4(INSET, INSET, INSET + 120.0, INSET + 120.0),
		)
	)
	home.add_child(_full_rect_art("Art", HOME_ART, "", false))
	root.add_child(home)


func _add_hud(root: Control) -> void:
	var hud: Control = Control.new()
	hud.name = "CoinTicketHud"
	hud.set_script(load(HUD_SCRIPT))
	(
		SceneBuilder
		. pin(
			hud,
			Vector4(1.0, 0.0, 1.0, 0.0),
			Vector4(-INSET - HUD_SIZE.x, INSET, -INSET, INSET + HUD_SIZE.y),
		)
	)
	root.add_child(hud)


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
