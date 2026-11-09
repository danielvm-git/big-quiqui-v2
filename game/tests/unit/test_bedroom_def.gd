# story: e14s01
extends PlayerTestCase
## SC-e14s01-P0-04 — lamp and plush in either order credit SLEEP once; tint stays off the rig.


func before_each() -> void:
	TestReset.reset_all()


func _to_sleep() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	for step: String in [CareSteps.FEED, CareSteps.BATH, CareSteps.DRESS, CareSteps.PLAY]:
		clm.call("begin_step", step)
		clm.call("complete_step", step)


func _tap_both(player: ScenePlayer, first: int, second: int) -> void:
	var buttons: Array[TapButton] = tray_taps(player)
	finger_tap(player, buttons[first])
	finger_tap(player, buttons[second])


func test_lamp_then_plush_credits_sleep_once() -> void:
	_to_sleep()
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("begin_step", CareSteps.SLEEP)
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("bedroom"))
	_tap_both(player, 0, 1)
	await _settle(player)
	assert_eq(clm.state_id(), CareSteps.CELEBRATE)
	var rig: QuiQuiRig = player.get_node("QuiQuiRig") as QuiQuiRig
	assert_eq(rig.modulate, Color.WHITE)


func test_plush_then_lamp_credits_sleep_once() -> void:
	_to_sleep()
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("begin_step", CareSteps.SLEEP)
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("bedroom"))
	_tap_both(player, 1, 0)
	await _settle(player)
	assert_eq(clm.state_id(), CareSteps.CELEBRATE)
