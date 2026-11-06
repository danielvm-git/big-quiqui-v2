# story: e04s04
extends BathE2eTestCase
## SC-E04-P0-30..P1-34: the whole BATH journey from the Casa door and back, driven by
## touch events, plus the 4:3 containment assertions that make the hull contract
## visible on the device we target.


func test_full_journey_at_16_9() -> void:
	await _assert_full_journey(GeometryOracle.DESKTOP_16_9)


func test_full_journey_at_4_3() -> void:
	await _assert_full_journey(GeometryOracle.IPAD_4_3)


func test_full_journey_at_the_real_4_3_canvas() -> void:
	await _assert_full_journey(GeometryOracle.CANVAS_4_3)


func _assert_full_journey(size: Vector2i) -> void:
	_advance_loop_to_bath()
	await _open_casa(size)

	var door: TapButton = (stage as CasaScene).door(CareSteps.BATH)
	_deliver(door, TouchSim.tap_events(door, true))
	assert_eq(door.taps, 1, "%s: one tap on the bath door" % size)
	assert_eq(requested, [BANHEIRO_PATH], "%s: the door asks for the bathroom" % size)

	for step: int in range(SCENE_STEPS):
		sm.advance(SCENE_STEP_SEC)
	await _settle()
	assert_true(stage is BathScene, "%s: the bathroom is on stage" % size)
	_assert_oracle_clean(size)
	_assert_patches_on_the_body(size)

	# SOAP: one drag per patch, all delivered as touch.
	_soak_every_patch()
	assert_eq(_bath().soaked, 8, "%s: eight patches soaked by touch" % size)
	_bath().advance(GAP_SEC)
	assert_eq(_bath().fsm.state, BathScene.STATE_RINSE, "%s: the shower opens" % size)

	# RINSE: the showerhead swept over her body.
	_sweep(_bath().shower, BODY_SWEEP_STEPS)
	_bath().advance(GAP_SEC)
	assert_eq(_bath().fsm.state, BathScene.STATE_DRY, "%s: the towel opens" % size)

	# DRY: the towel, then BATH is credited once.
	_sweep(_bath().towel, BODY_SWEEP_STEPS)
	assert_eq(_bath().fsm.state, BathScene.STATE_FINISHED, "%s: the bath is finished" % size)
	assert_eq(_bath().rig.expression_id, "brilhando", "%s: she comes out shiny" % size)
	assert_true(_bath().credited, "%s: the step is credited" % size)
	assert_eq(str(clm.call("state_id")), CareSteps.DRESS, "%s: DRESS is next" % size)
	assert_eq(clm.call("completed_steps"), 2, "%s: two dots filled" % size)

	assert_eq(requested, [BANHEIRO_PATH, CASA_PATH], "%s: the Casa is requested exactly once" % size)
	assert_eq(refused_requests, [], "%s: nothing asked twice" % size)

	for step: int in range(SCENE_STEPS):
		sm.advance(SCENE_STEP_SEC)
	await _settle()
	assert_true(stage is CasaScene, "%s: back at the Casa" % size)
	_assert_probes_clean()


# ── containment is the point: 4:3 must not put foam on the wallpaper ────────


func test_every_patch_is_inside_the_hull_before_and_after_a_resize() -> void:
	_advance_loop_to_bath()
	await _open_casa(GeometryOracle.CANVAS_4_3)
	await _enter_bath()
	_assert_patches_on_the_body(GeometryOracle.CANVAS_4_3)

	viewport.size = GeometryOracle.IPAD_4_3
	await wait_process_frames(3)
	_bath().project_blobs()
	await wait_process_frames(2)

	_assert_patches_on_the_body(GeometryOracle.IPAD_4_3)
	assert_eq(_bath().soaked, 0, "a resize does not soak anything on its own")


## A patch that has already been soaked stays soaked through a resize: re-projecting
## geometry must not resurrect foam the child has cleaned.
func test_a_resize_does_not_resurrect_soaked_patches() -> void:
	_advance_loop_to_bath()
	await _open_casa(GeometryOracle.DESKTOP_16_9)
	await _enter_bath()
	_scrub_patch(0)
	_scrub_patch(1)
	assert_eq(_bath().soaked, 2)

	viewport.size = GeometryOracle.CANVAS_4_3
	await wait_process_frames(3)
	_bath().project_blobs()

	assert_eq(_bath().soaked, 2, "still two soaked")
	assert_false(_bath().blob(0).visible, "and the cleaned patches stay clean")
	assert_true(_bath().blob(2).visible, "while the dirty ones are still on her")


# ── leaving is not earning ──────────────────────────────────────────────────


func test_leaving_mid_journey_abandons_and_never_credits() -> void:
	_advance_loop_to_bath()
	await _open_casa(GeometryOracle.DESKTOP_16_9)
	await _enter_bath()
	_scrub_patch(0)
	_scrub_patch(1)

	var home: TapButton = _bath().get_node("HomeButton") as TapButton
	_deliver(home, TouchSim.tap_events(home, true))

	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the step is abandoned")
	assert_false(_bath().credited, "and nothing is credited")
	assert_eq(requested, [BANHEIRO_PATH, CASA_PATH], "the Casa is asked for once")
	assert_eq(_bath().sponge.state_id(), "REST", "the device let go of the finger")
