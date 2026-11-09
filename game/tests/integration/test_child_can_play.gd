# story: e13s09
extends PlayerTestCase
## A child can see each target, touch it through the player, finish every step, and leave through a
## shipped `next_scene_id`. Hub maps leave through Home when their template never reports progress.

const ASPECTS: Array[Vector2i] = [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]


func before_each() -> void:
	TestReset.reset_all()
	var sm: Node = (Engine.get_main_loop() as SceneTree).root.get_node("SceneManager")
	sm.set("manual_step", true)
	if sm.has_method("set_test_mode"):
		sm.call("set_test_mode", true)


func after_each() -> void:
	TestReset.reset_all()


func test_probe_ids_are_discovered_from_the_data_folder() -> void:
	var ids: Array[String] = SceneDefLoader.child_play_gate_ids()
	assert_gte(ids.size(), 9)
	for scene_id: String in ids:
		assert_not_null(SceneDefLoader.load_by_id(scene_id), scene_id)


func test_every_probe_def_finishes_and_names_a_shipped_exit_at_every_aspect() -> void:
	for aspect: Vector2i in ASPECTS:
		for scene_id: String in SceneDefLoader.child_play_gate_ids():
			if scene_id == "reward_probe":
				CareWalk.to_celebrate((Engine.get_main_loop() as SceneTree).root.get_node("CareLoopManager"))
			var def: SceneDef = SceneDefLoader.load_by_id(scene_id)
			assert_true(SceneCatalog.is_shipped(def.next_scene_id), scene_id)
			var player: ScenePlayer = await mount(def, aspect)
			await _play_def(player, scene_id)
			var finished: bool = false
			if is_instance_valid(player):
				finished = _finished(player)
				if not finished:
					await _settle(player)
					finished = _finished(player)
			else:
				finished = true
			assert_true(finished, "%s at %s" % [scene_id, aspect])
			if is_instance_valid(player):
				assert_eq(def.next_scene_id, player.loaded_def.next_scene_id)
				player.queue_free()
			await wait_process_frames(1)


func test_a_picture_above_surface_z_fails_the_seen_gate() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("title_probe"))
	var verb: Control = player.find_child("play_button", true, false) as Control
	var cover: TextureRect = TextureRect.new()
	cover.name = "cover_art"
	cover.texture = verb.find_child("Art", true, false).get("texture") as Texture2D
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.size = verb.size
	cover.global_position = verb.global_position
	cover.z_index = TemplateKit.SURFACE_Z + 1
	player.add_child(cover)
	assert_false(HitProbe.seen(player, verb))


func _finished(player: ScenePlayer) -> bool:
	var state: String = player.runner.fsm.state
	if state in [StepRunner.STATE_STEP_DONE, StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT]:
		return true
	return player.runner.template_progress() >= 1.0


func _play_def(player: ScenePlayer, scene_id: String) -> void:
	match scene_id:
		"title_probe":
			_tap_verb(player)
		"touch_each_probe":
			_play_touch_each(player)
		"rub_reveal_probe":
			_play_rub_reveal(player)
		"bathroom_probe":
			await _play_bathroom(player)
		"dress_probe":
			_play_dress(player)
		"reward_probe":
			_play_reward(player)
		"prize_probe":
			_play_prize(player)
		"penguin_probe":
			_play_penguin(player)
		"home_map":
			_play_map(player)
		_:
			assert_true(false, "no play script for %s" % scene_id)


func _tap_verb(player: ScenePlayer) -> void:
	var verb: TapButton = player.find_child("play_button", true, false) as TapButton
	finger_tap(player, verb)


func _play_touch_each(player: ScenePlayer) -> void:
	var buttons: Array[TapButton] = _tray_taps(player)
	finger_tap(player, buttons[0])
	finger_tap(player, buttons[1])


func _play_rub_reveal(player: ScenePlayer) -> void:
	var hull: PackedVector2Array = (player.get_node("QuiQuiRig") as QuiQuiRig).scrub_hull_global()
	rub_hull(rub_tool(player), hull)


func _play_bathroom(player: ScenePlayer) -> void:
	for index: int in range(3):
		assert_eq(player.runner.step_index, index, "step %d is live" % index)
		var tool: Control = rub_tool(player)
		var hull: PackedVector2Array = (player.get_node("QuiQuiRig") as QuiQuiRig).scrub_hull_global()
		rub_hull(tool, hull)
		for _tick: int in range(6):
			player.advance(0.2)
		await wait_process_frames(1)
	assert_true(player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT], "the bathroom chain ends")


func _play_dress(player: ScenePlayer) -> void:
	var strip: Control = player.get_node("TrayZone/DressStrip")
	var scarf: TapButton = strip.find_child("blue_scarf", true, false) as TapButton
	finger_tap(player, scarf)


func _play_reward(player: ScenePlayer) -> void:
	finger_tap(player, _tray_taps(player)[0])


func _play_prize(player: ScenePlayer) -> void:
	finger_tap(player, _tray_taps(player)[0])


func _play_penguin(player: ScenePlayer) -> void:
	var pad: TouchPad = player.get_node("LanePad") as TouchPad
	for _attempt: int in range(48):
		player.advance(0.61)
		var tpl: RefCounted = player.get("_template") as RefCounted
		var lane: int = int(tpl.call("first_lane"))
		if lane >= 0:
			var at: Vector2 = _lane_point(player, lane)
			send(pad, touch(at - Vector2(300.0, 0.0), true))
			send(pad, drag(at))
			send(pad, touch(at, false))
		if player.runner.template_progress() >= 1.0:
			return


func _play_map(player: ScenePlayer) -> void:
	var sm: Node = (Engine.get_main_loop() as SceneTree).root.get_node("SceneManager")
	sm.set("manual_step", true)
	var pad: TouchPad = player.get_node("MapPad") as TouchPad
	var at: Vector2 = player.get_node("MapWorld/feed_door").get_global_rect().get_center()
	send(pad, touch(at, true))
	send(pad, touch(at, false))
	var home: TapButton = player.get_node("HomeButton") as TapButton
	finger_tap(player, home)


func _tray_taps(player: ScenePlayer) -> Array[TapButton]:
	var found: Array[TapButton] = []
	_collect_taps(player.get_node("TrayZone"), found)
	return found


func _collect_taps(node: Node, into: Array[TapButton]) -> void:
	for child: Node in node.get_children():
		if child is TapButton and child.is_in_group("hit_target"):
			into.append(child as TapButton)
		_collect_taps(child, into)


func _lane_point(player: ScenePlayer, lane: int) -> Vector2:
	var field: Control = player.get_node("LaneField") as Control
	var width: float = field.size.x / 3.0
	return field.global_position + Vector2(width * (float(lane) + 0.5), 800.0)


func _settle(player: ScenePlayer) -> void:
	for _tick: int in range(12):
		player.advance(0.2)
	await wait_process_frames(2)
