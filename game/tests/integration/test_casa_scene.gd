# story: e02s03
extends GutTest
## SC-E02-P1-14..20 — the hub slice: `casa.tscn` boots on bg_sala with a
## reactive QuiQui, six doors, dots, HUD and wish bubble; the layout holds on
## 16:9 and 4:3; doors fire once under mouse echo; an absent target scene is
## never navigated to; 8 s of idle show QuiQui's wish; the dots and the door
## highlight track the CareLoopManager.

const SCENE_PATH: String = "res://scenes/casa.tscn"

var scene: CasaScene = null
var requested_scenes: Array[String] = []


func before_all() -> void:
	# Connect once: the autoload outlives the test, so per-test connections would
	# stack and every signal would be recorded N times.
	var manager: Node = get_node_or_null("/root/SceneManager")
	assert_not_null(manager, "SceneManager must be an autoload")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested_scenes.append(path))


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()
	requested_scenes = []


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null
	get_node("/root/AudioManager").reset()


func _mount(size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)

	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "casa.tscn must load")
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


# SC-E02-P1-14
func test_both_aspects_pass_the_geometry_oracle() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		var stage: Control = _mount(size)
		await wait_frames(3)

		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(stage, size, GeometryOracle.CARE_ROOM_SPEC)
		assert_true(findings.is_empty(), "%dx%d: %s" % [size.x, size.y, oracle.summary()])

		stage.get_parent().queue_free()


# SC-E02-P1-15
func test_the_hub_exposes_rig_bubble_dots_hud_and_six_doors() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_frames(3)

	assert_not_null(scene.rig, "QuiQui lives in the hub")
	assert_true(scene.rig.get_visual_global_rect().has_area(), "QuiQui is visible")
	assert_not_null(scene.bubble)
	assert_not_null(scene.dots)
	assert_not_null(scene.hud)

	var door_steps: Array[String] = ["FEED", "BATH", "DRESS", "PLAY", "SLEEP", "VILA"]
	for step: String in door_steps:
		var door: TapButton = scene.door(step)
		assert_not_null(door, "the %s door must exist" % step)
		assert_true(door.is_in_group(GeometryOracle.HIT_GROUP))
		var box: Rect2 = door.get_global_rect()
		assert_true(box.size.x >= 120.0 and box.size.y >= 120.0, "%s door is %s" % [step, box.size])


# SC-E02-P1-16
func test_door_taps_fire_once_despite_the_mouse_echo() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_frames(3)
	var asked: Array[String] = []
	scene.door_requested.connect(func(step: String) -> void: asked.append(step))

	var feed_door: TapButton = scene.door("FEED")
	for event: InputEvent in TouchSim.tap_events(feed_door, true):
		feed_door._gui_input(event)

	assert_eq(scene.door_taps, 1, "one tap, one door press")
	assert_eq(asked, ["FEED"])


# SC-E02-P1-17 — a door to a scene that does not exist yet must never navigate
func test_tapping_the_vila_door_stays_pending() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_frames(3)

	var vila_door: TapButton = scene.door("VILA")
	for event: InputEvent in TouchSim.tap_events(vila_door, true):
		vila_door._gui_input(event)

	assert_eq(scene.door_taps, 1)
	assert_true(
		requested_scenes.is_empty(),
		"vila.tscn arrives with e08 — the hub must stay honest and log scene.pending instead"
	)


# SC-E02-P1-18
func test_eight_seconds_of_idle_show_the_wish_and_the_longing_face() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_frames(3)
	scene.manual_step = true
	assert_false(scene.bubble.is_showing(), "a fresh hub hides the wish")
	# A touch zeroes the idle timer through real behavior, so the stepped
	# timeline below starts from exactly 0 regardless of real-frame drift.
	for event: InputEvent in TouchSim.tap_events(scene.rig, true):
		scene.rig._gui_input(event)
	assert_false(scene.bubble.is_showing())

	scene.advance(7.5)
	assert_false(scene.bubble.is_showing(), "7.5 s of quiet is still patient")

	scene.advance(0.6)
	assert_true(scene.bubble.is_showing(), "8.0 s without touch shows the wish bubble")
	assert_eq(scene.rig.expression_id, "carente", "QuiQui shows she misses the child")
	assert_eq(scene.bubble.wish_id(), "cenoura", "the first wish of a fresh cycle is food")

	for event: InputEvent in TouchSim.tap_events(scene.rig, true):
		scene.rig._gui_input(event)

	assert_false(scene.bubble.is_showing(), "touch answers the wish")
	assert_eq(scene.rig.expression_id, "rindo", "and QuiQui laughs again")


# SC-E02-P1-19
func test_dots_and_highlight_track_the_care_loop_manager() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_frames(3)
	var clm: Node = get_node("/root/CareLoopManager")
	var probe: FsmProbe = FsmProbe.new().attach(clm.fsm)

	assert_eq(scene.dots.completed_steps(), 0, "a fresh cycle shows no dots")
	assert_eq(scene.door("FEED").modulate.a, 1.0, "the FEED door is the one that glows")
	assert_lt(scene.door("BATH").modulate.a, 1.0, "later doors wait dimmed")

	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)

	assert_eq(scene.dots.completed_steps(), 1, "one step done lights one dot")
	assert_eq(scene.door("BATH").modulate.a, 1.0, "the glow moved to the BATH door")
	assert_lt(scene.door("FEED").modulate.a, 1.0)

	clm.complete_step(clm.STATE_BATH)
	clm.complete_step(clm.STATE_DRESS)
	clm.complete_step(clm.STATE_PLAY)
	clm.complete_step(clm.STATE_SLEEP)

	assert_eq(scene.dots.completed_steps(), 5, "a finished cycle lights all five")
	assert_true(probe.is_clean(), "the walk is legal end to end: %s" % probe.summary())
	probe.detach()


# SC-E02-P1-20
func test_the_hub_voice_welcomes_the_child() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_frames(3)

	assert_true(scene.voice_started, "hub_bem_vindo.ogg must greet on arrival")


# BUG-009: the Vila door is a destination, not a waiting care step — dimming it
# says "disabled" to a child who can tap it.
func test_the_vila_door_is_never_dimmed() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_frames(3)

	assert_eq(scene.door("VILA").modulate.a, 1.0, "the recycling door always looks tappable")

	var clm: Node = get_node("/root/CareLoopManager")
	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)
	assert_eq(scene.door("VILA").modulate.a, 1.0, "and stays that way as the cycle advances")
	TestReset.reset_all()


# BUG-013: the layout gate must measure the character the child sees, and the
# scene must actually declare the groups the spec asserts.
func test_the_hub_declares_every_group_its_spec_asserts() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		var stage: Control = _mount(size)
		await wait_frames(3)

		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(stage, size, GeometryOracle.CARE_ROOM_SPEC)
		assert_true(findings.is_empty(), "%dx%d: %s" % [size.x, size.y, oracle.summary()])

		stage.get_parent().queue_free()


func test_the_painted_character_keeps_the_design_height_on_ipad() -> void:
	scene = _mount(GeometryOracle.IPAD_4_3) as CasaScene
	await wait_frames(3)

	var painted: Rect2 = scene.rig.get_visual_global_rect()
	var canvas: Vector2 = Vector2(GeometryOracle.IPAD_4_3)
	var height_ratio: float = painted.size.y / canvas.y
	var feet_ratio: float = painted.end.y / canvas.y

	assert_between(height_ratio, 0.55, 0.65, "DESIGN §3: 55-65 % of the viewport height, not 42 %")
	assert_almost_eq(feet_ratio, 0.78, 0.02, "and the feet stay on the 78 % line")
	assert_almost_eq(
		scene.rig.size.y,
		painted.size.y,
		painted.size.y * 0.03,
		"the box is the character, with no dead space above her head"
	)


# Round 3 (BUG-013): the bubble hangs above the head line, so the character growing
# to her design height must not push her head through the bubble. The face is a
# pre-reading child's only feedback channel.
func test_the_bubble_never_covers_the_character_on_either_aspect() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		scene = _mount(size) as CasaScene
		await wait_frames(3)
		scene.bubble.show_wish(scene.WISH_ICONS["FEED"])
		await wait_frames(2)

		var head: float = scene.rig.get_visual_global_rect().position.y
		var bubble_bottom: float = scene.bubble.get_global_rect().end.y
		assert_true(
			bubble_bottom <= head + 1.0,
			"%dx%d: the bubble ends at %.1f but her head starts at %.1f" % [size.x, size.y, bubble_bottom, head],
		)
		scene.bubble.hide_wish()
		scene.get_parent().queue_free()
		scene = null
