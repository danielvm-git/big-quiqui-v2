# story: e13s09
extends GutTest
## SC-e13s09-P1-01, P1-02, P2-01. One pick is saved. There is no second pick and no ad.


func before_each() -> void:
	TestReset.reset_all()


func test_one_tap_saves_one_prize() -> void:
	var first: RefCounted = _mount()
	assert_true(bool(first.call("pick", "plush")))
	assert_eq(_progress().call("equipped", "prize"), "plush", "SC-e13s09-P1-01")
	assert_false(bool(first.call("pick", "pinwheel")), "SC-e13s09-P1-02")
	assert_eq(_progress().call("equipped", "prize"), "plush")
	var again: RefCounted = _mount()
	assert_eq(str(again.call("picked")), "plush")
	assert_false(bool(again.call("pick", "pinwheel")))


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
