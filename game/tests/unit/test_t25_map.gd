# story: e13s03
extends GutTest
## SC-e13s03-P0-03..05, P2-01. Locks refuse, catalogue ids only, no wallet.


func test_a_locked_door_refuses_and_points_at_care() -> void:
	var tpl: RefCounted = _mount()
	assert_true(bool(tpl.call("is_dimmed", "bath_door")))
	assert_eq(str(tpl.call("activate", "bath_door")), "")
	assert_true(bool(tpl.call("refused")))
	assert_eq(str(tpl.call("pointed_step")), "FEED", "SC-e13s03-P0-03")
	assert_gt(int(tpl.call("play_count")), 0)


func test_open_destination_resolves_a_known_scene() -> void:
	var tpl: RefCounted = _mount()
	tpl.call("set_open_steps", PackedStringArray(["FEED"]))
	var opened: String = str(tpl.call("activate", "bath_door"))
	assert_eq(opened, "bathroom", "SC-e13s03-P0-04")
	assert_false(opened.contains("res://"))


func test_unknown_destination_is_rejected() -> void:
	var tpl: RefCounted = _mount()
	assert_eq(str(tpl.call("activate", "secret_door")), "", "SC-e13s03-P0-05")


func test_template_never_reads_the_wallet() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t25_map.gd")
	assert_false(body.contains("get_coins"), "SC-e13s03-P2-01")
	assert_false(body.contains("try_paying"))
	assert_false(body.contains("res://"))


func test_both_aspects_reach_def_destinations() -> void:
	var tpl: RefCounted = _mount()
	for canvas: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		tpl.call("apply_view", Vector2(canvas))
		tpl.call("follow", Vector2(100.0, 400.0))
		assert_true(bool(tpl.call("reachable", "feed_door")), "SC-e13s03-P1-01 %s" % canvas)
		tpl.call("follow", Vector2(3600.0, 400.0))
		assert_true(bool(tpl.call("reachable", "play_door")), "far door %s" % canvas)


func test_probe_def_is_the_house_hub() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("home_map")
	assert_not_null(def)
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t25_map")
	assert_gt(step.world_size.x, 1920.0)
	assert_eq(step.destination_scenes.size(), step.destination_ids.size())


func _mount() -> RefCounted:
	var step: StepDef = _step()
	var tpl: RefCounted = TemplateCatalog.instantiate("t25_map")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	tpl.call("setup", ctx)
	return tpl


func _step() -> StepDef:
	var step: StepDef = StepDef.new()
	step.template_id = "t25_map"
	step.world_size = Vector2(4000.0, 1600.0)
	step.pan_tolerance = 24.0
	step.destination_ids = PackedStringArray(["feed_door", "bath_door", "play_door", "secret_door"])
	step.destination_scenes = PackedStringArray(["kitchen", "bathroom", "playroom", "not_a_room"])
	step.destination_locks = PackedStringArray(["", "FEED", "", ""])
	step.destination_positions = PackedVector2Array(
		[Vector2(100, 400), Vector2(800, 400), Vector2(3600, 400), Vector2(200, 200)]
	)
	step.on_miss_sfx_id = "sfx_soft_error"
	return step
