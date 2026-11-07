# story: e10s04
extends SceneTree
## Builds `res://scenes/album.tscn`. Run:
##   godot --headless --path game -s tools/build_album_scene.gd

const SCENE_PATH: String = "res://scenes/album.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/album.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_album.jpg"
const HOME_ART: String = "res://assets/art/ui/botao_casa.png"
const STAR_ART: String = "res://assets/art/ui/estrela.png"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)

const CARD_SIZE: Vector2 = Vector2(240.0, 300.0)
const CARD_XS: Array[float] = [0.22, 0.5, 0.78]
const CARD_Y: float = 0.40
const STAR_SIZE: Vector2 = Vector2(36.0, 36.0)


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_cards(root)
	_add_hud(root)
	_add_home(root)

	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_album_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Album"
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


func _add_cards(root: Control) -> void:
	var cards_node: Control = Control.new()
	cards_node.name = "Cards"
	cards_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cards_node.mouse_filter = Control.MOUSE_FILTER_PASS

	for i: int in range(FriendCatalog.FRIEND_IDS.size()):
		var friend_id: String = FriendCatalog.FRIEND_IDS[i]
		var card: Control = _make_card(friend_id, CARD_XS[i])
		cards_node.add_child(card)

	root.add_child(cards_node)


func _make_card(friend_id: String, x_ratio: float) -> Control:
	var card: Control = Control.new()
	card.name = "Card_" + friend_id
	card.set_script(load(BUTTON_SCRIPT))
	card.add_to_group("hit_target", true)
	var half: Vector2 = CARD_SIZE * 0.5
	(
		SceneBuilder
		. pin(
			card,
			Vector4(x_ratio, CARD_Y, x_ratio, CARD_Y),
			Vector4(-half.x, -half.y, half.x, half.y),
		)
	)
	var art_path: String = FriendCatalog.art_path(friend_id)
	var art: TextureRect = _full_rect_art("Art", art_path, "", false)
	art.anchor_bottom = 0.75
	card.add_child(art)

	var stars: Control = Control.new()
	stars.name = "Stars"
	stars.anchor_top = 0.8
	stars.anchor_bottom = 1.0
	stars.anchor_left = 0.0
	stars.anchor_right = 1.0
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_stars_to_card(stars)
	card.add_child(stars)
	return card


func _add_stars_to_card(stars: Control) -> void:
	var star_w: float = 40.0
	var total_w: float = 5.0 * star_w
	var start_x: float = (CARD_SIZE.x - total_w) * 0.5
	for s: int in range(5):
		var star_rect: TextureRect = TextureRect.new()
		star_rect.name = "Star%d" % s
		star_rect.position = Vector2(start_x + float(s) * star_w, 0.0)
		star_rect.size = STAR_SIZE
		star_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(STAR_ART):
			star_rect.texture = load(STAR_ART) as Texture2D
		stars.add_child(star_rect)


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
