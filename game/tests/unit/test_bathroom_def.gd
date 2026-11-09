# story: e14s01
extends PlayerTestCase
## SC-e14s01-P0-01 — BATH is credited once from the shipped bathroom def.


func before_each() -> void:
	TestReset.reset_all()


func test_bath_credits_once_after_the_chain() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	clm.call("begin_step", CareSteps.BATH)
	var def: SceneDef = SceneDefLoader.load_by_id("bathroom")
	var player: ScenePlayer = await mount(def)
	var probe: FsmProbe = FsmProbe.new().attach(clm.fsm)
	var hull: PackedVector2Array = (player.get_node("QuiQuiRig") as QuiQuiRig).scrub_hull_global()
	for index: int in range(3):
		assert_eq(player.runner.step_index, index)
		rub_hull(rub_tool(player), hull)
		for _tick: int in range(6):
			player.advance(0.2)
		await wait_process_frames(1)
	assert_eq(clm.state_id(), CareSteps.DRESS)
	assert_true(probe.is_clean(), probe.summary())
	probe.detach()
