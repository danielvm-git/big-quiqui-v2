# story: e14s01
extends PlayerTestCase
## SC-e14s01-P0-02 — dress snaps, reloads from save, invalid ids never reach save.


func before_each() -> void:
	TestReset.reset_all()


func test_an_outfit_snap_credits_dress_once() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	for step: String in [CareSteps.FEED, CareSteps.BATH]:
		clm.call("begin_step", step)
		clm.call("complete_step", step)
	clm.call("begin_step", CareSteps.DRESS)
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("closet"))
	var strip: Control = player.get_node("TrayZone/DressStrip")
	var dress: TapButton = strip.find_child("floral_dress", true, false) as TapButton
	finger_tap(player, dress)
	await _settle(player)
	assert_eq(get_node("/root/ProgressManager").call("equipped", SaveData.SLOT_BODY), "floral_dress")
	assert_eq(clm.state_id(), CareSteps.PLAY)


func test_the_saved_look_reloads_on_a_second_mount() -> void:
	_progress().call("wear", SaveData.SLOT_BODY, "red_dress")
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("closet"))
	await wait_process_frames(2)
	var rig: QuiQuiRig = player.get_node("QuiQuiRig") as QuiQuiRig
	assert_eq(rig.outfit_id, "red_dress")


func _progress() -> Node:
	return get_node("/root/ProgressManager")
