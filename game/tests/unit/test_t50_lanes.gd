# story: e13s08
extends GutTest
## SC-e13s08-P0-03, P1-01. A catch scores. A miss does not. Nothing is a weapon.


func test_a_catch_scores_when_the_fruit_lands_in_the_basket_lane() -> void:
	var tpl: RefCounted = _mount()
	tpl.call("tick")
	var lane: int = int(tpl.call("first_lane"))
	assert_gte(lane, 0)
	tpl.call("release_on_lane", lane)
	assert_eq(int(tpl.call("score")), 0, "SC-e13s08-P0-03 nothing is caught while it is still falling")
	for _i: int in range(6):
		tpl.call("tick")
	assert_gte(int(tpl.call("score")), 1, "SC-e13s08-P0-03 catch")


func test_a_miss_does_not_score() -> void:
	var tpl: RefCounted = _mount()
	tpl.call("tick")
	var lane: int = int(tpl.call("first_lane"))
	tpl.call("release_on_lane", (lane + 1) % 2)
	for _i: int in range(6):
		tpl.call("tick")
	assert_gt(int(tpl.call("misses")), 0, "SC-e13s08-P0-03 miss")


func test_the_template_has_no_weapon_and_no_lives() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t50_lanes.gd")
	assert_false(body.contains("ShootBullet"), "SC-e13s08-P1-01")
	assert_false(body.contains("DecreaseLife"))
	assert_false(body.contains("ShakeScreen"))
	assert_false(body.contains("projectile"))


func _mount() -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t50_lanes"
	step.item_ids = PackedStringArray(["fish"])
	step.lane_count = 2
	step.spawn_seed = 1
	step.spawn_cadence = 1
	step.spawn_lifetime = 4
	step.goal_count = 3
	var tpl: RefCounted = TemplateCatalog.instantiate("t50_lanes")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	return tpl
