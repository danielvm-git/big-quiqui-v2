# story: e02s02
class_name CoinTicketHud
extends Control
## Coins and wheel tickets as icon + numeral, mirroring ProgressManager: it
## refreshes on `progress_changed` and never writes anything itself. Numerals
## are decoration next to icons — no interaction requires reading (Zero Text
## Rule).

const COIN_ICON_PATH: String = "res://assets/art/ui/moedinha.png"
## No dedicated ticket art exists yet; the wheel is what the ticket is for
## (user decision 2026-11-04). Swap when `bilhete.png` art lands.
const TICKET_ICON_PATH: String = "res://assets/art/items/roda_fortuna.png"
const ICON_SIZE: Vector2 = Vector2(64.0, 64.0)
const LABEL_MIN_WIDTH: float = 88.0
const GROUP_GAP: int = 40

## Seam so tests can point the HUD at an unreachable manager path.
var manager_path: String = "/root/ProgressManager"

var _manager: Node = null
var _coin_label: Label = null
var _ticket_label: Label = null
var _coins_shown: int = 0
var _tickets_shown: int = 0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_build()

	_manager = get_node_or_null(manager_path)
	if _manager != null and _manager.has_signal("progress_changed"):
		_manager.progress_changed.connect(_on_progress_changed)
	refresh()


func _exit_tree() -> void:
	if (
		_manager != null
		and _manager.has_signal("progress_changed")
		and _manager.progress_changed.is_connected(_on_progress_changed)
	):
		_manager.progress_changed.disconnect(_on_progress_changed)


## Re-reads the economy from ProgressManager. A missing manager shows zeros.
func refresh() -> void:
	var data: SaveData = null
	if _manager != null:
		data = _manager.get("data") as SaveData
	if data == null:
		_coins_shown = 0
		_tickets_shown = 0
	else:
		_coins_shown = data.coins
		_tickets_shown = data.tickets
	_coin_label.text = str(_coins_shown)
	_ticket_label.text = str(_tickets_shown)


func coins_shown() -> int:
	return _coins_shown


func tickets_shown() -> int:
	return _tickets_shown


func coin_label() -> Label:
	return _coin_label


func ticket_label() -> Label:
	return _ticket_label


func _build() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row"
	row.set_anchors_preset(PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", GROUP_GAP)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(row)

	_coin_label = _build_group(row, "Coin", COIN_ICON_PATH)
	_ticket_label = _build_group(row, "Ticket", TICKET_ICON_PATH)


func _build_group(row: HBoxContainer, group_name: String, icon_path: String) -> Label:
	var group: HBoxContainer = HBoxContainer.new()
	group.name = group_name + "Group"
	group.mouse_filter = MOUSE_FILTER_IGNORE
	group.add_theme_constant_override("separation", 8)
	group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(group)

	var icon: TextureRect = TextureRect.new()
	icon.name = group_name + "Icon"
	icon.custom_minimum_size = ICON_SIZE
	icon.texture = load(icon_path) as Texture2D
	icon.mouse_filter = MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	group.add_child(icon)

	var count: Label = Label.new()
	count.name = group_name + "Count"
	count.text = "0"
	count.custom_minimum_size = Vector2(LABEL_MIN_WIDTH, ICON_SIZE.y)
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.mouse_filter = MOUSE_FILTER_IGNORE
	count.add_theme_font_size_override("font_size", 40)
	count.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	count.add_theme_color_override("font_outline_color", Color(0.29, 0.145, 0.066, 1.0))
	count.add_theme_constant_override("outline_size", 8)
	group.add_child(count)
	return count


func _on_progress_changed() -> void:
	refresh()
