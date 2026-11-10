# story: e14s01
extends PlayerTestCase
## SC-e14s01-P0-03 — three distinct toys credit PLAY once.


func before_each() -> void:
	TestReset.reset_all()


func _to_play() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	for step: String in [CareSteps.FEED, CareSteps.BATH, CareSteps.DRESS]:
		clm.call("begin_step", step)
		clm.call("complete_step", step)


func test_three_distinct_toys_credit_play_once() -> void:
	_to_play()
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("begin_step", CareSteps.PLAY)
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("playroom"))
	var buttons: Array[TapButton] = tray_taps(player)
	assert_eq(buttons.size(), 3)
	finger_tap(player, buttons[0])
	finger_tap(player, buttons[1])
	finger_tap(player, buttons[2])
	await _settle(player)
	assert_eq(clm.state_id(), CareSteps.SLEEP)
	var again: ScenePlayer = await mount(SceneDefLoader.load_by_id("playroom"))
	var replay: Array[TapButton] = tray_taps(again)
	finger_tap(again, replay[0])
	await _settle(again)
	assert_eq(clm.state_id(), CareSteps.SLEEP)
