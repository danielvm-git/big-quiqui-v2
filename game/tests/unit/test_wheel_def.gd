# story: e14s04
extends GutTest
## SC-e14s04-P0-01, P1-01 — wheel pays once from EconomyData; templates stay roomless.


func before_each() -> void:
	TestReset.reset_all()


func test_wheel_def_loads_with_wheel_mode() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("wheel")
	assert_not_null(def)
	assert_eq(def.intro_voice_key, "vo.wheel.intro")
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t51_prize_pick")
	assert_eq(step.mode, "wheel")
	assert_eq(step.item_ids, PackedStringArray(["a", "b", "c"]))


func test_one_wheel_tap_spends_a_ticket_and_pays_coins_once() -> void:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_tickets", 2)
	var tpl: RefCounted = _mount_wheel()
	assert_true(bool(tpl.call("pick", "b")))
	assert_eq(int(progress.call("get_tickets")), 1, "SC-e14s04-P0-01 ticket spent")
	assert_eq(int(progress.call("get_coins")), 2, "prize b pays 2")
	assert_false(bool(tpl.call("pick", "c")))
	assert_eq(int(progress.call("get_tickets")), 1)
	assert_eq(int(progress.call("get_coins")), 2)


func test_templates_have_no_room_nouns_or_ads() -> void:
	var pick: String = SourceScanner.text("res://scripts/templates/t51_prize_pick.gd")
	var lanes: String = SourceScanner.text("res://scripts/templates/t50_lanes.gd")
	for body: String in [pick, lanes]:
		assert_false(body.contains("AddVideo"))
		assert_false(body.contains("wheel_scene"))
		assert_false(body.contains("penguin_scene"))
	assert_false(lanes.contains("DecreaseLife"))
	assert_false(lanes.contains("ShakeScreen"))


func _mount_wheel() -> RefCounted:
	var def: SceneDef = SceneDefLoader.load_by_id("wheel")
	var step: StepDef = def.steps[0] as StepDef
	var tray: Control = Control.new()
	tray.size = Vector2(800.0, 160.0)
	add_child_autofree(tray)
	var tpl: RefCounted = TemplateCatalog.instantiate("t51_prize_pick")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	return tpl
