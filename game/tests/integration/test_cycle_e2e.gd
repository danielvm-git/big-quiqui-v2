# story: e07s04
extends CycleE2eTestCase
## SC-E07-P0-15..P1-17: the whole care cycle — five credits, one reward, a usable hub.
##
## The fixture (`CycleE2eTestCase`) owns the loader, the probes and the per-stage layout audit;
## what is left here is the journey and its assertions.

# ── SC-E07-P0-15/16 the cycle, on both canvases ───────────────────────────


func test_the_full_cycle_at_16_9() -> void:
	await _walk_cycle(GeometryOracle.DESKTOP_16_9)

	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the cycle closed")
	assert_eq(clm.call("completed_steps"), 0, "the counter resets with the closed cycle")
	assert_eq(pm.call("get_coins"), 5, "+5 coins once")
	assert_eq(pm.call("get_tickets"), 1, "+1 ticket once")
	assert_eq(int(pm.data.completed_cycles), 1, "one cycle closed")
	assert_true(stage is CasaScene, "and we are back at the hub")
	_assert_probes_clean()


func test_the_full_cycle_on_ipad() -> void:
	await _walk_cycle(GeometryOracle.IPAD_4_3)

	assert_eq(pm.call("get_coins"), 5, "the reward does not depend on the canvas")
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE)
	_assert_probes_clean()


# ── SC-E07-P1-17 a detour out of the celebration does not brick the hub ───


func test_a_detour_out_of_the_celebration_leaves_the_hub_usable() -> void:
	await _walk_cycle(GeometryOracle.DESKTOP_16_9, false)
	assert_eq(str(clm.call("state_id")), CareSteps.CELEBRATE, "the party is on, not yet closed")
	var paid: int = int(pm.call("get_coins"))

	sm.request_scene(ALBUM_PATH)
	await _follow()

	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the detour closed the cycle")
	assert_eq(int(pm.call("get_coins")), paid, "and paid nothing extra")
	sm.loader = _swap
	await _open_casa(GeometryOracle.DESKTOP_16_9)
	assert_eq((stage as CasaScene).door(CareSteps.FEED).modulate.a, 1.0, "the first door is live")
	_assert_probes_clean()
