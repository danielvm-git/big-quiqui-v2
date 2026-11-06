# story: e03s03
extends CozinhaTestCase
## SC-E03-P1-18..P1-21: kitchen anticipation, Home button, watchdog, audio, and idle wish.


func test_each_food_targets_the_mouth_with_the_forgiving_margin() -> void:
	await _enter()
	for index: int in range(FOOD_COUNT):
		assert_eq(scene.food(index).drop_target, scene.rig.mouth_zone)
		assert_eq(scene.food(index).drop_margin, 120.0)


func test_dragging_near_the_mouth_opens_it_and_a_miss_restores_her_face() -> void:
	await _enter()
	var mouth: Vector2 = scene.rig.mouth_global_center()
	_press(0)
	assert_eq(scene.rig.expression_id, "base", "on the tray she does not anticipate")
	_move(0, mouth + Vector2(200.0, 0.0))
	assert_eq(scene.rig.expression_id, "boca_aberta")
	_move(0, AWAY_FROM_MOUTH)
	assert_eq(scene.rig.expression_id, "base", "moving away closes it")
	_move(0, mouth + Vector2(200.0, 0.0))
	assert_eq(scene.rig.expression_id, "boca_aberta")
	_release(0, mouth + Vector2(215.0, 0.0))
	assert_eq(scene.rig.expression_id, "base", "a release off target closes it")
	assert_eq(scene.food(0).state_id(), "RETURNING")
	assert_eq(scene.bites, 0)


func test_a_consumed_food_leaves_her_chewing_and_the_next_food_still_opens_her_mouth() -> void:
	await _enter()
	var mouth: Vector2 = scene.rig.mouth_global_center()
	var faces: Array[String] = []
	scene.rig.expression_changed.connect(func(id: String) -> void: faces.append(id))
	_feed(0)
	assert_eq(scene.rig.expression_id, "mastigando", "chewing, not the base face")
	assert_eq(faces.back(), "mastigando")
	assert_false(faces.has("base"), "the base face never flashes between the open mouth and chewing")
	_finish_reactions()
	_press(1)
	_move(1, mouth + Vector2(100.0, 0.0))
	assert_eq(scene.rig.expression_id, "boca_aberta", "no stale anticipation face")


func test_a_missed_food_flies_back_and_can_be_used_again() -> void:
	await _enter()
	var food: TouchDraggable = scene.food(0)
	var rest_position: Vector2 = food.position
	_deliver(food, TouchSim.drag_events(food, AWAY_FROM_MOUTH))
	food.advance(TouchDraggable.RETURN_SEC)
	assert_eq(food.state_id(), "REST")
	assert_true(food.position.is_equal_approx(rest_position))
	_feed(0)
	assert_eq(scene.bites, 1)


func test_home_abandons_the_step_and_requests_the_casa_once() -> void:
	await _enter()
	var probe: FsmProbe = FsmProbe.new().attach(clm.fsm)
	_tap_home()
	_tap_home()
	assert_eq(clm.state_id(), "IDLE")
	assert_eq(requested, [CASA_PATH], "a second tap during the fade asks for nothing")
	assert_eq(refused_requests, [], "the scene itself never asked twice")
	assert_true(probe.is_clean(), probe.summary())


func test_home_is_ignored_once_finished() -> void:
	await _enter()
	_feed_all()
	_tap_home()
	assert_eq(clm.state_id(), "BATH", "the credited step is not abandoned")
	assert_eq(requested, [CASA_PATH])


func test_home_during_free_play_keeps_the_cycle_where_it_is() -> void:
	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)
	await _enter()
	_tap_home()
	assert_eq(clm.state_id(), "BATH")
	assert_eq(requested, [CASA_PATH])


func test_home_during_the_last_bite_credits_the_step_and_requests_once() -> void:
	await _enter()
	var probe: FsmProbe = FsmProbe.new().attach(clm.fsm)
	_feed(0)
	_finish_reactions()
	_feed(1)
	_finish_reactions()
	_feed(2)
	_tap_home()
	assert_eq(clm.state_id(), "BATH", "the finished step is credited at once")
	assert_eq(loop_state_at_request, ["BATH"], "credited before the scene request")
	_finish_reactions()
	assert_eq(scene.fsm.state, "FINISHED")
	assert_eq(clm.completed_steps(), 1, "credited once, not again on FINISHED")
	assert_eq(requested, [CASA_PATH])
	assert_eq(refused_requests, [], "FINISHED and Home share one request")
	assert_true(probe.is_clean(), probe.summary())


func test_home_during_the_second_bite_still_abandons_the_step() -> void:
	await _enter()
	_feed(0)
	_finish_reactions()
	_feed(1)
	_tap_home()
	assert_eq(clm.state_id(), "IDLE")
	assert_eq(clm.completed_steps(), 0)
	assert_eq(requested, [CASA_PATH])


func test_home_during_the_last_bite_of_free_play_credits_nothing() -> void:
	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)
	await _enter()
	var probe: FsmProbe = FsmProbe.new().attach(clm.fsm)
	_feed(0)
	_finish_reactions()
	_feed(1)
	_finish_reactions()
	_feed(2)
	_tap_home()
	_finish_reactions()
	assert_eq(clm.state_id(), "BATH")
	assert_eq(probe.transition_count(), 0)
	assert_eq(requested, [CASA_PATH])


func test_a_long_frame_during_the_fade_home_still_reaches_the_casa() -> void:
	await _enter()
	var swapped: Array[String] = []
	sm.manual_step = true
	sm.loader = func(path: String) -> void: swapped.append(path)
	_tap_home()
	sm.advance(2.1)
	assert_eq(swapped, [CASA_PATH])
	assert_false(sm.is_busy())


func test_a_long_frame_after_the_last_bite_still_reaches_the_casa() -> void:
	await _enter()
	var swapped: Array[String] = []
	sm.manual_step = true
	sm.loader = func(path: String) -> void: swapped.append(path)
	_feed_all()
	sm.advance(2.1)
	assert_eq(swapped, [CASA_PATH])
	assert_eq(clm.state_id(), "BATH")


func test_entry_plays_the_kitchen_theme_and_the_voice_prompt() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9)
	assert_true(am.is_music_playing(load(MUSIC_PATH) as AudioStream))
	assert_true(am.is_ducked, "the voice prompt ducks the music")


func test_a_missing_stream_degrades() -> void:
	await _enter()
	assert_false(scene._play_stream("play_voice", "res://assets/audio/voice/nao_existe.ogg"))
	_feed(0)
	assert_eq(scene.bites, 1, "the scene stays playable")


func test_eight_seconds_of_quiet_show_the_wish_and_any_drag_clears_it() -> void:
	await _enter()
	scene.advance(7.5)
	assert_false(scene.bubble.is_showing())
	scene.advance(0.6)
	assert_true(scene.bubble.is_showing())
	assert_eq(scene.bubble.wish_id(), _art_name(0), "she asks for a food that is on the tray")
	assert_eq(scene.rig.expression_id, "carente")
	scene.bubble.manual_step = true
	scene.bubble.advance(0.5)
	assert_ne(scene.bubble.pulse_scale(), 1.0, "the bubble pulses")
	_press(0)
	assert_false(scene.bubble.is_showing())
	assert_eq(scene.rig.expression_id, "base")


func test_the_wish_moves_to_the_next_food_after_each_bite() -> void:
	await _enter()
	_feed(0)
	_finish_reactions()
	scene.advance(8.1)
	assert_eq(scene.bubble.wish_id(), _art_name(1))
	_feed(1)
	_finish_reactions()
	scene.advance(8.1)
	assert_eq(scene.bubble.wish_id(), _art_name(2))


func test_the_wish_can_skip_a_food_eaten_out_of_order() -> void:
	await _enter()
	_feed(1)
	_finish_reactions()
	scene.advance(8.1)
	assert_eq(scene.bubble.wish_id(), _art_name(0))


func test_a_held_food_is_a_touch_so_no_wish_appears() -> void:
	await _enter()
	_press(0)
	scene.advance(9.0)
	assert_false(scene.bubble.is_showing())


func test_a_tap_on_quiqui_clears_the_wish() -> void:
	await _enter()
	scene.advance(8.1)
	for event: InputEvent in TouchSim.tap_events(scene.rig, true):
		scene.rig._gui_input(event)
	assert_false(scene.bubble.is_showing())
	assert_eq(scene.rig.expression_id, "base")


func test_the_idle_timer_runs_only_in_ready_and_restarts_after_a_bite() -> void:
	await _enter()
	_feed(0)
	scene.advance(8.5)
	assert_eq(scene.fsm.state, "PLEASURE")
	assert_false(scene.bubble.is_showing())
	scene.advance(8.5)
	assert_eq(scene.fsm.state, "READY")
	assert_false(scene.bubble.is_showing())
	scene.advance(7.5)
	assert_false(scene.bubble.is_showing(), "a fresh 8 s after the bite")
	scene.advance(0.6)
	assert_true(scene.bubble.is_showing())


func test_a_frame_spike_during_chewing_or_pleasure_logs_dwell_timeout_and_advances() -> void:
	await _enter()
	var exceeded: Array[String] = []
	scene.fsm.dwell_timeout.connect(func(st: String) -> void: exceeded.append(st))
	_feed(0)
	scene.advance(2.1)
	assert_eq(scene.fsm.state, "PLEASURE")
	scene.advance(2.1)
	assert_eq(scene.fsm.state, "READY")
	assert_eq(exceeded, ["CHEWING", "PLEASURE"], "both 2.0 s dwell ceilings must fire")
