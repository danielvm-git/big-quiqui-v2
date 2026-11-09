# story: e13s04
extends PlayerTestCase
## SC-e13s04-P0-04. Soap, rinse and dry are three steps of one def, played through the player.

const PROBE: String = "bathroom_probe"


func before_each() -> void:
	TestReset.reset_all()


func test_the_bathroom_def_names_three_templates() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id(PROBE)
	assert_not_null(def, "SC-e13s04-P0-04 the bathroom probe loads")
	assert_eq(def.steps.size(), 3, "SC-e13s04-P0-04 soap rinse and dry are three steps")
	assert_eq((def.steps[0] as StepDef).template_id, "t40_draw_fill")
	assert_eq((def.steps[1] as StepDef).template_id, "t23_erase")
	assert_eq((def.steps[2] as StepDef).template_id, "t23_erase")


func test_the_player_mounts_a_tool_and_a_layer_from_the_def() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	var tool: Control = rub_tool(player)
	assert_not_null(tool, "A2 the tool comes from the template")
	assert_not_null(tool.get_node_or_null("Art"), "the tool has a picture")
	assert_eq(tool.size, TouchDraggable.MIN_HIT_SIZE)
	assert_not_null(player.get_node_or_null("foam_large"), "the layer is named by the def")


func test_the_soap_stays_for_the_rinse_to_clear_and_the_dry_layer_comes_after() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	var hull: PackedVector2Array = (player.get_node("QuiQuiRig") as QuiQuiRig).scrub_hull_global()
	rub_hull(rub_tool(player), hull)
	for _tick: int in range(6):
		player.advance(0.2)
	await wait_process_frames(1)
	assert_eq(player.runner.step_index, 1, "the soap step is done")
	var foam: Control = player.get_node_or_null("foam_large") as Control
	assert_not_null(foam, "A10 the soap is still on QuiQui for the rinse")
	assert_gt(foam.modulate.a, 0.9)
	rub_hull(rub_tool(player), hull)
	for _tick: int in range(6):
		player.advance(0.2)
	await wait_process_frames(2)
	assert_eq(player.runner.step_index, 2, "the rinse step is done")
	assert_true(not is_instance_valid(foam) or foam.is_queued_for_deletion(), "the rinse took the soap off")
	assert_not_null(player.get_node_or_null("droplet"), "the dry step has its own layer")


func test_rubbing_the_real_tool_completes_each_step_and_chains() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	for index: int in range(3):
		assert_eq(player.runner.step_index, index, "step %d is live" % index)
		var tool: Control = rub_tool(player)
		var hull: PackedVector2Array = (player.get_node("QuiQuiRig") as QuiQuiRig).scrub_hull_global()
		assert_gt(hull.size(), 2, "the rig reports a hull")
		rub_hull(tool, hull)
		for _tick: int in range(6):
			player.advance(0.2)
		await wait_process_frames(1)
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT], "all three steps are done")
	assert_eq(player.runner.step_index, 3)


func test_the_same_rub_path_makes_the_same_progress_at_both_aspects() -> void:
	var wide: Array[float] = await _progress_trace(GeometryOracle.DESKTOP_16_9, GeometryOracle.DESKTOP_16_9)
	var ipad: Array[float] = await _progress_trace(GeometryOracle.IPAD_4_3, GeometryOracle.IPAD_4_3)
	assert_gt(wide[wide.size() - 1], 0.3, "SC-e13s01-P1-02 the path really rubs something")
	assert_eq(ipad.size(), wide.size())
	for index: int in range(mini(wide.size(), ipad.size())):
		assert_almost_eq(ipad[index], wide[index], 0.001, "SC-e13s01-P1-02 point %d" % index)


func test_a_path_not_mapped_to_the_rig_at_4_3_makes_different_progress() -> void:
	var wide: Array[float] = await _progress_trace(GeometryOracle.DESKTOP_16_9, GeometryOracle.DESKTOP_16_9)
	var skewed: Array[float] = await _progress_trace(GeometryOracle.IPAD_4_3, GeometryOracle.DESKTOP_16_9)
	assert_ne(skewed, wide, "the control fails: pixels laid out for 16:9 do not rub the 4:3 rig the same")


## Progress after each point of a path laid over the hull of the rig at `path_for`, rubbed at `aspect`.
func _progress_trace(aspect: Vector2i, path_for: Vector2i) -> Array[float]:
	var reference: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE), path_for)
	var box: Rect2 = _hull_box(reference)
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE), aspect)
	var tool: Control = rub_tool(player)
	var template: RefCounted = player.get("_template") as RefCounted
	send(tool, touch(tool.get_global_rect().get_center(), true))
	var trace: Array[float] = []
	for col: int in range(RubPrimitive.CELL_EDGE):
		for row: int in range(RubPrimitive.CELL_EDGE / 2):
			var at: Vector2 = box.position + box.size * Vector2((float(col) + 0.5) / 4.0, (float(row) + 0.5) / 4.0)
			send(tool, drag(at))
			trace.append(float(template.call("progress")))
	send(tool, touch(box.get_center(), false))
	return trace


func _hull_box(player: ScenePlayer) -> Rect2:
	var hull: PackedVector2Array = (player.get_node("QuiQuiRig") as QuiQuiRig).scrub_hull_global()
	var box: Rect2 = Rect2(hull[0], Vector2.ZERO)
	for point: Vector2 in hull:
		box = box.expand(point)
	return box


func test_other_tray_children_ignore_touch_while_the_tool_is_held() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	var tray: Control = player.get_node("TrayZone") as Control
	var other: Control = Control.new()
	other.mouse_filter = Control.MOUSE_FILTER_STOP
	tray.add_child(other)
	var tool: Control = rub_tool(player)
	send(tool, touch(tool.get_global_rect().get_center(), true))
	assert_eq(other.mouse_filter, Control.MOUSE_FILTER_IGNORE, "SC-e13s04-P1-01 the tray holds while rubbing")
	assert_true(tool.visible and other.visible, "but nothing is hidden")
	send(tool, touch(tool.get_global_rect().get_center(), false))
	assert_eq(other.mouse_filter, Control.MOUSE_FILTER_STOP, "and it comes back")


func test_leaving_the_step_frees_the_tool_the_layer_and_the_loop() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	var before: int = player.get_child_count()
	player.runner.request_home()
	player.advance(0.2)
	await wait_process_frames(2)
	assert_lt(player.get_child_count(), before, "the layer left with the step")
	assert_null(rub_tool(player))
