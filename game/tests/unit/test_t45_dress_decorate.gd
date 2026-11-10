# story: e13s05
extends GutTest
## SC-e13s05-P1-01, P1-02. A snap saves the look. A bad id never reaches the file.


func before_each() -> void:
	TestReset.reset_all()


func test_snap_saves_and_the_bin_clears() -> void:
	var tpl: RefCounted = _mount()
	assert_true(bool(tpl.call("snap", "blue_scarf")))
	assert_eq(_progress().call("equipped", "neck"), "blue_scarf", "SC-e13s05-P1-01")
	assert_true(bool(tpl.call("bin", "blue_scarf")))
	assert_eq(_progress().call("equipped", "neck"), "")
	assert_gt(int(tpl.call("play_count")), 0)
	assert_eq(tpl.call("categories").size(), 1)


func test_binning_announces_the_change_once() -> void:
	var tpl: RefCounted = _mount()
	tpl.call("snap", "blue_scarf")
	watch_signals(_progress())
	assert_true(bool(tpl.call("bin", "blue_scarf")))
	assert_signal_emit_count(_progress(), "progress_changed", 1, "A11 the rig repaints once")
	assert_false(bool(_progress().call("equipped", "neck") != ""))


func test_an_invalid_id_does_not_save() -> void:
	var step: StepDef = StepDef.new()
	step.item_ids = PackedStringArray(["Nope"])
	step.slot_ids = PackedStringArray(["neck"])
	var tpl: RefCounted = TemplateCatalog.instantiate("t45_dress_decorate")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	var writes: int = int(_progress().get("write_count"))
	assert_false(bool(tpl.call("snap", "Nope")), "SC-e13s05-P1-02 the def lists the bad id")
	assert_eq(int(_progress().get("write_count")), writes, "SC-e13s05-P1-02 and nothing reaches save")


func test_a_refused_snap_or_place_answers_with_the_miss_sound() -> void:
	var recorder: ReactionRecorder = ReactionRecorder.new()
	var tpl: RefCounted = _mount_with_miss(recorder)
	assert_false(bool(tpl.call("snap", "banana")), "a food is not wearable, so the save refuses it")
	assert_eq(recorder.kinds(), ["sfx"], "A8 a refused snap is not silent")
	assert_false(bool(tpl.call("place", "vaso_planta", 0.5, 0.5)), "an unowned piece is refused")
	assert_eq(recorder.kinds(), ["sfx", "sfx"], "A8 a refused place is not silent")


func test_an_item_with_no_art_is_not_dressed() -> void:
	var step: StepDef = StepDef.new()
	step.item_ids = PackedStringArray(["no_such_item"])
	step.slot_ids = PackedStringArray(["neck"])
	var tpl: RefCounted = TemplateCatalog.instantiate("t45_dress_decorate")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	assert_false(bool(tpl.call("snap", "no_such_item")))
	assert_eq(_progress().call("equipped", "neck"), "")


func test_place_saves_a_ratio() -> void:
	var tpl: RefCounted = _mount()
	assert_true(bool(_progress().call("buy_furniture", "chair", 0)))
	assert_true(bool(tpl.call("place", "chair", 0.25, 0.5)))
	assert_eq(int(_progress().call("placed_count")), 1)


func test_only_shipped_pieces_in_their_own_slot_are_worn() -> void:
	var writes: int = int(_progress().get("write_count"))
	assert_false(bool(_progress().call("wear", "neck", "carrot")), "B3 a food id is not a scarf")
	assert_false(bool(_progress().call("wear", "head", "blue_scarf")), "B3 a scarf is not a hat")
	assert_false(bool(_progress().call("wear", "tail", "crown")), "B3 there is no tail slot")
	assert_eq(int(_progress().get("write_count")), writes, "B3 zero writes for a refused piece")
	assert_true(bool(_progress().call("wear", "neck", "blue_scarf")))


func test_a_def_that_names_a_food_for_a_slot_saves_nothing() -> void:
	var step: StepDef = StepDef.new()
	step.item_ids = PackedStringArray(["carrot"])
	step.slot_ids = PackedStringArray(["neck"])
	var tpl: RefCounted = TemplateCatalog.instantiate("t45_dress_decorate")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	assert_false(bool(tpl.call("snap", "carrot")))
	assert_eq(_progress().call("equipped", "neck"), "")


func test_a_tap_on_the_worn_piece_is_answered_and_confirms_the_look() -> void:
	var tpl: RefCounted = _mount_with_tray()
	tpl.call("snap", "blue_scarf")
	var again: RefCounted = _mount_with_tray()
	assert_true(bool(again.call("snap", "blue_scarf")), "A6 the scarf she wears on a return visit")
	assert_eq(_changes(again), 1, "A6 it answers, it is not a dead control")
	assert_almost_eq(float(again.call("progress")), 1.0, 0.001, "A6 and it counts, so the step can end")


func test_the_bin_acts_on_the_worn_slot_after_re_entry() -> void:
	var tpl: RefCounted = _mount_with_tray()
	tpl.call("snap", "blue_scarf")
	var again: RefCounted = _mount_with_tray()
	assert_true(bool(again.call("bin", "blue_scarf")), "A1 after re-entry the bin still takes the worn piece off")
	assert_eq(_progress().call("equipped", "neck"), "")


func test_the_bin_button_clears_a_saved_look_without_a_last_wear() -> void:
	_progress().call("wear", "neck", "blue_scarf")
	var tpl: RefCounted = _mount_with_tray()
	assert_eq(_progress().call("equipped", "neck"), "blue_scarf", "A1 setup dresses the saved look")
	assert_true(bool(tpl.call("bin")), "A1 the wired tap needs no item id")
	assert_eq(_progress().call("equipped", "neck"), "")


func test_a_category_tab_filters_the_strip_by_touch() -> void:
	var tpl: RefCounted = _mount_with_tray()
	assert_true(bool(_progress().call("buy_furniture", "chair", 0)), "the home item must be owned to show")
	assert_eq(tpl.call("visible_items").size(), 3)
	var tab: TapButton = (tpl.call("strip") as Control).find_child("tab_warm", true, false) as TapButton
	assert_not_null(tab, "A8 the categories are tabs")
	tab.press()
	assert_eq(tpl.call("visible_items"), PackedStringArray(["blue_scarf"]), "only the warm items stay")
	tab.press()
	assert_eq(tpl.call("visible_items").size(), 3, "the same tab again shows everything")


func test_a_finger_slides_the_strip_and_a_slide_over_an_item_does_not_wear_it() -> void:
	var tpl: RefCounted = _mount_with_tray(360.0)
	await wait_process_frames(2)
	var strip: Control = tpl.call("strip") as Control
	var pad: TouchPad = strip.get_node("StripPad") as TouchPad
	var scarf: TapButton = tpl.call("button", "blue_scarf") as TapButton
	var start: Vector2 = scarf.get_global_rect().get_center()
	_touch(pad, start, true)
	_drag(pad, start + Vector2(-90.0, 0.0))
	_touch(pad, start + Vector2(-90.0, 0.0), false)
	assert_gt(float(tpl.call("slide_offset")), 0.0, "A8 a finger drag slides the strip")
	assert_eq(_progress().call("equipped", "neck"), "", "A8 a slide that began on an item does not wear it")
	assert_eq(scarf.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the items take no touch of their own")
	var after: Vector2 = scarf.get_global_rect().get_center()
	_touch(pad, after, true)
	_touch(pad, after, false)
	assert_eq(_progress().call("equipped", "neck"), "blue_scarf", "and a tap on the slid item still wears it")


func test_a_slide_stops_at_the_end_of_the_row() -> void:
	var tpl: RefCounted = _mount_with_tray(360.0)
	await wait_process_frames(2)
	var pad: TouchPad = (tpl.call("strip") as Control).get_node("StripPad") as TouchPad
	var start: Vector2 = pad.get_global_rect().get_center()
	_touch(pad, start, true)
	_drag(pad, start + Vector2(-5000.0, 0.0))
	_touch(pad, start, false)
	var strip_width: float = (tpl.call("strip") as Control).size.x
	assert_lt(float(tpl.call("slide_offset")), 5000.0, "A8 the slide is clamped to the row")
	assert_gt(float(tpl.call("slide_offset")), 0.0)
	assert_lt(strip_width, 360.0)


func _touch(pad: TouchPad, point: Vector2, down: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = point
	event.pressed = down
	pad._gui_input(TouchSim.gui_event(pad, event))


func _drag(pad: TouchPad, point: Vector2) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.position = point
	pad._gui_input(TouchSim.gui_event(pad, event))


func test_a_tap_on_a_furniture_piece_places_it_free() -> void:
	var tpl: RefCounted = _mount_with_tray()
	assert_true(bool(_progress().call("buy_furniture", "chair", 0)))
	var button: TapButton = tpl.call("button", "chair") as TapButton
	assert_not_null(button)
	button.press()
	assert_eq(int(_progress().call("placed_count")), 1, "A8 free place is reachable by a tap")


func test_a_worn_piece_shows_on_the_rig_at_once() -> void:
	var rig: QuiQuiRig = QuiQuiRig.new()
	add_child_autofree(rig)
	var step: StepDef = StepDef.new()
	step.item_ids = PackedStringArray(["blue_scarf"])
	step.slot_ids = PackedStringArray(["neck"])
	var tpl: RefCounted = TemplateCatalog.instantiate("t45_dress_decorate")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.rig = rig
	tpl.call("setup", ctx)
	tpl.call("snap", "blue_scarf")
	assert_eq(rig.accessory_id("neck"), "blue_scarf", "A3 QuiQui changes with the tap")
	tpl.call("bin", "blue_scarf")
	assert_eq(rig.accessory_id("neck"), "", "and changes back with the bin")


func _changes(tpl: RefCounted) -> int:
	return int(tpl.get("_changes"))


func _mount_with_tray(width: float = 1200.0) -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t45_dress_decorate"
	step.item_ids = PackedStringArray(["blue_scarf", "crown", "chair"])
	step.slot_ids = PackedStringArray(["neck", "head", ""])
	step.category_ids = PackedStringArray(["warm", "royal", "home"])
	var tray: Control = Control.new()
	tray.size = Vector2(width, 160.0)
	add_child_autofree(tray)
	var tpl: RefCounted = TemplateCatalog.instantiate("t45_dress_decorate")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	return tpl


func _mount() -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t45_dress_decorate"
	step.item_ids = PackedStringArray(["blue_scarf"])
	step.slot_ids = PackedStringArray(["neck"])
	step.category_ids = PackedStringArray(["warm"])
	var tpl: RefCounted = TemplateCatalog.instantiate("t45_dress_decorate")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	return tpl


func _progress() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("ProgressManager")


func _mount_with_miss(recorder: ReactionRecorder) -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t45_dress_decorate"
	step.item_ids = PackedStringArray(["blue_scarf", "banana"])
	step.slot_ids = PackedStringArray(["neck", "neck"])
	step.on_miss_sfx_id = "sfx_heart"
	var tpl: RefCounted = TemplateCatalog.instantiate("t45_dress_decorate")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	ctx.reactions.recorder = recorder
	tpl.call("setup", ctx)
	return tpl
