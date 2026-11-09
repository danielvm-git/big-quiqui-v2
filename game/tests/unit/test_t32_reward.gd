# story: e13s05
extends GutTest
## SC-e13s05-P1-04, P2-01. The reward pays once. There is no ad branch.


func before_each() -> void:
	TestReset.reset_all()


func test_the_reward_pays_once_and_stays_lit() -> void:
	var first: RefCounted = _mount()
	var before: int = int(_progress().call("get_coins"))
	assert_true(bool(first.call("collect")))
	var paid: int = int(_progress().call("get_coins"))
	assert_gt(paid, before, "SC-e13s05-P1-04")
	assert_false(bool(first.call("collect")))
	assert_eq(int(_progress().call("get_coins")), paid)
	var again: RefCounted = _mount()
	assert_true(bool(again.call("star_lit")))
	assert_false(bool(again.call("collect")))
	assert_eq(int(_progress().call("get_coins")), paid)
	assert_eq(str(again.call("gift_id")), "sticker")


func test_the_reward_template_has_no_ad_branch() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t32_reward.gd")
	assert_false(body.contains("video_ad"), "SC-e13s05-P2-01")
	assert_false(body.contains("AddVideo"))
	assert_false(body.contains("advert"))


func _mount() -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t32_reward"
	step.item_ids = PackedStringArray(["sticker"])
	var tpl: RefCounted = TemplateCatalog.instantiate("t32_reward")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	return tpl


func _progress() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("ProgressManager")
