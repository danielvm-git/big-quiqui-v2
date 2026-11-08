# story: e09s01
extends SceneTree
## Builds `res://scenes/mercado.tscn`. Run:
##   godot --headless --path game -s tools/build_mercado_scene.gd

const SCENE_PATH: String = "res://scenes/mercado.tscn"
const SCENE_SCRIPT: String = "res://scripts/scenes/mercado.gd"
const RIG_SCRIPT: String = "res://scripts/components/quiqui_rig.gd"
const BUTTON_SCRIPT: String = "res://scripts/components/tap_button.gd"
const HUD_SCRIPT: String = "res://scripts/components/coin_ticket_hud.gd"

const BG_PATH: String = "res://assets/art/backgrounds/bg_market.jpg"
const HOME_ART: String = "res://assets/art/ui/home_button.png"
const COIN_ART: String = "res://assets/art/ui/coin.png"
const SOLD_ART: String = "res://assets/art/ui/star.png"
const FURNITURE_ART: String = "res://assets/art/furniture/"

const RIG_WIDTH: float = 640.0
const RIG_HEIGHT_RATIO: float = 620.0 / 1080.0
const FEET_RATIO: float = 0.78
const INSET: float = 36.0
const HUD_SIZE: Vector2 = Vector2(380.0, 88.0)
const HUD_INSET: float = 36.0

## 3 columns x 4 rows on the back wall: shelf pitch is 144 px wide and 151 px tall on the
## 16:9 canvas, above the 120 px hit floor on both.
const COLUMN_RATIOS: Array[float] = [0.70, 0.775, 0.85]
const ROW_RATIOS: Array[float] = [0.28, 0.42, 0.56, 0.70]
const SHELF_SIZE: float = 120.0
const BADGE_SIZE: float = 48.0
const PRICE_SIZE: Vector2 = Vector2(96.0, 40.0)

const SHELF_IDS: Array[String] = [
	"abajur",
	"armario",
	"beliche",
	"cadeira",
	"cama",
	"escada",
	"estante",
	"mesa",
	"porta",
	"sofa",
	"tapete",
	"vaso_planta",
]
const PRICES: Array[int] = [3, 8, 9, 3, 10, 7, 6, 4, 5, 8, 2, 3]


func _init() -> void:
	var root: Control = _make_root()
	root.add_child(_full_rect_art("Background", BG_PATH, "background", true))
	_add_rig(root)
	_add_hud(root)
	_add_home(root)
	for index: int in range(SHELF_IDS.size()):
		_add_shelf(root, index)
	var saved: bool = SceneBuilder.pack_and_save(root, SCENE_PATH, "build_mercado_scene")
	root.free()
	quit(0 if saved else 1)


func _make_root() -> Control:
	var root: Control = Control.new()
	root.name = "Mercado"
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


func _add_shelf(root: Control, index: int) -> void:
	var column: float = COLUMN_RATIOS[index % COLUMN_RATIOS.size()]
	var row: float = ROW_RATIOS[index / COLUMN_RATIOS.size()]
	var half: float = SHELF_SIZE * 0.5
	var shelf: Control = Control.new()
	shelf.name = "Shelf%d" % index
	shelf.set_script(load(BUTTON_SCRIPT))
	shelf.add_to_group("hit_target", true)
	SceneBuilder.pin(shelf, Vector4(column, row, column, row), Vector4(-half, -half, half, half))
	shelf.add_child(_full_rect_art("Art", FURNITURE_ART + SHELF_IDS[index] + ".png", "", false))
	shelf.add_child(_price_badge(index))
	shelf.add_child(_sold_badge(index))
	root.add_child(shelf)


func _price_badge(index: int) -> Control:
	var badge: Control = Control.new()
	badge.name = "PriceBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var half: float = PRICE_SIZE.x * 0.5
	(
		SceneBuilder
		. pin(
			badge,
			Vector4(0.0, 1.0, 0.0, 1.0),
			Vector4(-half + SHELF_SIZE * 0.5, 0.0, half + SHELF_SIZE * 0.5, PRICE_SIZE.y),
		)
	)
	badge.add_child(_badge_coin())
	badge.add_child(_badge_label(PRICES[index]))
	return badge


func _badge_coin() -> TextureRect:
	var coin: TextureRect = _full_rect_art("Coin", COIN_ART, "", false)
	coin.custom_minimum_size = Vector2(32.0, 32.0)
	SceneBuilder.pin(coin, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(0.0, 0.0, 32.0, 32.0))
	return coin


func _badge_label(price: int) -> Label:
	var label: Label = Label.new()
	label.name = "Price"
	label.text = str(price)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", 28)
	SceneBuilder.pin(label, Vector4(0.0, 0.0, 0.0, 0.0), Vector4(36.0, 0.0, PRICE_SIZE.x, 32.0))
	return label


func _sold_badge(index: int) -> Control:
	var badge: Control = Control.new()
	badge.name = "SoldBadge%d" % index
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.visible = false
	var half: float = BADGE_SIZE * 0.5
	SceneBuilder.pin(badge, Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-half, -half, half, half))
	badge.add_child(_full_rect_art("Art", SOLD_ART, "", false))
	return badge


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
