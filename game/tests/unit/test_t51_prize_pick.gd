# story: e13s09
extends GutTest
## SC-e13s09-P1-01, P1-02, P2-01. One pick is saved. There is no second pick and no ad.


func before_each() -> void:
	TestReset.reset_all()


func test_one_tap_saves_one_prize() -> void:
	var first: RefCounted = _mount()
	assert_true(bool(first.call("pick", "plush")))
	assert_eq(_progress().call("picked_prize"), "plush", "SC-e13s09-P1-01")
	assert_false(bool(first.call("pick", "pinwheel")), "SC-e13s09-P1-02")
	assert_eq(_progress().call("picked_prize"), "plush")
	var again: RefCounted = _mount()
	assert_eq(str(again.call("picked")), "plush")
	assert_false(bool(again.call("pick", "pinwheel")))


func test_the_next_cycle_opens_a_fresh_wheel() -> void:
	var first: RefCounted = _mount()
	assert_true(bool(first.call("pick", "plush")))
	_progress().call("complete_cycle")
	var next: RefCounted = _mount()
	assert_eq(str(next.call("picked")), "", "A17 a new cycle starts with nothing picked")
	assert_true(bool(next.call("pick", "pinwheel")), "the second cycle may pick again")
	assert_eq(_progress().call("picked_prize"), "pinwheel")


func test_the_step_is_three_named_states() -> void:
	var tpl: RefCounted = _mount()
	assert_eq(float(tpl.call("progress")), 0.0, "OPEN: nothing is picked")
	tpl.call("pick", "plush")
	assert_eq(float(tpl.call("progress")), 1.0, "DONE after one pick")
	var again: RefCounted = _mount()
	assert_eq(float(again.call("progress")), 0.0, "PICKED waits for one tap")
	again.call("pick", "pinwheel")
	assert_eq(float(again.call("progress")), 0.0, "a tap on the other prize does not carry on")
	again.call("pick", "plush")
	assert_eq(float(again.call("progress")), 1.0, "a tap on the saved prize carries on")


func test_a_saved_prize_that_is_not_in_this_def_still_lets_one_tap_carry_on() -> void:
	_progress().call("pick_prize", "teddy")
	var tpl: RefCounted = _mount()
	assert_eq(str(tpl.call("picked")), "", "A10 the saved prize is not on this wheel")
	assert_eq(float(tpl.call("progress")), 0.0)
	tpl.call("pick", "pinwheel")
	assert_eq(float(tpl.call("progress")), 1.0, "A10 one tap carries on, so the step is never stuck")
	assert_eq(_progress().call("picked_prize"), "teddy", "and the cycle's pick is not rewritten")


func test_a_prize_never_lands_in_the_outfit_map() -> void:
	var first: RefCounted = _mount()
	first.call("pick", "plush")
	assert_eq(_progress().call("equipped", "prize"), "", "A17 the prize has its own ledger")


func test_prizes_come_from_the_def_and_there_is_no_ad() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t51_prize_pick.gd")
	assert_false(body.contains("plush"), "SC-e13s09-P2-01")
	assert_false(body.contains("AddVideo"))
	assert_false(body.contains("video_ad"))
	assert_false(body.contains("advert"))


func _mount() -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t51_prize_pick"
	step.item_ids = PackedStringArray(["plush", "pinwheel"])
	var tpl: RefCounted = TemplateCatalog.instantiate("t51_prize_pick")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	return tpl


func _progress() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("ProgressManager")
