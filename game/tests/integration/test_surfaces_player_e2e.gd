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
	assert_eq(live, 2, "only the verb and Home take touches")
	assert_true(verb.size.x >= TapButton.MIN_HIT_SIZE.x and verb.size.y >= TapButton.MIN_HIT_SIZE.y)
	assert_not_null(verb.get_node_or_null("Visual/Art"), "the verb has a picture")
	send(verb, touch(verb.get_global_rect().get_center(), true))
	await _settle(player)
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT])


func test_the_reward_star_collects_once_and_carries_on() -> void:
	CareWalk.to_celebrate((Engine.get_main_loop() as SceneTree).root.get_node("CareLoopManager"))
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("reward_probe"))
	var star: TapButton = _taps(player)[0]
	var before: int = int(_progress().call("get_coins"))
	await _settle(player)
	assert_eq(player.runner.step_index, 0, "the step waits for the child")
	send(star, touch(star.get_global_rect().get_center(), true))
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
	send(star, touch(star.get_global_rect().get_center(), true))
	var paid: int = int(_progress().call("get_coins"))
	var again: ScenePlayer = await mount(SceneDefLoader.load_by_id("reward_probe"))
	var lit: TapButton = _taps(again)[0]
	assert_eq(lit.visual.modulate.a, 1.0, "the star is already lit")
	send(lit, touch(lit.get_global_rect().get_center(), true))
	assert_eq(int(_progress().call("get_coins")), paid, "a second visit never pays")


func test_touching_each_object_through_the_player_completes_the_step() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("touch_each_probe"))
	var buttons: Array[TapButton] = _taps(player)
	assert_eq(buttons.size(), 2, "one target per item in the def")
	send(buttons[0], touch(buttons[0].get_global_rect().get_center(), true))
	assert_lt(buttons[0].visual.modulate.r, 1.0, "A11 the tapped object marks itself")
	await _settle(player)
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT], "A14 any tap ends it")


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
	send(buttons[0], touch(buttons[0].get_global_rect().get_center(), true))
	assert_eq(_progress().call("picked_prize"), "plush")
	send(buttons[1], touch(buttons[1].get_global_rect().get_center(), true))
	assert_eq(_progress().call("picked_prize"), "plush", "no second pick")
	await _settle(player)
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT])


func test_the_dress_strip_snaps_and_the_bin_clears() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("dress_probe"))
	var strip: ScrollContainer = player.get_node("TrayZone").get_node_or_null("DressStrip") as ScrollContainer
	assert_not_null(strip, "the strip is a scroll container in the tray")
	var scarf: TapButton = strip.find_child("blue_scarf", true, false) as TapButton
	assert_not_null(scarf)
	send(scarf, touch(scarf.get_global_rect().get_center(), true))
	assert_eq(_progress().call("equipped", "neck"), "blue_scarf")
	var bin: TapButton = player.get_node("TrayZone").get_node("trash_bag") as TapButton
	send(bin, touch(bin.get_global_rect().get_center(), true))
	assert_eq(_progress().call("equipped", "neck"), "", "the bin takes it off")


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
