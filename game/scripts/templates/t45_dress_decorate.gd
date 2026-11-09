# story: e13s05
extends RefCounted
## A scrolling strip of the def's items. A tap snaps one onto its slot, the bin clears it, and
## invalid or unpictured ids never reach the save. The step is done after `repeat_count` snaps.

const STRIP_NAME: String = "DressStrip"
const BIN_ART: String = "trash_bag"
const GAP: float = 24.0

var _ctx: TemplateContext = null
var _plays: int = 0
var _snaps: int = 0
var _last: String = ""
var _strip: ScrollContainer = null
var _row: HBoxContainer = null
var _bin: TapButton = null
var _buttons: Dictionary = {}


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_build_strip()


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
	return clampf(float(_snaps) / float(_goal()), 0.0, 1.0)


func categories() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	return _ctx.step_def.category_ids


func strip() -> ScrollContainer:
	return _strip


func button(item_id: String) -> TapButton:
	return _buttons.get(item_id) as TapButton


func bin_button() -> TapButton:
	return _bin


func snap(item_id: String) -> bool:
	if not Ids.is_valid(item_id) or not ItemArt.has_art(item_id):
		return false
	var slot: String = _slot_for(item_id)
	if slot.is_empty():
		return false
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null or not bool(sink.call("equip", slot, item_id)):
		return false
	_snaps += 1
	_last = item_id
	TemplateKit.play_hit(_ctx, "template.snap", {"snaps": _snaps})
	return true


func place(item_id: String, nx: float, ny: float) -> bool:
	if not Ids.is_valid(item_id):
		return false
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null or not bool(sink.call("place_furniture", item_id, nx, ny)):
		return false
	_snaps += 1
	return true


func bin(item_id: String) -> bool:
	var slot: String = _slot_for(item_id)
	if not Ids.is_valid(slot):
		return false
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null:
		return false
	_plays += 1
	return bool(sink.call("clear_slot", slot))


func play_count() -> int:
	return _plays


func _goal() -> int:
	if _ctx == null or _ctx.step_def == null:
		return 1
	return maxi(_ctx.step_def.repeat_count, 1)


func _slot_for(item_id: String) -> String:
	if _ctx == null or _ctx.step_def == null:
		return ""
	var index: int = _ctx.step_def.item_ids.find(item_id)
	var slots: PackedStringArray = _ctx.step_def.slot_ids
	if index < 0 or index >= slots.size():
		return ""
	return slots[index]


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
	for item_id: String in _ctx.step_def.item_ids:
		var item: TapButton = TemplateKit.tap_button(item_id, Vector2.ZERO)
		item.custom_minimum_size = TapButton.MIN_HIT_SIZE
		item.tapped.connect(snap.bind(item_id))
		_row.add_child(item)
		_buttons[item_id] = item
	_ctx.tray.add_child(_strip)
	_bin = TemplateKit.tap_button(BIN_ART, Vector2(_strip.size.x + GAP, 0.0))
	_bin.tapped.connect(_on_bin)
	_ctx.tray.add_child(_bin)


func _on_bin() -> void:
	if not _last.is_empty():
		bin(_last)
