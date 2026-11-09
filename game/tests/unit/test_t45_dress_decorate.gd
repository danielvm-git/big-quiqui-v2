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
	var tpl: RefCounted = _mount()
	var writes: int = int(_progress().get("write_count"))
	assert_false(bool(tpl.call("snap", "Nope")))
	assert_eq(int(_progress().get("write_count")), writes, "SC-e13s05-P1-02")


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
