# story: e13s09
extends PlayerTestCase
## Review round 3 (A12). A finger anywhere in the room tells the player the child is playing, so the
## hint stays quiet: a tap in the tray, a press on a pad, a drag. The mouse echo does not count.


func before_each() -> void:
	TestReset.reset_all()


func test_a_finger_down_anywhere_counts_as_input() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("touch_each_probe"))
	var hint: HintLayer = player.get("_hint") as HintLayer
	assert_false(hint.input_seen, "nothing touched yet")
	player._input(touch(Vector2(300.0, 300.0), true))
	assert_true(hint.input_seen, "A12 a touch in the room is input")


func test_a_drag_and_a_real_click_count_and_a_lift_and_an_echo_do_not() -> void:
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("touch_each_probe"))
	var hint: HintLayer = player.get("_hint") as HintLayer
	player._input(touch(Vector2(300.0, 300.0), false))
	assert_false(hint.input_seen, "a lift alone is not input")
	player._input(touch(Vector2(300.0, 300.0), true, 0, -1))
	assert_false(hint.input_seen, "A12 the mouse echo of a touch is not a second finger")
	player._input(drag(Vector2(320.0, 300.0)))
	assert_true(hint.input_seen, "a drag is input")
	hint.begin_step(player.loaded_def.steps[0] as StepDef)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	player._input(click)
	assert_true(hint.input_seen, "a real click is input")
