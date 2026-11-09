# story: e13s09
extends PlayerTestCase
## Review round 3 (A1, A2, A3). Every tray target answers a finger through the real player tree,
## at the three canvases we ship. The finger goes through `HitProbe`, so a control above the target
## (QuiQui's STOP rect was the one) takes the touch and the test fails.

const ROW_FOODS: Array[String] = [
	"apple", "banana", "grape", "carrot", "cupcake", "strawberry", "watermelon", "carrot_pasta"
]


func before_each() -> void:
	TestReset.reset_all()


func test_each_touch_each_object_answers_a_finger_at_every_canvas() -> void:
	for aspect: Vector2i in GeometryOracle.ASPECTS:
		var player: ScenePlayer = await mount(_t21_def(ROW_FOODS), aspect)
		for target: TapButton in _taps(player):
			assert_eq(finger_tap(player, target), target, "A1 %s at %s is the one touched" % [target.name, aspect])
			assert_eq(target.taps, 1, "A1 %s at %s heard its tap" % [target.name, aspect])
		player.queue_free()
		await wait_process_frames(1)


func test_the_second_prize_can_be_picked_by_a_finger() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("prize_probe"))
	var buttons: Array[TapButton] = _taps(player)
	assert_eq(finger_tap(player, buttons[1]), buttons[1], "A1 the second prize is under no other control")
	assert_eq(_progress().call("picked_prize"), "pinwheel", "A1 the second prize is the one picked")


func test_the_dress_strip_and_bin_answer_a_finger_at_every_canvas() -> void:
	for aspect: Vector2i in GeometryOracle.ASPECTS:
		TestReset.reset_all()
		var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("dress_probe"), aspect)
		var scarf: TapButton = player.find_child("blue_scarf", true, false) as TapButton
		assert_eq(scarf.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the strip pad answers for the scarf")
		assert_true(finger_tap(player, scarf) is TouchPad, "A2 the strip pad is what a finger lands on at %s" % aspect)
		assert_eq(_progress().call("equipped", "neck"), "blue_scarf", "A2 a finger dresses QuiQui at %s" % aspect)
		var bin: TapButton = player.get_node("TrayZone/trash_bag") as TapButton
		assert_eq(finger_tap(player, bin), bin, "A2 the bin answers at %s" % aspect)
		assert_eq(_progress().call("equipped", "neck"), "", "A2 the bin takes it off at %s" % aspect)
		player.queue_free()
		await wait_process_frames(1)


func test_a_finger_in_the_middle_of_the_stage_lands_on_the_pad() -> void:
	for aspect: Vector2i in GeometryOracle.ASPECTS:
		for def_id: String in ["home_map", "penguin_probe"]:
			var player: ScenePlayer = await mount(SceneDefLoader.load_by_id(def_id), aspect)
			var centre: Vector2 = Vector2(aspect) * 0.5
			assert_true(
				HitProbe.top_at(player, centre) is TouchPad, "A3 %s at %s: the pad has a size" % [def_id, aspect]
			)
			player.queue_free()
			await wait_process_frames(1)


func test_the_rig_takes_touches_again_when_the_tray_step_ends() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("touch_each_probe"))
	var rig: QuiQuiRig = player.get_node("QuiQuiRig") as QuiQuiRig
	assert_eq(rig.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the row is not under QuiQui while it is mounted")
	(player.get("_template") as RefCounted).call("teardown")
	assert_eq(rig.mouse_filter, Control.MOUSE_FILTER_STOP, "A1 QuiQui answers touches again when the step ends")


func test_a_stop_sibling_above_a_target_fails_the_check() -> void:
	var host: Control = Control.new()
	host.size = Vector2(400.0, 400.0)
	add_child_autofree(host)
	var target: Control = Control.new()
	target.size = Vector2(120.0, 120.0)
	host.add_child(target)
	assert_true(HitProbe.answers(host, target), "a free target answers")
	var cover: Control = Control.new()
	cover.size = Vector2(300.0, 300.0)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(cover)
	assert_false(HitProbe.answers(host, target), "a STOP sibling above takes the touch")
	assert_eq(HitProbe.coverer(host, target), str(cover.get_path()))
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	assert_true(HitProbe.answers(host, target), "an IGNORE sibling lets it through")
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.visible = true
	host.move_child(cover, 0)
	assert_true(HitProbe.answers(host, target), "an earlier STOP sibling is under it")
	cover.z_index = 5
	assert_false(HitProbe.answers(host, target), "B4 an earlier sibling with a higher z is caught by the z order")
	assert_eq(HitProbe.top_at(host, Vector2(10.0, 10.0)), target, "the tree order alone would miss it")
	cover.z_index = 0
	cover.visible = false
	assert_true(HitProbe.answers(host, target), "a hidden sibling lets it through")


func _t21_def(items: Array[String]) -> SceneDef:
	var def: SceneDef = SceneDefFactory.valid()
	var step: StepDef = StepDef.new()
	step.template_id = "t21_touch_each"
	step.mode = "any"
	step.item_ids = PackedStringArray(items)
	var steps: Array[Resource] = []
	steps.append(step)
	def.steps = steps
	return def


func _taps(player: ScenePlayer) -> Array[TapButton]:
	var found: Array[TapButton] = []
	for child: Node in player.get_node("TrayZone").get_children():
		if child is TapButton and child.is_in_group("hit_target") and not child.is_queued_for_deletion():
			found.append(child as TapButton)
	return found


func _progress() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("ProgressManager")
