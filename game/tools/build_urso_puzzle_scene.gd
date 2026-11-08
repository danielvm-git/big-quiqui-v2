# story: e10s02
extends SceneTree
## Builds `res://scenes/urso_puzzle.tscn`. Run:
##   godot --headless --path game -s tools/build_urso_puzzle_scene.gd

const SCENE_PATH: String = "res://scenes/urso_puzzle.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/urso_puzzle.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"
const PIECE_SCRIPT: String = "res://scripts/components/puzzle_piece.gd"
const DRAG_HINT_SCRIPT: String = "res://scripts/components/drag_hint.gd"
const HINT_MGR_SCRIPT: String = "res://scripts/components/hint_manager.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_puzzle.jpg"
const HOME_ART: String = "res://assets/art/ui/home_button.png"
const URSO_ART: String = "res://assets/art/friends/bear.png"
const REPLAY_ART: String = "res://assets/art/effects/confetti.png"
const CONFETTI_ART: String = "res://assets/art/effects/confetti.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)

const BOARD_SIZE: Vector2 = Vector2(360.0, 360.0)
const BOARD_Y: float = 0.35
const QUAD_SIZE: Vector2 = Vector2(180.0, 180.0)
const TRAY_SIZE: Vector2 = Vector2(810.0, 180.0)
const TRAY_Y: float = 0.86


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_board(root)
	_add_tray(root)
	_add_hud(root)
	_add_home(root)
	_add_replay(root)
	_add_confetti(root)
	_add_hint_layer(root)
	_add_hint_manager(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_urso_puzzle_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "UrsoPuzzle"
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


func _add_board(root: Control) -> void:
	var board: Control = Control.new()
	board.name = "Board"
	var half: Vector2 = BOARD_SIZE * 0.5
	(
		SceneBuilder
		. pin(
			board,
			Vector4(0.5, BOARD_Y, 0.5, BOARD_Y),
			Vector4(-half.x, -half.y, half.x, half.y),
		)
	)
	var art: Texture2D = load(URSO_ART) as Texture2D if ResourceLoader.exists(URSO_ART) else null
	var tex_size: Vector2 = art.get_size() if art != null else Vector2(1024.0, 1024.0)
	for i: int in range(4):
		var slot: Control = Control.new()
		slot.name = "Slot%d" % i
		slot.position = Vector2(float(i % 2) * QUAD_SIZE.x, float(i / 2) * QUAD_SIZE.y)
		slot.size = QUAD_SIZE
		if art != null:
			var ghost: TextureRect = _create_ghost(art, i, tex_size)
			slot.add_child(ghost)
		board.add_child(slot)
	root.add_child(board)


func _create_ghost(art: Texture2D, index: int, tex_size: Vector2) -> TextureRect:
	var ghost: TextureRect = TextureRect.new()
	ghost.name = "Ghost"
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ghost.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost.modulate = Color(0.4, 0.4, 0.4, 0.7)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = art
	atlas.region = PuzzlePiece.quadrant_region(index, tex_size)
	ghost.texture = atlas
	return ghost


func _add_tray(root: Control) -> void:
	var tray: Control = Control.new()
	tray.name = "Tray"
	var half: Vector2 = TRAY_SIZE * 0.5
	(
		SceneBuilder
		. pin(
			tray,
			Vector4(0.5, TRAY_Y, 0.5, TRAY_Y),
			Vector4(-half.x, -half.y, half.x, half.y),
		)
	)
	for i: int in range(4):
		var piece: Control = Control.new()
		piece.name = "Piece%d" % i
		piece.set_script(load(PIECE_SCRIPT))
		piece.position = Vector2(float(i) * 210.0, 0.0)
		piece.size = QUAD_SIZE
		piece.custom_minimum_size = QUAD_SIZE
		piece.mouse_filter = Control.MOUSE_FILTER_PASS
		tray.add_child(piece)
	root.add_child(tray)


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


func _add_hint_layer(root: Control) -> void:
	var layer: Control = Control.new()
	layer.name = "HintLayer"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hint: Control = Control.new()
	hint.name = "DragHint"
	hint.set_script(load(DRAG_HINT_SCRIPT))
	hint.visible = false
	layer.add_child(hint)
	root.add_child(layer)


func _add_hint_manager(root: Control) -> void:
	var mgr: Node = Node.new()
	mgr.name = "HintManager"
	mgr.set_script(load(HINT_MGR_SCRIPT))
	root.add_child(mgr)


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
