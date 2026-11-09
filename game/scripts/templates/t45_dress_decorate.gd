# story: e13s05
extends RefCounted
## A scrolling strip of the def's items with category tabs. A tap snaps an item onto its slot (or places
## a furniture piece), the bin takes the worn piece off, and QuiQui changes at once. Only shipped,
## owned ids reach the save. The step is done after `repeat_count` real changes.

const STRIP_NAME: String = "DressStrip"
const TAB_PREFIX: String = "tab_"
const BIN_ART: String = "trash_bag"
const GAP: float = 24.0
const SPREAD: float = 0.15

var _ctx: TemplateContext = null
var _plays: int = 0
var _changes: int = 0
var _last: String = ""
var _category: String = ""
var _strip: ScrollContainer = null
var _row: HBoxContainer = null
var _bin: TapButton = null
var _buttons: Dictionary = {}


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_build_strip()
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink != null and _ctx != null and _ctx.rig != null:
		sink.call("dress", _ctx.rig)


func teardown() -> void:
	for node: Control in [_strip, _bin]:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_strip = null
	_bin = null
	_buttons.clear()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return clampf(float(_changes) / float(_goal()), 0.0, 1.0)


func categories() -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	for category_id: String in _item_categories():
		if not found.has(category_id):
			found.append(category_id)
	return found


## Shows one category's items, or all of them when `category_id` is empty.
func show_category(category_id: String) -> void:
	_category = category_id
	for item_id: String in _buttons.keys():
		(_buttons[item_id] as TapButton).visible = _category.is_empty() or _category_of(item_id) == _category


func visible_items() -> PackedStringArray:
	var shown: PackedStringArray = PackedStringArray()
	for item_id: String in _buttons.keys():
		if (_buttons[item_id] as TapButton).visible:
			shown.append(item_id)
	return shown


func strip() -> ScrollContainer:
	return _strip


func button(item_id: String) -> TapButton:
	return _buttons.get(item_id) as TapButton


func bin_button() -> TapButton:
	return _bin


## The tap on an item: a dress item snaps to its slot, anything else is free-placed.
func choose(item_id: String) -> bool:
	return snap(item_id) if not _slot_for(item_id).is_empty() else place_free(item_id)


func snap(item_id: String) -> bool:
	var slot: String = _slot_for(item_id)
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null or slot.is_empty():
		return false
	var before: String = str(sink.call("equipped", slot))
	if not bool(sink.call("wear", slot, item_id)):
		return false
	var changed: bool = before != item_id
	_last = item_id
	_show_on_rig(slot, item_id)
	_count_change(changed, "snap")
	return true


func place_free(item_id: String) -> bool:
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null:
		return false
	var spot: float = 0.2 + SPREAD * float(int(sink.call("placed_count")) % 5)
	return place(item_id, spot, 0.6)


func place(item_id: String, nx: float, ny: float) -> bool:
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null or not Ids.is_valid(item_id) or not bool(sink.call("place_furniture", item_id, nx, ny)):
		return false
	_count_change(true, "place")
	return true


## The bin takes off the last piece she wore, or the first worn slot of the def, softly.
func bin(item_id: String = "") -> bool:
	var slot: String = _slot_for(item_id if not item_id.is_empty() else _last)
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null or slot.is_empty() or str(sink.call("equipped", slot)).is_empty():
		return false
	_plays += 1
	_last = ""
	_show_on_rig(slot, "")
	TemplateKit.play_miss(_ctx)
	return bool(sink.call("clear_slot", slot))


func play_count() -> int:
	return _plays


func _count_change(changed: bool, label: String) -> void:
	if not changed:
		return
	_changes += 1
	TemplateKit.play_hit(_ctx, "template.%s" % label, {"changes": _changes})


func _show_on_rig(slot: String, item_id: String) -> void:
	var rig: Object = null if _ctx == null else _ctx.rig
	if rig == null:
		return
	if slot == SaveData.SLOT_BODY:
		rig.call("set_outfit", item_id)
	else:
		rig.call("set_accessory", slot, item_id)


func _goal() -> int:
	return 1 if _ctx == null or _ctx.step_def == null else maxi(_ctx.step_def.repeat_count, 1)


func _item_categories() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	var found: PackedStringArray = _ctx.step_def.category_ids
	return found if found.size() == _ctx.step_def.item_ids.size() else PackedStringArray()


func _category_of(item_id: String) -> String:
	var index: int = _ctx.step_def.item_ids.find(item_id)
	var found: PackedStringArray = _item_categories()
	return found[index] if index >= 0 and index < found.size() else ""


func _slot_for(item_id: String) -> String:
	if _ctx == null or _ctx.step_def == null:
		return ""
	var index: int = _ctx.step_def.item_ids.find(item_id)
	var slots: PackedStringArray = _ctx.step_def.slot_ids
	return slots[index] if index >= 0 and index < slots.size() else ""


func _build_strip() -> void:
	if _ctx == null or _ctx.tray == null or _ctx.step_def == null:
		return
	_strip = ScrollContainer.new()
	_strip.name = STRIP_NAME
	_strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_strip.size = Vector2(maxf(_ctx.tray.size.x - TapButton.MIN_HIT_SIZE.x - 2.0 * GAP, 240.0), 160.0)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", int(GAP))
	_strip.add_child(_row)
	_fill_row()
	_ctx.tray.add_child(_strip)
	_bin = TemplateKit.tap_button(BIN_ART, Vector2(_strip.size.x + GAP, 0.0))
	_bin.tapped.connect(bin)
	_ctx.tray.add_child(_bin)


func _fill_row() -> void:
	for category_id: String in categories():
		var tab: TapButton = TemplateKit.tap_button(category_id, Vector2.ZERO)
		tab.name = TAB_PREFIX + category_id
		tab.custom_minimum_size = TapButton.MIN_HIT_SIZE
		tab.tapped.connect(_on_tab.bind(category_id))
		_row.add_child(tab)
	for item_id: String in _ctx.step_def.item_ids:
		var item: TapButton = TemplateKit.tap_button(item_id, Vector2.ZERO)
		item.custom_minimum_size = TapButton.MIN_HIT_SIZE
		item.tapped.connect(choose.bind(item_id))
		_row.add_child(item)
		_buttons[item_id] = item


func _on_tab(category_id: String) -> void:
	show_category("" if _category == category_id else category_id)
