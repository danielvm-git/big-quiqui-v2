# story: e03s03
extends CozinhaTestCase
## SC-E03-P0-14..P0-17: the kitchen slice — three bites complete FEED, re-entry is
## free play, both aspects pass the geometry oracle, and each bite chews then enjoys.


func test_three_bites_complete_feed_and_request_the_casa_once() -> void:
	await _enter()
	var loop_probe: FsmProbe = FsmProbe.new().attach(clm.fsm)
	var kitchen_probe: FsmProbe = FsmProbe.new().attach(scene.fsm)
	assert_eq(clm.state_id(), "FEED", "entering from IDLE begins the step")

	_feed_all()

	assert_eq(scene.bites, 3)
	assert_eq(scene.fsm.state, "FINISHED")
	assert_eq(clm.state_id(), "BATH", "BATH is next")
	assert_eq(clm.completed_steps(), 1, "the first dot fills")
	assert_eq(requested, [CASA_PATH], "one request for the Casa")
	assert_eq(loop_state_at_request, ["BATH"], "the step is credited before the scene request")
	assert_true(loop_probe.is_clean(), loop_probe.summary())
	assert_true(kitchen_probe.is_clean(), kitchen_probe.summary())


func test_two_bites_do_not_finish() -> void:
	await _enter()
	_feed(0)
	_finish_reactions()
	_feed(1)
	_finish_reactions()

	assert_eq(scene.fsm.state, "READY")
	assert_eq(clm.state_id(), "FEED")
	assert_true(requested.is_empty())


func test_the_trip_home_never_swaps_the_real_scene_under_test() -> void:
	await _enter()
	sm.manual_step = true
	_feed_all()
	for step: int in range(30):
		sm.advance(0.1)

	assert_false(sm.is_busy())
	assert_eq(sm.current_scene, CASA_PATH)
	assert_eq(sm.production_swap_path, "", "T-E03-04")


func test_replaying_a_gesture_on_a_consumed_food_is_not_a_second_bite() -> void:
	await _enter()
	var probe: FsmProbe = FsmProbe.new().attach(scene.fsm)
	_feed(0)
	_finish_reactions()
	_feed(0)

	assert_eq(scene.bites, 1)
	assert_eq(scene.fsm.state, "READY")
	assert_true(probe.is_clean(), probe.summary())


func test_a_consume_outside_ready_counts_nothing_and_keeps_the_food() -> void:
	await _enter()
	_feed(0)
	scene.food(1).consumed.emit()

	assert_eq(scene.bites, 1, "transition_from guards the count")
	assert_true(scene.food(1).visible)


func test_entering_after_feed_is_clean_free_play() -> void:
	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)
	var loop_probe: FsmProbe = FsmProbe.new().attach(clm.fsm)
	await _enter()
	_feed_all()

	assert_eq(scene.bites, 3, "she still eats")
	assert_eq(clm.state_id(), "BATH", "no step is credited")
	assert_eq(loop_probe.transition_count(), 0)
	assert_true(loop_probe.is_clean(), "no illegal transition: %s" % loop_probe.summary())
	assert_eq(requested, [CASA_PATH])


func test_both_aspects_pass_the_oracle_and_the_tray_rules() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		await _enter(size)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(scene, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		_assert_food_layout(size)
		_assert_tray_layout(size)
		scene.get_parent().queue_free()


func test_the_bubble_never_covers_the_character_on_any_aspect() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		await _enter(size)
		scene.advance(8.1)
		await wait_process_frames(2)

		var head: float = scene.rig.get_visual_global_rect().position.y
		var bubble_bottom: float = scene.bubble.get_global_rect().end.y
		assert_true(
			bubble_bottom <= head + 1.0,
			"%dx%d: the bubble ends at %.1f but her head starts at %.1f" % [size.x, size.y, bubble_bottom, head],
		)
		scene.get_parent().queue_free()


func _assert_food_layout(size: Vector2i) -> void:
	var canvas: Rect2 = Rect2(Vector2.ZERO, Vector2(size))
	var mouth: Vector2 = scene.rig.mouth_global_center()
	for index: int in range(FOOD_COUNT):
		var rect: Rect2 = scene.food(index).get_global_rect()
		assert_eq(rect.size, Vector2(148.0, 148.0))
		assert_true(canvas.encloses(rect), "%s: food %d is inside the canvas" % [size, index])
		assert_true(scene.food(index).is_in_group(GeometryOracle.HIT_GROUP))
		var nearest: Vector2 = mouth.clamp(rect.position, rect.end)
		assert_gte(nearest.distance_to(mouth), MIN_MOUTH_DISTANCE, "%s: food %d at rest" % [size, index])
		if index > 0:
			var gap: float = rect.position.x - scene.food(index - 1).get_global_rect().end.x
			assert_gte(gap, MIN_FOOD_GAP, "%s: gap before food %d" % [size, index])


func _assert_tray_layout(size: Vector2i) -> void:
	var tray: TextureRect = scene.get_node("Tray") as TextureRect
	assert_eq(tray.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "the art keeps its proportions")
	assert_eq(tray.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_almost_eq(float(size.y) - tray.get_global_rect().get_center().y, TRAY_CENTRE_ABOVE_BOTTOM, 1.0)
	var painted: Rect2 = scene.rig.get_visual_global_rect()
	assert_almost_eq(scene.rig.size.x, painted.size.x, painted.size.x * 0.03, "box width fits the painted character")
	assert_between(painted.size.y / float(size.y), 0.55, 0.65, "painted character keeps DESIGN §3 height")


func test_the_home_button_is_a_safe_top_left_hit_target() -> void:
	await _enter()
	var home: TapButton = scene.get_node("HomeButton") as TapButton
	assert_true(home.is_in_group(GeometryOracle.HIT_GROUP))
	assert_gte(home.get_global_rect().position.x, 36.0)
	assert_gte(home.get_global_rect().position.y, 36.0)
	assert_lt(home.get_global_rect().end.x, 300.0)
	assert_lt(home.get_global_rect().end.y, 300.0)


func test_the_scene_has_no_text() -> void:
	await _enter()
	assert_eq(scene.find_children("*", "Label", true, false).size(), 0)
	assert_eq(scene.find_children("*", "RichTextLabel", true, false).size(), 0)


func test_a_fixed_seed_serves_three_distinct_foods_from_the_catalog() -> void:
	await _enter()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = FIXED_SEED
	var expected: Array[String] = _ids(FoodCatalog.pick_tray(rng, FOOD_COUNT))
	assert_eq(_ids(scene.tray), expected)
	for index: int in range(FOOD_COUNT):
		var art: TextureRect = scene.food(index).get_node("Art") as TextureRect
		assert_eq(art.texture, scene.tray[index].texture())
		assert_eq(art.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_the_default_seed_varies_the_tray_between_visits() -> void:
	var seen: Dictionary = {}
	for visit: int in range(8):
		var visit_scene: KitchenScene = _mount(GeometryOracle.DESKTOP_16_9, 0)
		seen[",".join(_ids(visit_scene.tray))] = true
		visit_scene.get_parent().queue_free()
	assert_gt(seen.size(), 1, "seed_value 0 randomizes on entry")


func test_each_bite_chews_then_enjoys_then_waits_for_the_next() -> void:
	await _enter()
	var crumbs: CPUParticles2D = scene.get_node("Crumbs") as CPUParticles2D
	var hearts: CPUParticles2D = scene.get_node("Hearts") as CPUParticles2D
	var sfx_before: int = am.sfx_cursor()
	assert_false(crumbs.emitting, "no burst before a bite")
	assert_false(hearts.emitting)
	_feed(0)
	assert_eq(scene.fsm.state, "CHEWING")
	assert_eq(scene.bites, 1)
	assert_eq(scene.rig.expression_id, "chewing")
	assert_true(crumbs.emitting)
	assert_true(crumbs.one_shot)
	assert_true(crumbs.global_position.is_equal_approx(scene.rig.mouth_global_center()))
	assert_eq(am.sfx_cursor(), sfx_before + 1, "nhami plays")
	assert_false(scene.food(0).visible, "the eaten food is gone")
	assert_false(hearts.emitting)
	assert_false(scene.food(1).enabled, "other foods wait while she chews")
	scene.advance(STEP_SEC)
	assert_eq(scene.fsm.state, "PLEASURE")
	assert_eq(scene.rig.expression_id, "pleased")
	assert_true(hearts.emitting)
	assert_true(hearts.one_shot)
	assert_false(scene.food(1).enabled, "and while she enjoys it")
	scene.advance(STEP_SEC)
	assert_eq(scene.fsm.state, "READY")
	assert_eq(scene.rig.expression_id, "base")
	assert_true(scene.food(1).enabled)
	assert_true(scene.food(2).enabled)


func test_a_disabled_food_cannot_be_picked_up_during_the_reaction() -> void:
	await _enter()
	_feed(0)
	_press(1)
	assert_eq(scene.food(1).state_id(), "REST")


func test_foods_dim_during_the_reaction_and_come_back_on_ready() -> void:
	await _enter()
	assert_eq(scene.food(1).modulate.a, 1.0, "bright while she waits for food")
	_feed(0)
	assert_lt(scene.food(1).modulate.a, 1.0, "dim while she chews")
	assert_eq(scene.food(1).modulate.a, KitchenScene.DISABLED_FOOD_ALPHA)
	assert_eq(scene.food(2).modulate.a, KitchenScene.DISABLED_FOOD_ALPHA)
	scene.advance(STEP_SEC)
	assert_eq(scene.food(1).modulate.a, KitchenScene.DISABLED_FOOD_ALPHA, "and while she enjoys it")
	scene.advance(STEP_SEC)
	assert_eq(scene.fsm.state, "READY")
	assert_eq(scene.food(1).modulate.a, 1.0)
	assert_eq(scene.food(2).modulate.a, 1.0)


func test_a_short_step_does_not_end_the_chewing_early() -> void:
	await _enter()
	_feed(0)
	scene.advance(0.1)
	assert_eq(scene.fsm.state, "CHEWING")


func test_the_kitchen_machine_declares_its_dwell_deadlines() -> void:
	await _enter()
	assert_eq(scene.fsm.max_dwell_sec, {"CHEWING": 2.0, "PLEASURE": 2.0})
	assert_eq(scene.fsm.legal_edges["FINISHED"], [])


func test_foods_and_particles_draw_above_quiqui() -> void:
	await _enter()
	var top_layer: int = scene.rig.glasses.z_index
	for index: int in range(FOOD_COUNT):
		assert_gt(scene.food(index).z_index, top_layer, "a held food must not hide behind her")
	assert_gt((scene.get_node("Crumbs") as CanvasItem).z_index, top_layer)
	assert_gt((scene.get_node("Hearts") as CanvasItem).z_index, top_layer)
