# story: e13s02
extends GutTest
## SC-e13s02-P1-03..04. A spent target still answers, and nothing ends the step on a timer.


func test_a_spent_target_replays_without_moving_progress() -> void:
	var tpl: RefCounted = _mount("any")
	tpl.call("press", "apple")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001)
	tpl.call("press", "apple")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001, "SC-e13s02-P1-03")
	assert_eq(int(tpl.call("play_count")), 2, "the second tap still answers")


func test_each_target_has_its_own_pose_and_marks_itself() -> void:
	var step: StepDef = StepDef.new()
	step.on_hit_pose = "pleased"
	step.item_ids = PackedStringArray(["apple", "grape"])
	step.hit_poses = PackedStringArray(["", "surprised"])
	assert_eq(TemplateKit.pose_for(step, 0), "pleased", "A11 an empty entry uses the step pose")
	assert_eq(TemplateKit.pose_for(step, 1), "surprised", "A11 the grape answers in its own way")
	assert_eq(TemplateKit.pose_for(step, -1), "pleased")
	var tpl: RefCounted = _mount("any")
	var apple: TapButton = tpl.get("_buttons")["apple"] as TapButton
	assert_eq(apple.visual.modulate, Color.WHITE, "a fresh target is bright")
	tpl.call("press", "apple")
	assert_lt(apple.visual.modulate.r, 1.0, "A11 a spent target marks itself")


func test_a_toggle_target_dims_only_while_it_is_on() -> void:
	var tpl: RefCounted = _mount("toggle")
	var apple: TapButton = tpl.get("_buttons")["apple"] as TapButton
	tpl.call("press", "apple")
	assert_lt(apple.visual.modulate.r, 1.0)
	tpl.call("press", "apple")
	assert_eq(apple.visual.modulate, Color.WHITE, "off again, bright again")


func test_the_template_has_no_auto_end_timer() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t21_touch_each.gd")
	assert_false(body.contains("AddAutoEndTimer"), "SC-e13s02-P1-04")
	assert_false(body.contains("Timer"))
	assert_false(body.to_lower().contains("market"))


func test_probe_def_uses_the_template() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("touch_each_probe")
	assert_not_null(def)
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t21_touch_each")
	assert_eq(step.mode, "count_n", "A7 the shipped probe really asks for each one")
	assert_eq(step.repeat_count, 2)


func test_targets_meet_the_hit_floor() -> void:
	var tpl: RefCounted = _mount("count_n")
	var size: Vector2 = tpl.call("button_size", "apple")
	assert_gte(size.x, GeometryOracle.MIN_HIT_SIZE.x, "SC-e13s02-P2-01")
	assert_gte(size.y, GeometryOracle.MIN_HIT_SIZE.y)


func test_the_squash_runs_and_the_target_has_a_picture() -> void:
	var tpl: RefCounted = _mount("any")
	var button: TapButton = tpl.get("_buttons")["apple"] as TapButton
	assert_false(button.manual_step, "A6 the shipped button steps itself")
	assert_not_null(button.visual.get_node_or_null("Art"), "A6 the target is a picture")
	assert_eq((button.visual.get_node("Art") as TextureRect).texture.resource_path, "res://assets/art/items/apple.png")
	button.press()
	assert_true(button.is_squashing())


func test_toggle_is_done_when_every_target_is_on() -> void:
	var tpl: RefCounted = _mount("toggle")
	tpl.call("press", "apple")
	assert_lt(float(tpl.call("progress")), 1.0)
	tpl.call("press", "grape")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001, "A9 toggle has an exit")


func test_a_goal_above_the_targets_still_finishes() -> void:
	var tpl: RefCounted = _mount("count_n", 9)
	tpl.call("press", "apple")
	tpl.call("press", "grape")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001, "A9 goal is clamped to the targets")


func test_a_duplicate_id_builds_one_button() -> void:
	var tpl: RefCounted = _mount("any", 1, PackedStringArray(["apple", "apple", "grape"]))
	assert_eq((tpl.get("_buttons") as Dictionary).size(), 2, "A21 no leaked twin")


func _mount(
	mode_name: String, goal: int = 2, ids: PackedStringArray = PackedStringArray(["apple", "grape"])
) -> RefCounted:
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var step: StepDef = StepDef.new()
	step.template_id = "t21_touch_each"
	step.mode = mode_name
	step.repeat_count = goal
	step.item_ids = ids
	step.on_hit_pose = "pleased"
	var tpl: RefCounted = TemplateCatalog.instantiate("t21_touch_each")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.tray = tray
	ctx.host = tray
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	tpl.call("setup", ctx)
	return tpl
