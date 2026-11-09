# story: e13s05
extends PlayerTestCase
## Review round 1 (A5, B1, B2, B3). The dress strip, the reward star, the prize pair and the title
## verb are real tap surfaces that a finger can reach once the player mounts them.


func before_each() -> void:
	TestReset.reset_all()


func test_the_title_verb_is_one_tap_and_completes_the_def() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("title_probe"))
	var verb: TapButton = player.find_child("play_button", true, false) as TapButton
	assert_not_null(verb, "the verb is on the host")
	var live: int = 0
	for child: Node in player.get_children():
		if child is TapButton and (child as TapButton).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			live += 1
	assert_eq(live, 1, "A5 B6 the verb is the only target on the shipped player, Home included")
	assert_true(verb.size.x >= TapButton.MIN_HIT_SIZE.x and verb.size.y >= TapButton.MIN_HIT_SIZE.y)
	assert_not_null(verb.get_node_or_null("Visual/Art"), "the verb has a picture")
	finger_tap(player, verb)
	await _settle(player)
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT])


func test_the_reward_star_collects_once_and_carries_on() -> void:
	CareWalk.to_celebrate((Engine.get_main_loop() as SceneTree).root.get_node("CareLoopManager"))
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("reward_probe"))
	var star: TapButton = _taps(player)[0]
	var before: int = int(_progress().call("get_coins"))
	await _settle(player)
	assert_eq(player.runner.step_index, 0, "the step waits for the child")
	finger_tap(player, star)
	await _settle(player)
	assert_eq(
		int(_progress().call("get_coins")), before, "the cycle paid once at the celebration, the tap never pays again"
	)
	assert_true(bool(_progress().call("owns_furniture", "vaso_planta")), "and the gift is free")
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT])


func test_a_second_visit_shows_the_star_lit_and_pays_nothing() -> void:
	CareWalk.to_celebrate((Engine.get_main_loop() as SceneTree).root.get_node("CareLoopManager"))
	var first: ScenePlayer = await mount(SceneDefLoader.load_by_id("reward_probe"))
	var star: TapButton = _taps(first)[0]
	finger_tap(first, star)
	var paid: int = int(_progress().call("get_coins"))
	var again: ScenePlayer = await mount(SceneDefLoader.load_by_id("reward_probe"))
	var lit: TapButton = _taps(again)[0]
	assert_eq(lit.visual.modulate.a, 1.0, "the star is already lit")
	finger_tap(again, lit)
	assert_eq(int(_progress().call("get_coins")), paid, "a second visit never pays")


func test_touching_each_object_through_the_player_completes_the_step() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("touch_each_probe"))
	var buttons: Array[TapButton] = _taps(player)
	assert_eq(buttons.size(), 2, "one target per item in the def")
	finger_tap(player, buttons[0])
	assert_lt(buttons[0].visual.modulate.r, 1.0, "A11 the tapped object marks itself")
	finger_tap(player, buttons[0])
	await _settle(player)
	assert_eq(player.runner.step_index, 0, "A7 the same object twice is not each object")
	assert_false(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT], "so the step is live")
	finger_tap(player, buttons[1])
	await _settle(player)
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT], "A14 each one ends it")


func test_rubbing_the_reveal_layers_through_the_player_completes_the_step() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("rub_reveal_probe"))
	var tool: Control = rub_tool(player)
	assert_not_null(tool, "A14 the brush is in the tray")
	assert_not_null(player.get_node_or_null("crumbs"), "the layers come from the def and have art")
	var hull: PackedVector2Array = (player.get_node("QuiQuiRig") as QuiQuiRig).scrub_hull_global()
	rub_hull(tool, hull)
	await _settle(player)
	assert_true(
		player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT], "the rub reveals both layers"
	)


func test_one_prize_tap_saves_and_the_other_does_nothing() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("prize_probe"))
	var buttons: Array[TapButton] = _taps(player)
	assert_eq(buttons.size(), 2, "one target per prize in the def")
	finger_tap(player, buttons[0])
	assert_eq(_progress().call("picked_prize"), "plush")
	finger_tap(player, buttons[1])
	assert_eq(_progress().call("picked_prize"), "plush", "no second pick")
	await _settle(player)
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT])


func test_the_dress_strip_snaps_and_the_bin_clears() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("dress_probe"))
	var strip: Control = player.get_node("TrayZone").get_node_or_null("DressStrip") as Control
	assert_not_null(strip, "the strip is in the tray")
	var scarf: TapButton = strip.find_child("blue_scarf", true, false) as TapButton
	assert_not_null(scarf)
	finger_tap(player, scarf)
	assert_eq(_progress().call("equipped", "neck"), "blue_scarf")
	var bin: TapButton = player.get_node("TrayZone").get_node("trash_bag") as TapButton
	finger_tap(player, bin)
	assert_eq(_progress().call("equipped", "neck"), "", "the bin takes it off")


func test_a_finger_drag_across_a_long_strip_slides_it_and_wears_nothing() -> void:
	var step: StepDef = StepDef.new()
	step.template_id = "t45_dress_decorate"
	step.item_ids = PackedStringArray(FurnitureCatalog.FURNITURE_IDS)
	var def: SceneDef = SceneDefFactory.valid()
	def.steps = [step] as Array[Resource]
	var player: ScenePlayer = await mount(def)
	await wait_process_frames(2)
	var template: RefCounted = player.get("_template") as RefCounted
	var strip: Control = template.call("strip") as Control
	var first: Control = template.call("button", FurnitureCatalog.FURNITURE_IDS[0]) as Control
	var pad: Control = strip.get_node("StripPad") as Control
	var start: Vector2 = first.get_global_rect().get_center()
	assert_eq(HitProbe.top_at(player, start), pad, "A8 the finger lands on the strip pad")
	send(pad, touch(start, true))
	send(pad, drag(start + Vector2(-200.0, 0.0)))
	send(pad, touch(start + Vector2(-200.0, 0.0), false))
	assert_gt(float(template.call("slide_offset")), 0.0, "A8 a finger drag slides a strip longer than the tray")
	assert_eq(int(_progress().call("placed_count")), 0, "A8 and the item under the finger is not placed")


func _taps(player: ScenePlayer) -> Array[TapButton]:
	var found: Array[TapButton] = []
	_collect(player.get_node("TrayZone"), found)
	return found


func _collect(node: Node, into: Array[TapButton]) -> void:
	for child: Node in node.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is TapButton and child.is_in_group("hit_target"):
			into.append(child as TapButton)
		_collect(child, into)


func _settle(player: ScenePlayer) -> void:
	for _tick: int in range(8):
		player.advance(0.2)
	await wait_process_frames(1)


func _progress() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("ProgressManager")
