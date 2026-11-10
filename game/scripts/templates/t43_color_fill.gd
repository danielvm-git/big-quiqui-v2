# story: e15s01
extends RefCounted
## Give pick_one: each area accepts one named color; a miss flies home.

var _ctx: TemplateContext = null
var _areas: Dictionary = {}
var _chips: Array[TouchDraggable] = []
var _filled: Dictionary = {}
var _goal: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_goal = _area_ids().size()
	_build_areas()
	_build_chips()


func teardown() -> void:
	for chip: TouchDraggable in _chips:
		if is_instance_valid(chip):
			chip.queue_free()
	_chips.clear()
	for area: Control in _areas.values():
		if is_instance_valid(area):
			area.queue_free()
	_areas.clear()
	_filled.clear()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	if _goal <= 0:
		return 1.0
	return clampf(float(_filled.size()) / float(_goal), 0.0, 1.0)


func _area_ids() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	return _ctx.step_def.slot_ids


func _expected_color(area_index: int) -> String:
	if _ctx == null or _ctx.step_def == null:
		return ""
	if area_index < _ctx.step_def.category_ids.size():
		return _ctx.step_def.category_ids[area_index]
	return ""


func _build_areas() -> void:
	if _ctx == null or _ctx.host == null:
		return
	var ids: PackedStringArray = _area_ids()
	for index: int in range(ids.size()):
		var area: Control = Control.new()
		area.name = ids[index]
		area.custom_minimum_size = TapButton.MIN_HIT_SIZE
		area.size = TapButton.MIN_HIT_SIZE
		area.position = Vector2(220.0 * float(index), 320.0)
		area.add_to_group("hit_target", true)
		area.mouse_filter = Control.MOUSE_FILTER_STOP
		var fill: ColorRect = ColorRect.new()
		fill.name = "Fill"
		fill.color = Color(0.85, 0.85, 0.85, 1.0)
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(fill)
		(_ctx.host as Control).add_child(area)
		if _ctx.nodes != null:
			_ctx.nodes.register(ids[index], area)
		_areas[ids[index]] = area


func _build_chips() -> void:
	if _ctx == null or _ctx.tray == null or _ctx.step_def == null:
		return
	for index: int in range(_ctx.step_def.item_ids.size()):
		var paint_id: String = _ctx.step_def.item_ids[index]
		var chip: TouchDraggable = TouchDraggable.new()
		chip.name = "Chip%d" % index
		chip.custom_minimum_size = TouchDraggable.MIN_HIT_SIZE
		chip.size = TouchDraggable.MIN_HIT_SIZE
		chip.position = Vector2(140.0 * float(index), 0.0)
		chip.payload_id = paint_id
		chip.add_to_group("hit_target", true)
		var swatch: ColorRect = ColorRect.new()
		swatch.color = PaintCatalog.color_of(paint_id)
		swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(swatch)
		chip.drag_ended.connect(_on_drag_end.bind(chip))
		_ctx.tray.add_child(chip)
		_chips.append(chip)


func _on_drag_end(chip: TouchDraggable) -> void:
	var area_id: String = _area_at(chip.global_position)
	if area_id.is_empty():
		TemplateKit.play_miss(_ctx)
		return
	var index: int = _area_ids().find(area_id)
	var want: String = _expected_color(index)
	if want != chip.payload_id or _filled.has(area_id):
		TemplateKit.play_miss(_ctx)
		return
	_filled[area_id] = true
	chip.queue_free()
	var area: Control = _areas.get(area_id) as Control
	if area != null:
		var fill: ColorRect = area.get_node_or_null("Fill") as ColorRect
		if fill != null:
			fill.color = PaintCatalog.color_of(want)
	TemplateKit.play_hit(_ctx, "template.fill", {"area": area_id, "color": want})
	if _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())


func _area_at(point: Vector2) -> String:
	for area_id: String in _areas.keys():
		var area: Control = _areas[area_id] as Control
		if area.get_global_rect().has_point(point):
			return area_id
	return ""
