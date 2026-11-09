# story: e13s05
extends GutTest
## SC-e13s05-P1-04, P2-01. The reward pays once. There is no ad branch.


func before_each() -> void:
	TestReset.reset_all()


func test_the_reward_pays_once_and_stays_lit() -> void:
	CareWalk.to_celebrate((Engine.get_main_loop() as SceneTree).root.get_node("CareLoopManager"))
	var first: RefCounted = _mount()
	var before: int = int(_progress().call("get_coins"))
	assert_true(bool(first.call("collect")))
	var paid: int = int(_progress().call("get_coins"))
	assert_eq(paid, before, "SC-e13s05-P1-04 the cycle paid at the celebration, the tap never pays again")
	assert_false(bool(first.call("collect")))
	assert_eq(int(_progress().call("get_coins")), paid)
	var again: RefCounted = _mount()
	assert_true(bool(again.call("star_lit")))
	assert_false(bool(again.call("collect")))
	assert_eq(int(_progress().call("get_coins")), paid)
	assert_eq(str(again.call("gift_id")), "vaso_planta")


func test_a_reward_already_paid_on_entry_still_waits_for_the_tap() -> void:
	var loop: Node = (Engine.get_main_loop() as SceneTree).root.get_node("CareLoopManager")
	loop.call("_grant_cycle_reward")
	var paid: int = int(_progress().call("get_coins"))
	var tpl: RefCounted = _mount()
	assert_true(bool(loop.call("reward_paid")))
	assert_false(bool(tpl.call("star_lit")), "paid is not seen: the star is lit by the tap")
	assert_true(bool(tpl.call("collect")), "the first tap collects")
	assert_eq(int(_progress().call("get_coins")), paid, "and never pays twice")
	assert_true(bool(_mount().call("star_lit")))


func test_the_gift_is_free_and_owned_once() -> void:
	CareWalk.to_celebrate((Engine.get_main_loop() as SceneTree).root.get_node("CareLoopManager"))
	var tpl: RefCounted = _mount()
	tpl.call("collect")
	assert_true(bool(_progress().call("owns_furniture", "vaso_planta")))
	assert_eq(int(_progress().call("owned_count")), 1)
	tpl.call("collect")
	assert_eq(int(_progress().call("owned_count")), 1)


func test_a_tap_before_the_celebration_pays_nothing_and_carries_on() -> void:
	var tpl: RefCounted = _mount()
	var before: int = int(_progress().call("get_coins"))
	assert_false(bool(tpl.call("collect")), "A7 the reward is earned by finishing the cycle")
	assert_eq(int(_progress().call("get_coins")), before)
	assert_eq(tpl.call("progress"), 1.0, "the step still goes on")
	assert_false(bool(_progress().call("owns_furniture", "vaso_planta")))


func test_the_star_is_three_named_states() -> void:
	var tpl: RefCounted = _mount()
	assert_false(bool(tpl.call("star_lit")), "UNLIT")
	assert_eq(float(tpl.call("progress")), 0.0)
	tpl.call("collect")
	assert_true(bool(tpl.call("star_lit")), "LIT, then DONE on the same tap")
	assert_eq(float(tpl.call("progress")), 1.0)
	assert_false(bool(tpl.call("collect")), "a second tap collects nothing")
	assert_eq(float(tpl.call("progress")), 1.0)


func test_the_reward_template_has_no_ad_branch() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t32_reward.gd")
	assert_false(body.contains("video_ad"), "SC-e13s05-P2-01")
	assert_false(body.contains("AddVideo"))
	assert_false(body.contains("advert"))


func _mount() -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t32_reward"
	step.item_ids = PackedStringArray(["vaso_planta"])
	var tpl: RefCounted = TemplateCatalog.instantiate("t32_reward")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	return tpl


func _progress() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("ProgressManager")
