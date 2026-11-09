# story: e13s04
extends PlayerTestCase
## SC-e13s04-P0-04. Soap, rinse and dry are three steps of one def, played through the player.

const PROBE: String = "bathroom_probe"


func before_each() -> void:
	TestReset.reset_all()


func test_the_bathroom_def_names_three_templates() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id(PROBE)
	assert_not_null(def)
	assert_eq(def.steps.size(), 3)
	assert_eq((def.steps[0] as StepDef).template_id, "t40_draw_fill")
	assert_eq((def.steps[1] as StepDef).template_id, "t23_erase")
	assert_eq((def.steps[2] as StepDef).template_id, "t23_erase")


func test_the_player_mounts_a_tool_and_a_layer_from_the_def() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	var tool: Control = rub_tool(player)
	assert_not_null(tool, "A2 the tool comes from the template")
	assert_not_null(tool.get_node_or_null("Art"), "the tool has a picture")
	assert_eq(tool.size, TouchDraggable.MIN_HIT_SIZE)
	assert_not_null(player.get_node_or_null("foam"), "the layer is named by the def")


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


func test_other_tray_children_ignore_touch_while_the_tool_is_held() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(PROBE))
	var tray: Control = player.get_node("TrayZone") as Control
	var other: Control = Control.new()
	other.mouse_filter = Control.MOUSE_FILTER_STOP
	tray.add_child(other)
	var tool: Control = rub_tool(player)
	send(tool, touch(tool.get_global_rect().get_center(), true))
	assert_eq(other.mouse_filter, Control.MOUSE_FILTER_IGNORE, "SC-e13s04 tray holds while rubbing")
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
