# story: e03s03
extends GutTest
## SC-E03-P0-14..P1-21: the kitchen slice. Three foods from the tray, chewing and
## pleasure per bite, the FEED step credited once, free play after it, one way home.
## Every gesture is the TouchSim sequence with its mouse echo, fed to `_gui_input`.

const SCENE_PATH: String = "res://scenes/cozinha.tscn"
const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/cozinha.ogg"
const FIXED_SEED: int = 20261105
## Longer than either reaction, so one `advance` always ends the current one.
const STEP_SEC: float = 1.0
const AWAY_FROM_MOUTH: Vector2 = Vector2(150.0, 300.0)
const FOOD_COUNT: int = 3
const MIN_FOOD_GAP: float = 24.0
const MIN_MOUTH_DISTANCE: float = 220.0
const TRAY_CENTRE_ABOVE_BOTTOM: float = 156.0

var scene: KitchenScene = null
var requested: Array[String] = []
var loop_state_at_request: Array[String] = []
## SceneManager also refuses a repeat: only this list proves the scene never asked twice.
var refused_requests: Array[String] = []
var clm: Node = null
var sm: Node = null
var am: Node = null


func before_all() -> void:
	clm = get_node("/root/CareLoopManager")
	sm = get_node("/root/SceneManager")
	am = get_node("/root/AudioManager")
	# Connect once: the autoload outlives the test.
	sm.scene_requested.connect(_on_scene_requested)
	sm.transition_rejected.connect(func(path: String, _reason: String) -> void: refused_requests.append(path))


func before_each() -> void:
	TestReset.reset_all()
	requested = []
	loop_state_at_request = []
	refused_requests = []


func after_each() -> void:
	sm.manual_step = false
	am.reset()
	scene = null


func _on_scene_requested(path: String, _queued: bool) -> void:
	requested.append(path)
	loop_state_at_request.append(clm.state_id())


func _mount(size: Vector2i, seed_value: int = FIXED_SEED) -> KitchenScene:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "cozinha.tscn must load")
	var instance: KitchenScene = packed.instantiate() as KitchenScene
	instance.manual_step = true
	instance.seed_value = seed_value
	viewport.add_child(instance)
	return instance


## Mounts, lets the layout settle and takes over every timeline in the scene.
func _enter(size: Vector2i = GeometryOracle.DESKTOP_16_9) -> KitchenScene:
	scene = _mount(size)
	await wait_frames(3)
	scene.rig.manual_step = true
	for index: int in range(FOOD_COUNT):
		scene.food(index).manual_step = true
	return scene


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _touch(point: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	return event


func _drag(point: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.position = point
	return event


func _press(index: int) -> void:
	var food: TouchDraggable = scene.food(index)
	food._gui_input(TouchSim.gui_event(food, _touch(food.get_global_rect().get_center(), true)))


func _move(index: int, point: Vector2) -> void:
	var food: TouchDraggable = scene.food(index)
	food._gui_input(TouchSim.gui_event(food, _drag(point)))


func _release(index: int, point: Vector2) -> void:
	var food: TouchDraggable = scene.food(index)
	food._gui_input(TouchSim.gui_event(food, _touch(point, false)))


func _feed(index: int) -> void:
	var food: TouchDraggable = scene.food(index)
	_deliver(food, TouchSim.drag_events(food, scene.rig.mouth_global_center()))


func _finish_reactions() -> void:
	scene.advance(STEP_SEC)
	scene.advance(STEP_SEC)


func _feed_all() -> void:
	for index: int in range(FOOD_COUNT):
		_feed(index)
		_finish_reactions()


func _tap_home() -> void:
	var home: TapButton = scene.get_node("HomeButton") as TapButton
	for event: InputEvent in TouchSim.tap_events(home, true):
		home._gui_input(event)


func _ids(items: Array[ItemData]) -> Array[String]:
	var ids: Array[String] = []
	for item: ItemData in items:
		ids.append(item.id)
	return ids


# ── SC-E03-P0-14 three bites complete FEED ───────────────────────────────────


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


# ── T-E03-02 exactly once ────────────────────────────────────────────────────


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


# ── SC-E03-P0-15 re-entry ────────────────────────────────────────────────────


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


# ── SC-E03-P0-16 both aspects ────────────────────────────────────────────────


func test_both_aspects_pass_the_oracle_and_the_tray_rules() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		await _enter(size)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(scene, size, GeometryOracle.CARE_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		_assert_food_layout(size)
		_assert_tray_layout(size)
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
	assert_eq(scene.rig.get_global_rect().size.x, 640.0)


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


# ── SC-E03-P0-17 reactions and particles ─────────────────────────────────────


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
	assert_eq(scene.rig.expression_id, "mastigando")
	assert_true(crumbs.emitting)
	assert_true(crumbs.one_shot)
	assert_true(crumbs.global_position.is_equal_approx(scene.rig.mouth_global_center()))
	assert_eq(am.sfx_cursor(), sfx_before + 1, "nhami plays")
	assert_false(scene.food(0).visible, "the eaten food is gone")
	assert_false(hearts.emitting)
	assert_false(scene.food(1).enabled, "other foods wait while she chews")

	scene.advance(STEP_SEC)

	assert_eq(scene.fsm.state, "PLEASURE")
	assert_eq(scene.rig.expression_id, "prazer")
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


# ── SC-E03-P1-18 anticipation ────────────────────────────────────────────────


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


# ── SC-E03-P1-19 way out ─────────────────────────────────────────────────────


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


func test_home_during_the_last_bite_requests_once_and_credits_nothing() -> void:
	await _enter()
	_feed(0)
	_finish_reactions()
	_feed(1)
	_finish_reactions()
	_feed(2)

	_tap_home()
	_finish_reactions()

	assert_eq(scene.fsm.state, "FINISHED")
	assert_eq(clm.state_id(), "IDLE", "home won: the step was abandoned")
	assert_eq(requested, [CASA_PATH])
	assert_eq(refused_requests, [], "FINISHED and Home share one request")


# ── audio ────────────────────────────────────────────────────────────────────


func test_entry_plays_the_kitchen_theme_and_the_voice_prompt() -> void:
	await _enter()

	assert_true(am.is_music_playing(load(MUSIC_PATH) as AudioStream))
	assert_true(am.is_ducked, "the voice prompt ducks the music")


func test_a_missing_stream_degrades() -> void:
	await _enter()

	assert_false(scene._play_stream("play_voice", "res://assets/audio/voice/nao_existe.ogg"))
	_feed(0)
	assert_eq(scene.bites, 1, "the scene stays playable")


# ── SC-E03-P1-21 idle wish ───────────────────────────────────────────────────


func test_eight_seconds_of_quiet_show_the_wish_and_any_drag_clears_it() -> void:
	await _enter()

	scene.advance(7.5)
	assert_false(scene.bubble.is_showing())

	scene.advance(0.6)
	assert_true(scene.bubble.is_showing())
	assert_eq(scene.bubble.wish_id(), "cenoura")
	assert_eq(scene.rig.expression_id, "carente")
	scene.bubble.manual_step = true
	scene.bubble.advance(0.5)
	assert_ne(scene.bubble.pulse_scale(), 1.0, "the bubble pulses")

	_press(0)

	assert_false(scene.bubble.is_showing())
	assert_eq(scene.rig.expression_id, "base")


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
