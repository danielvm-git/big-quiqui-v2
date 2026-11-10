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
	var log: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Log")
	var before: int = int(log.call("write_count"))
	var tpl: RefCounted = _mount()
	assert_eq(str(tpl.call("activate", "secret_door")), "", "SC-e13s03-P0-05")
	assert_gt(int(log.call("write_count")), before)
	var diary: String = FileAccess.get_file_as_string(str(log.get("log_path")))
	assert_true(diary.contains("map.destination_rejected"), "SC-e13s03-P0-05 the rejection is logged")


func test_a_short_lock_list_fails_closed() -> void:
	var step: StepDef = _step()
	step.destination_locks = PackedStringArray([""])
	var tpl: RefCounted = TemplateCatalog.instantiate("t25_map")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	tpl.call("setup", ctx)
	assert_eq(str(tpl.call("activate", "feed_door")), "")
	assert_true(bool(tpl.call("is_dimmed", "feed_door")))


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


func test_the_room_opens_on_the_first_open_door() -> void:
	var step: StepDef = _step()
	step.destination_positions = PackedVector2Array([Vector2(3600.0, 400.0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var tpl: RefCounted = TemplateCatalog.instantiate("t25_map")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	tpl.call("setup", ctx)
	assert_gt((tpl.call("offset") as Vector2).x, 1000.0, "A12 follow runs when the room opens")


func test_a_resize_clamps_the_view_again() -> void:
	var host: Control = Control.new()
	host.size = Vector2(1000.0, 800.0)
	add_child_autofree(host)
	var tpl: RefCounted = TemplateCatalog.instantiate("t25_map")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = _step()
	ctx.host = host
	tpl.call("setup", ctx)
	tpl.call("follow", Vector2(3900.0, 400.0))
	var before: float = (tpl.call("offset") as Vector2).x
	host.size = Vector2(3000.0, 800.0)
	assert_lt((tpl.call("offset") as Vector2).x, before, "A12 a wider canvas shows more world, so the offset clamps")
	tpl.call("teardown")
	assert_false(host.resized.is_connected(tpl.get("_on_resized")), "and the listener left with the step")


func test_probe_def_is_the_house_hub() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("home_map")
	assert_not_null(def)
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t25_map")
	assert_gt(step.world_size.x, 1920.0)
	assert_eq(step.destination_scenes.size(), step.destination_ids.size())
	assert_eq(step.destination_locks.size(), step.destination_ids.size())
	assert_eq(step.destination_positions.size(), step.destination_ids.size())


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
