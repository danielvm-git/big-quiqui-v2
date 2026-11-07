# story: e08s01
# story: e08s02
# story: e10s04
extends SceneTree
## Builds `res://scenes/vila.tscn`. Run:
##   godot --headless --path game -s tools/build_vila_scene.gd

const SCENE_PATH: String = "res://scenes/vila.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/vila.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const BUBBLE_SCRIPT: String = "res://scripts/components/wish_bubble.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"
const DRAG_SCRIPT: String = "res://scripts/components/touch_draggable.gd"
const HINT_MGR_SCRIPT: String = "res://scripts/components/hint_manager.gd"
const DRAG_HINT_SCRIPT: String = "res://scripts/components/drag_hint.gd"
const DOOR_BADGE_SCRIPT: String = "res://scripts/components/door_badge.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_vila.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const CONFETTI_ART: String = "res://assets/art/efeitos/confete.png"
const PARTY_LOCKED_ART: String = "res://assets/art/ui/bolinha_progresso_vazia.png"
const PARTY_UNLOCKED_ART: String = "res://assets/art/ui/estrela.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)
const HUD_INSET: float = 36.0
const BUBBLE_SIZE: Vector2 = Vector2(220.0, 220.0)
const BUBBLE_GAP: float = 8.0
const POI_SIZE: float = 168.0
const BAG_SIZE: float = 148.0

## CASA/RODA/recycling row + mercado + casinha + festa + album
const POI_SPECS: Array[Dictionary] = [
	{"id": "CASA", "x": 0.12, "y": 0.44, "art": "res://assets/art/moveis/porta.png"},
	{"id": "RODA", "x": 0.86, "y": 0.40, "art": "res://assets/art/items/roda_fortuna.png"},
	{"id": "MERCADO", "x": 0.84, "y": 0.68, "art": "res://assets/art/items/melancia.png"},
	{"id": "CASINHA", "x": 0.36, "y": 0.36, "art": "res://assets/art/items/patinho.png"},
	{"id": "FESTA", "x": 0.64, "y": 0.34, "art": "res://assets/art/items/coroa.png"},
	{"id": "ALBUM", "x": 0.24, "y": 0.54, "art": "res://assets/art/moveis/estante.png"},
]


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_hud(root)
	_add_home(root)
	_add_bubble(root)
	for spec: Dictionary in POI_SPECS:
		_add_poi(root, str(spec["id"]), float(spec["x"]), float(spec["y"]), str(spec["art"]))
	_add_party_badge(root)
	_add_album_badge(root)
	_add_recycle_bin(root, 0.72, 0.78)
	_add_recycle_bag(root, 0.16, 0.70)
	_add_hint_layer(root)
	_add_hint_manager(root)
	_add_sparkle(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_vila_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Vila"
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


func _add_poi(root: Control, poi_id: String, x: float, y: float, art_path: String) -> void:
	var poi: Control = Control.new()
	poi.name = "Poi" + poi_id
	poi.set_script(load(BUTTON_SCRIPT))
	poi.add_to_group("hit_target", true)
	var half: float = POI_SIZE * 0.5
	SceneBuilder.pin(poi, Vector4(x, y, x, y), Vector4(-half, -half, half, half))
	poi.add_child(_full_rect_art("Art", art_path, "", false))
	root.add_child(poi)


## FIX-04: the party door says whether the party is open, from the same rule the party
## scene reads. A component, so the hub never grows a second owner for the threshold.
func _add_party_badge(root: Control) -> void:
	var door: Control = root.get_node_or_null("PoiFESTA") as Control
	if door == null:
		return
	var badge: Control = Control.new()
	badge.name = "PartyBadge"
	badge.set_script(load(DOOR_BADGE_SCRIPT))
	badge.set("required_placed", 5)
	badge.set("locked_art", PARTY_LOCKED_ART)
	badge.set("unlocked_art", PARTY_UNLOCKED_ART)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SceneBuilder.pin(badge, Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-48.0, -48.0, 0.0, 0.0))
	badge.add_child(_full_rect_art("Art", PARTY_LOCKED_ART, "", false))
	door.add_child(badge)


func _add_album_badge(root: Control) -> void:
	var door: Control = root.get_node_or_null("PoiALBUM") as Control
	if door == null:
		return
	var badge: Control = Control.new()
	badge.name = "AlbumBadge"
	badge.set_script(load(DOOR_BADGE_SCRIPT))
	badge.set("rule", "stars")
	badge.set("required_stars", 1)
	badge.set("locked_art", PARTY_LOCKED_ART)
	badge.set("unlocked_art", PARTY_UNLOCKED_ART)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SceneBuilder.pin(badge, Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-48.0, -48.0, 0.0, 0.0))
	badge.add_child(_full_rect_art("Art", PARTY_LOCKED_ART, "", false))
	door.add_child(badge)


func _add_recycle_bin(root: Control, x: float, y: float) -> void:
	var bin: Control = Control.new()
	bin.name = "RecycleBin"
	bin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bin.add_to_group("hit_target", true)
	var half: float = POI_SIZE * 0.5
	SceneBuilder.pin(bin, Vector4(x, y, x, y), Vector4(-half, -half, half, half))
	var visual: Control = Control.new()
	visual.name = "Visual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	bin.add_child(visual)
	var art: TextureRect = _full_rect_art("Art", "res://assets/art/items/chuveirinho.png", "", false)
	visual.add_child(art)
	root.add_child(bin)


func _add_recycle_bag(root: Control, x: float, y: float) -> void:
	var bag: Control = Control.new()
	bag.name = "RecycleBag"
	bag.set_script(load(DRAG_SCRIPT))
	bag.add_to_group("hit_target", true)
	var half: float = BAG_SIZE * 0.5
	SceneBuilder.pin(bag, Vector4(x, y, x, y), Vector4(-half, -half, half, half))
	bag.add_child(_full_rect_art("Art", "res://assets/art/items/saquinho_lixo.png", "", false))
	root.add_child(bag)


func _add_hint_layer(root: Control) -> void:
	var layer: Control = Control.new()
	layer.name = "HintLayer"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(layer)
	var hint: Control = Control.new()
	hint.name = "DragHint"
	hint.set_script(load(DRAG_HINT_SCRIPT))
	hint.visible = false
	layer.add_child(hint)


func _add_hint_manager(root: Control) -> void:
	var mgr: Node = Node.new()
	mgr.name = "HintManager"
	mgr.set_script(load(HINT_MGR_SCRIPT))
	root.add_child(mgr)


func _add_sparkle(root: Control) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Sparkle"
	particles.texture = load(CONFETTI_ART) as Texture2D if ResourceLoader.exists(CONFETTI_ART) else null
	particles.z_index = 40
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 24
	particles.lifetime = 0.6
	particles.spread = 45.0
	particles.direction = Vector2(0.0, -1.0)
	particles.gravity = Vector2(0.0, 120.0)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 220.0
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
