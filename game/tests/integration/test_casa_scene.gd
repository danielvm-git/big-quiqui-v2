# story: e02s03
extends GutTest
## SC-E02-P1-14..20 — the hub's input and its care-loop coupling: six doors that fire
## once under mouse echo, an absent target scene that is never navigated to, music on
## arrival, 8 s of idle showing QuiQui's wish, the dots and the door highlight tracking
## the CareLoopManager, and the e07 guarantee that a hub arriving inside a CELEBRATE
## cycle closes it. Layout, inventory and the wish bubble live in `test_casa_layout.gd
## (split at the 300-line guideline, e07 post-epic).

const SCENE_PATH: String = "res://scenes/casa.tscn"
const COZINHA_PATH: String = "res://scenes/cozinha.tscn"
const VILA_PATH: String = "res://scenes/vila.tscn"
const THEME_PATH: String = "res://assets/audio/music/main_theme.ogg"
const KITCHEN_THEME_PATH: String = "res://assets/audio/music/kitchen.ogg"

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


# SC-E02-P1-16
func test_door_taps_fire_once_despite_the_mouse_echo() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	var asked: Array[String] = []
	scene.door_requested.connect(func(step: String) -> void: asked.append(step))
	var feed_door: TapButton = scene.door("FEED")
	for event: InputEvent in TouchSim.tap_events(feed_door, true):
		feed_door._gui_input(event)
	assert_eq(scene.door_taps, 1, "one tap, one door press")
	assert_eq(asked, ["FEED"])


# SC-E03-P1-20
func test_the_feed_door_navigates_to_the_kitchen() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	var feed_door: TapButton = scene.door("FEED")
	for event: InputEvent in TouchSim.tap_events(feed_door, true):
		feed_door._gui_input(event)
	assert_eq(requested_scenes, [COZINHA_PATH])


# Review H1: without the swap, the Casa stayed on screen and every later tap on the
# door was refused as same_scene.
func test_a_long_frame_during_the_fade_still_opens_the_kitchen() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	var manager: Node = get_node("/root/SceneManager")
	var swapped: Array[String] = []
	manager.manual_step = true
	manager.loader = func(path: String) -> void: swapped.append(path)
	var feed_door: TapButton = scene.door("FEED")
	for event: InputEvent in TouchSim.tap_events(feed_door, true):
		feed_door._gui_input(event)
	manager.advance(2.1)
	var seen: Array[String] = swapped.duplicate()
	var busy: bool = manager.is_busy()
	manager.manual_step = false
	manager.loader = Callable()
	assert_eq(seen, [COZINHA_PATH])
	assert_false(busy)


# e03s03: a 4-year-old double-taps, and the door now navigates.
func test_a_double_tap_on_the_feed_door_asks_for_the_kitchen_once() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	var feed_door: TapButton = scene.door("FEED")
	for tap: int in range(2):
		for event: InputEvent in TouchSim.tap_events(feed_door, true):
			feed_door._gui_input(event)
	assert_eq(scene.door_taps, 2)
	assert_eq(requested_scenes, [COZINHA_PATH])
	assert_eq(get_node("/root/SceneManager").pending_scene, "", "no reload is queued")


## Every care step now has a scene, so no door is "pending" any more: this replaces the
## e03-era "doors stay pending" assertion, which had been shrinking epic by epic. A door
## that stops navigating is now a regression, not a feature.
func test_every_care_door_navigates_to_its_scene() -> void:
	var expected: Dictionary = {
		"FEED": "res://scenes/cozinha.tscn",
		"BATH": "res://scenes/banheiro.tscn",
		"DRESS": "res://scenes/closet.tscn",
		"PLAY": "res://scenes/jardim.tscn",
		"SLEEP": "res://scenes/quarto_sono.tscn",
	}
	for step: String in expected.keys():
		requested_scenes = []
		scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
		await wait_process_frames(3)
		var door: TapButton = scene.door(step)
		for event: InputEvent in TouchSim.tap_events(door, true):
			door._gui_input(event)
		assert_eq(requested_scenes, [expected[step]], "%s door" % step)
		scene.queue_free()
		scene = null


## The garden door opens now that the scene exists.
func test_the_play_door_asks_for_the_garden_once() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	var door: TapButton = scene.door("PLAY")
	for tap: int in range(2):
		for event: InputEvent in TouchSim.tap_events(door, true):
			door._gui_input(event)

	assert_eq(requested_scenes, ["res://scenes/jardim.tscn"], "one request, not two")


## The closet door opens now that the scene exists.
func test_the_dress_door_asks_for_the_closet_once() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	var door: TapButton = scene.door("DRESS")
	for tap: int in range(2):
		for event: InputEvent in TouchSim.tap_events(door, true):
			door._gui_input(event)

	assert_eq(requested_scenes, ["res://scenes/closet.tscn"], "one request, not two")


# SC-E03-P1-20: the kitchen theme must not follow the child into the hub.
func test_arriving_from_the_kitchen_restores_the_main_theme() -> void:
	var audio: Node = get_node("/root/AudioManager")
	audio.play_music(load(KITCHEN_THEME_PATH) as AudioStream)
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	assert_true(audio.is_music_playing(load(THEME_PATH) as AudioStream))


func test_arriving_with_silence_starts_the_main_theme() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	assert_true(get_node("/root/AudioManager").is_music_playing(load(THEME_PATH) as AudioStream))


# Asserted before any frame passes, so a short clip cannot end first: Casa decides
# in `_ready`.
func test_arriving_from_the_title_does_not_restart_the_main_theme() -> void:
	var audio: Node = get_node("/root/AudioManager")
	audio.play_music(load(THEME_PATH) as AudioStream)
	var active: AudioStreamPlayer = audio._active_music
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	assert_eq(audio._active_music, active, "play_music always swaps players: it was not called")
	assert_true(audio.is_music_playing(load(THEME_PATH) as AudioStream))


# SC-E02-P1-17 — the Vila door navigates now that vila.tscn exists (e08s01).
func test_tapping_the_vila_door_opens_the_vila() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	var vila_door: TapButton = scene.door("VILA")
	for event: InputEvent in TouchSim.tap_events(vila_door, true):
		vila_door._gui_input(event)
	assert_eq(scene.door_taps, 1)
	assert_eq(requested_scenes, [VILA_PATH])


# SC-E02-P1-18
func test_eight_seconds_of_idle_show_the_wish_and_the_longing_face() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	scene.manual_step = true
	assert_false(scene.bubble.is_showing(), "a fresh hub hides the wish")
	for event: InputEvent in TouchSim.tap_events(scene.rig, true):
		scene.rig._gui_input(event)
	assert_false(scene.bubble.is_showing())
	scene.advance(7.5)
	assert_false(scene.bubble.is_showing(), "7.5 s of quiet is still patient")
	scene.advance(0.6)
	assert_true(scene.bubble.is_showing(), "8.0 s without touch shows the wish bubble")
	assert_eq(scene.rig.expression_id, "needy", "QuiQui shows she misses the child")
	assert_eq(scene.bubble.wish_id(), "carrot", "the first wish of a fresh cycle is food")
	assert_eq(scene.bubble.urgency(), 0, "the first prompt is calm")
	scene.advance(6.0)
	assert_eq(scene.bubble.urgency(), 1, "FIX-01: urgency steps with ESCALATION_SEC")
	for event: InputEvent in TouchSim.tap_events(scene.rig, true):
		scene.rig._gui_input(event)
	assert_false(scene.bubble.is_showing(), "touch answers the wish")
	assert_eq(scene.rig.expression_id, "laughing", "and QuiQui laughs again")


# e07 post-epic (T-E07-05): the Casa is a whitelisted target of the detour guard, so a hub
# that arrives while the loop is still in CELEBRATE must close the cycle itself — otherwise
# it mounts with every care door refusing, the exact brick the guard exists to prevent.
func test_arriving_during_the_celebration_closes_the_cycle() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	clm.call("begin_step", CareSteps.FEED)
	for step: String in [CareSteps.FEED, CareSteps.BATH, CareSteps.DRESS, CareSteps.PLAY, CareSteps.SLEEP]:
		clm.call("complete_step", step)
	assert_eq(str(clm.call("state_id")), CareSteps.CELEBRATE)

	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)

	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the hub is usable again")
	assert_eq(int(clm.get("cycle_id")), 1, "and the cycle closed once")
	assert_eq(scene.door(CareSteps.FEED).modulate.a, 1.0, "the first door is live, not dimmed")


# SC-E02-P1-19
func test_dots_and_highlight_track_the_care_loop_manager() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
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
	await wait_process_frames(3)

	assert_true(scene.voice_started, "home_welcome.ogg must greet on arrival")


# BUG-009: the Vila door is a destination, not a waiting care step — dimming it
# says "disabled" to a child who can tap it.
func test_the_vila_door_is_never_dimmed() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)

	assert_eq(scene.door("VILA").modulate.a, 1.0, "the recycling door always looks tappable")

	var clm: Node = get_node("/root/CareLoopManager")
	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)
	assert_eq(scene.door("VILA").modulate.a, 1.0, "and stays that way as the cycle advances")
	TestReset.reset_all()
