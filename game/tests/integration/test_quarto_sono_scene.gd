# story: e07s01
extends GutTest
## The bedroom: dim the lamp, tuck her in, SLEEP is credited once. Order is free, both
## are required, and the room never goes dark enough to lose her face.

const SCENE_PATH: String = "res://scenes/quarto_sono.tscn"
const CELEBRACAO_PATH: String = "res://scenes/celebracao.tscn"

var scene: SleepScene = null
var viewport: SubViewport = null
var requested: Array[String] = []


func before_all() -> void:
	var sm: Node = get_node("/root/SceneManager")
	sm.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))


func before_each() -> void:
	TestReset.reset_all()
	requested = []


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount(size: Vector2i = GeometryOracle.DESKTOP_16_9) -> SleepScene:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	scene = (load(SCENE_PATH) as PackedScene).instantiate() as SleepScene
	scene.manual_step = true
	viewport.add_child(scene)
	return scene


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _tap(control: Control) -> void:
	_deliver(control, TouchSim.tap_events(control, true))


func _tuck() -> void:
	var onto: Vector2 = scene.rig.get_visual_global_rect().get_center()
	_deliver(scene.plush, TouchSim.drag_events(scene.plush, onto, 10, true))
	scene.plush.advance(TouchDraggable.RETURN_SEC)


func _walk_to_sleep() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	for step: String in [CareSteps.FEED, CareSteps.BATH, CareSteps.DRESS, CareSteps.PLAY]:
		clm.call("begin_step", step)
		clm.call("complete_step", step)
	clm.call("begin_step", CareSteps.SLEEP)


# ── SC-E07-P0-01 the lamp dims the room, not the character ─────────────────


func test_the_lamp_dims_the_background_and_never_the_rig() -> void:
	_mount()
	await wait_process_frames(3)

	_tap(scene.lamp)

	assert_false(scene.lamp_on, "the lamp is off")
	assert_eq(scene.background.modulate, SleepScene.NIGHT_TINT, "the room is tinted")
	assert_eq(scene.rig.modulate, Color.WHITE, "the character is not (T-E07-01)")


func test_the_lamp_toggles_back_on() -> void:
	_mount()
	await wait_process_frames(3)
	_tap(scene.lamp)

	_tap(scene.lamp)

	assert_true(scene.lamp_on)
	assert_eq(scene.background.modulate, SleepScene.LIT_TINT)


# ── SC-E07-P0-02 the tuck is idempotent ───────────────────────────────────


func test_the_tuck_sets_the_sleepy_face_and_starts_zzz_once() -> void:
	_mount()
	await wait_process_frames(3)

	_tuck()

	assert_true(scene.tucked)
	assert_eq(scene.rig.expression_id, "sleepy")
	assert_true(scene.zzz.emitting, "the zzz burst runs")
	# e07 post-epic (review B should-fix 3): the old test only re-read the expression, so a
	# `zzz.restart()` on the second tuck would have passed. Stop the burst first, then tuck again.
	scene.zzz.emitting = false
	assert_false(scene.tuck(), "the seam refuses a second tuck")
	assert_false(scene.zzz.emitting, "so the burst is not restarted")
	assert_eq(scene.rig.expression_id, "sleepy", "and the sleepy face stays")


# ── SC-E07-P0-03 both interactions credit SLEEP once ──────────────────────


func test_both_interactions_credit_sleep_and_request_the_celebration_once() -> void:
	_walk_to_sleep()
	var clm: Node = get_node("/root/CareLoopManager")
	assert_eq(str(clm.call("state_id")), CareSteps.SLEEP)

	_mount()
	await wait_process_frames(3)
	_tuck()
	_tap(scene.lamp)

	assert_eq(scene.fsm.state, SleepScene.STATE_FINISHED)
	assert_true(scene.credited)
	assert_eq(str(clm.call("state_id")), CareSteps.CELEBRATE, "the loop moved to CELEBRATE")
	assert_eq(requested, [CELEBRACAO_PATH], "one request")
	assert_false(clm.call("complete_step", CareSteps.SLEEP), "a second credit is refused")


# ── SC-E07-P1-04 one interaction is not enough ────────────────────────────


func test_the_lamp_is_inert_once_the_step_is_finished() -> void:
	_walk_to_sleep()
	_mount()
	await wait_process_frames(3)
	_tuck()
	_tap(scene.lamp)
	assert_eq(scene.fsm.state, SleepScene.STATE_FINISHED)
	assert_false(scene.lamp_on, "the winning tap dimmed the room")

	_tap(scene.lamp)

	assert_false(scene.lamp_on, "a tap after finishing changes nothing")
	assert_eq(scene.background.modulate, SleepScene.NIGHT_TINT, "and the room stays dark")


func test_the_lamp_alone_does_not_credit() -> void:
	_walk_to_sleep()
	_mount()
	await wait_process_frames(3)

	_tap(scene.lamp)

	assert_eq(scene.fsm.state, SleepScene.STATE_SLEEPING)
	assert_false(scene.credited)
	assert_eq(requested, [], "nothing requested yet")


# ── SC-E07-P1-05 leaving early abandons and stops the particles ───────────


func test_leaving_before_both_abandons_and_stops_the_particles() -> void:
	_walk_to_sleep()
	var clm: Node = get_node("/root/CareLoopManager")
	_mount()
	await wait_process_frames(3)
	_tuck()

	_tap(scene.get_node("HomeButton") as TapButton)

	assert_false(scene.zzz.emitting, "particles stopped")
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the step is abandoned")
	assert_false(scene.credited)


# ── SC-E07-P2-06 house rules ───────────────────────────────────────────────


func test_the_bedroom_passes_the_oracle_on_both_canvases_and_has_no_text() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		viewport = SubViewport.new()
		viewport.size = size
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child_autofree(viewport)
		var mounted: SleepScene = (load(SCENE_PATH) as PackedScene).instantiate() as SleepScene
		mounted.manual_step = true
		viewport.add_child(mounted)
		await wait_process_frames(3)

		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		for node: Node in mounted.find_children("*", "Label", true, false):
			assert_true((node as Label).text.is_empty(), "%s carries text" % node.name)
		mounted.queue_free()


# e07 review B: an uncredited SLEEP must go home, not open a rewardless party.
func test_an_uncredited_finish_goes_home_instead_of_the_celebration() -> void:
	_mount()
	await wait_process_frames(3)
	_tuck()
	_tap(scene.lamp)

	assert_eq(scene.fsm.state, SleepScene.STATE_FINISHED)
	assert_false(scene.credited, "the loop was never in SLEEP")
	assert_eq(requested, [SleepScene.CASA_PATH], "the hub, not a rewardless celebration")


## e07 post-epic (review B should-fix 5): `play_music` always swaps players, so an unguarded
## call restarts the hub's theme from 0 s under the zzz. The threat model promises the opposite:
## "music continues rather than restarting".
func test_the_bedroom_does_not_restart_the_theme_it_arrives_on() -> void:
	var audio: Node = get_node("/root/AudioManager")
	audio.call("play_music", load(SleepScene.MUSIC_PATH) as AudioStream)
	var active: AudioStreamPlayer = audio.get("_active_music")

	_mount()

	assert_eq(audio.get("_active_music"), active, "play_music swaps players: it was not called")
	assert_true(bool(audio.call("is_music_playing", load(SleepScene.MUSIC_PATH) as AudioStream)))


## e07 post-epic (review B should-fix 6): the bedroom was the only care room that made no sound
## at all, and it carried a dead VOICE_PATH constant pointing at the celebration's clip. There is
## no bedtime line in the set (recorded in ADR-009), so the room answers with shipped SFX.
func test_the_lamp_and_the_tuck_make_a_sound() -> void:
	var audio: Node = get_node("/root/AudioManager")
	_mount()
	await wait_process_frames(3)
	var plays: int = int(audio.call("sfx_cursor"))

	_tap(scene.lamp)
	assert_eq(int(audio.call("sfx_cursor")), plays + 1, "the lamp clicks")

	_tuck()
	assert_eq(int(audio.call("sfx_cursor")), plays + 3, "a thud, then the success chime that ends the step")


## e07 post-epic (review B should-fix 4): the frozen contract promises `tuck() -> bool`, and the
## suite only drove the drag slot. The seam is the contract; the drag is one of its callers.
func test_the_tuck_seam_reports_the_first_tuck_only() -> void:
	_mount()
	await wait_process_frames(3)

	assert_true(scene.tuck(), "the first tuck happens")
	assert_false(scene.tuck(), "the second one is a no-op")
	assert_eq(scene.rig.expression_id, "sleepy")


## e07 post-epic (review A consider 3, review B consider 14): `rig.modulate` alone would not
## catch a tint applied to the rig's layers, or a `CanvasModulate` that darkens the whole
## canvas — the exact failure T-E07-01 exists for. And the assertion only means something if
## the character is actually painted.
func test_the_night_tint_never_reaches_a_layer_or_the_canvas() -> void:
	_mount()
	await wait_process_frames(3)

	_tap(scene.lamp)

	var painted: Sprite2D = scene.rig.get_node("Pivot/Expression") as Sprite2D
	assert_not_null(painted.texture, "the character is painted, so a tint would be visible")
	for layer: Node in scene.rig.get_node("Pivot").get_children():
		if layer is Sprite2D:
			assert_eq((layer as Sprite2D).modulate, Color.WHITE, "%s was tinted" % layer.name)
	assert_eq(scene.find_children("*", "CanvasModulate", true, false).size(), 0, "nothing darkens the whole canvas")
