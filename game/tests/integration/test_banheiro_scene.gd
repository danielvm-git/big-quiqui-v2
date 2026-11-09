# story: e04s02
extends GutTest
## The bath room, stage 1 (SOAP): eight foam patches on her body, the sponge soaks
## them, and the last one closes the stage.
##
## Geometry claims are asserted on the *hull*, not on the box: that is the whole point
## of e04s01, and the failure it prevents (patches on the wallpaper) is invisible at
## 16:9.

const SCENE_PATH: String = "res://scenes/banheiro.tscn"

var scene: BathScene = null


func before_each() -> void:
	TestReset.reset_all()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount(size: Vector2i) -> BathScene:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "banheiro.tscn must load")
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as BathScene


# ── SC-E04-P0-10 the patches are on her body, on every canvas ────────────────


func test_every_patch_starts_inside_the_hull_on_both_aspects() -> void:
	for size: Vector2i in [Vector2i(1920, 1080), Vector2i(1920, 1440), Vector2i(2048, 1536)]:
		scene = _mount(size)
		await wait_frames(3)

		var hull: PackedVector2Array = scene.rig.scrub_hull_global()
		assert_eq(scene.blob_count(), 8, "%s: eight patches" % size)
		for index: int in range(scene.blob_count()):
			var blob: FoamBlob = scene.blob(index)
			assert_true(
				Geometry2D.is_point_in_polygon(blob.get_global_rect().get_center(), hull),
				"%s: patch %d at %s must sit inside the hull" % [size, index, blob.get_global_rect().get_center()],
			)
			assert_gt(blob.size.x, 24.0, "%s: patch %d is big enough to hit" % [size, index])

		scene.get_parent().queue_free()
		scene = null


# ── SC-E04-P0-11 scrubbing soaks exactly one patch ──────────────────────────


func test_scrubbing_a_patch_soaks_it_once() -> void:
	scene = _mount(Vector2i(2048, 1536))
	await wait_frames(3)
	var target: FoamBlob = scene.blob(3)
	var point: Vector2 = target.get_global_rect().get_center()

	scene.sponge.scrubbed.emit(point)
	scene.sponge.scrubbed.emit(point)

	assert_true(target.is_soaked, "the patch under the finger is soaked")
	assert_eq(scene.soaked, 1, "and counted once, not twice")
	assert_eq(scene.fsm.state, BathScene.STATE_SOAP, "seven patches still to go")


func test_scrubbing_off_the_patches_soaks_nothing() -> void:
	scene = _mount(Vector2i(2048, 1536))
	await wait_frames(3)

	scene.sponge.scrubbed.emit(Vector2(4.0, 4.0))  # a corner of the screen

	assert_eq(scene.soaked, 0, "a scrub on the wallpaper does nothing")


# ── SC-E04-P0-12 the last patch closes the stage, once ──────────────────────


func test_the_last_patch_closes_the_stage_exactly_once() -> void:
	scene = _mount(Vector2i(1920, 1080))
	await wait_frames(3)

	for index: int in range(scene.blob_count()):
		scene.sponge.scrubbed.emit(scene.blob(index).get_global_rect().get_center())

	assert_eq(scene.soaked, 8)
	assert_eq(scene.fsm.state, BathScene.STATE_SOAP_DONE, "the stage is done")
	assert_false(scene.fsm.transition_to(BathScene.STATE_SOAP), "and the edge back is illegal")


# ── SC-E04-P0-13 a resize mid-stage keeps the patches on her body ───────────


func test_a_resize_keeps_the_patches_inside_the_hull() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	scene = (load(SCENE_PATH) as PackedScene).instantiate() as BathScene
	viewport.add_child(scene)
	await wait_frames(3)

	viewport.size = Vector2i(2048, 1536)
	await wait_frames(3)

	var hull: PackedVector2Array = scene.rig.scrub_hull_global()
	for index: int in range(scene.blob_count()):
		assert_true(
			Geometry2D.is_point_in_polygon(scene.blob(index).get_global_rect().get_center(), hull),
			"patch %d stayed on the body after the canvas changed" % index,
		)


# ── SC-E04-P0-14 the soaps change the foam, never the geometry ─────────────


func test_tapping_a_soap_recolours_every_patch() -> void:
	scene = _mount(Vector2i(2048, 1536))
	await wait_frames(3)
	var before: Color = scene.blob(0).self_modulate

	scene.soap(1).tapped.emit()

	assert_ne(scene.blob(0).self_modulate, before, "the foam took the new scent colour")
	assert_true(
		Geometry2D.is_point_in_polygon(scene.blob(0).get_global_rect().get_center(), scene.rig.scrub_hull_global()),
		"and stayed on her body",
	)


# ── house rules ────────────────────────────────────────────────────────────


func test_the_scene_declares_the_groups_the_spec_asserts() -> void:
	scene = _mount(Vector2i(2048, 1536))
	await wait_frames(3)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(scene, Vector2i(2048, 1536), GeometryOracle.STEP_ROOM_SPEC)
	assert_true(findings.is_empty(), oracle.summary())


func test_the_bath_room_has_no_text() -> void:
	scene = _mount(Vector2i(1920, 1080))
	await wait_frames(3)

	for node: Node in scene.find_children("*", "Label", true, false):
		assert_true((node as Label).text.is_empty(), "%s carries text" % node.name)


# ── SC-E04-P0-20 SOAP -> RINSE -> DRY, on effort ─────────────────────────────


func _soak_everything() -> void:
	for index: int in range(scene.blob_count()):
		scene.sponge.scrubbed.emit(scene.blob(index).get_global_rect().get_center())


func _scrub_body(device: TouchDraggable, points: int) -> void:
	var centre: Vector2 = scene.rig.get_visual_global_rect().get_center()
	for step: int in range(points):
		device.scrubbed.emit(centre + Vector2(float(step % 3) - 1.0, 0.0))


func _reach_rinse() -> void:
	_soak_everything()
	scene.advance(BathScene.STAGE_GAP_SEC + 0.1)


func test_the_stage_machine_walks_soap_rinse_dry_finished() -> void:
	scene = _mount(Vector2i(1920, 1080))
	await wait_frames(3)
	assert_eq(scene.fsm.state, BathScene.STATE_SOAP)

	_reach_rinse()
	assert_eq(scene.fsm.state, BathScene.STATE_RINSE, "soap done opens the shower")
	assert_false(scene.sponge.enabled, "and the sponge is put away")
	assert_true(scene.shower.enabled, "the showerhead is in hand")

	_scrub_body(scene.shower, BathScene.RINSE_POINTS)
	scene.advance(BathScene.STAGE_GAP_SEC + 0.1)
	assert_eq(scene.fsm.state, BathScene.STATE_DRY, "rinsing enough opens the towel")
	assert_false(scene.shower.enabled)
	assert_true(scene.towel.enabled)

	_scrub_body(scene.towel, BathScene.DRY_POINTS)
	assert_eq(scene.fsm.state, BathScene.STATE_FINISHED, "drying finishes the bath")
	assert_eq(scene.rig.expression_id, "shining", "she comes out shiny")


func test_scrubbing_off_the_body_does_not_advance_a_stage() -> void:
	scene = _mount(Vector2i(1920, 1080))
	await wait_frames(3)
	_reach_rinse()

	for step: int in range(BathScene.RINSE_POINTS * 2):
		scene.shower.scrubbed.emit(Vector2(6.0, 6.0))
	scene.advance(BathScene.STAGE_GAP_SEC + 0.1)

	assert_eq(scene.fsm.state, BathScene.STATE_RINSE, "points on the wallpaper are not a rinse")
	assert_eq(scene.rinsed, 0)


# ── SC-E04-P0-21 BATH is credited exactly once (T-E04-02) ───────────────────


func test_finishing_the_bath_credits_the_step_once() -> void:
	var care: Node = get_node("/root/CareLoopManager")
	care.call("begin_step", CareSteps.FEED)
	care.call("complete_step", CareSteps.FEED)
	care.call("begin_step", CareSteps.BATH)
	assert_eq(care.call("state_id"), CareSteps.BATH)

	scene = _mount(Vector2i(1920, 1080))
	await wait_frames(3)
	_reach_rinse()
	_scrub_body(scene.shower, BathScene.RINSE_POINTS)
	scene.advance(BathScene.STAGE_GAP_SEC + 0.1)
	_scrub_body(scene.towel, BathScene.DRY_POINTS)

	assert_true(scene.credited, "the visit credits BATH")
	assert_eq(str(care.call("state_id")), CareSteps.DRESS, "and the loop moved on")
	assert_false(care.call("complete_step", CareSteps.BATH), "a second credit is refused")


## Coming back after BATH is free play: the room still works, nothing is credited.
func test_replaying_the_bath_after_the_step_is_free_play() -> void:
	var care: Node = get_node("/root/CareLoopManager")
	care.call("begin_step", CareSteps.FEED)
	care.call("complete_step", CareSteps.FEED)
	assert_eq(str(care.call("state_id")), CareSteps.BATH)

	scene = _mount(Vector2i(1920, 1080))
	await wait_frames(3)
	care.call("begin_step", CareSteps.BATH)
	care.call("complete_step", CareSteps.BATH)
	assert_eq(str(care.call("state_id")), CareSteps.DRESS)

	_reach_rinse()
	_scrub_body(scene.shower, BathScene.RINSE_POINTS)
	scene.advance(BathScene.STAGE_GAP_SEC + 0.1)
	_scrub_body(scene.towel, BathScene.DRY_POINTS)

	assert_eq(scene.fsm.state, BathScene.STATE_FINISHED, "the room still finishes")
	assert_false(scene.credited, "but nothing is credited twice")
	assert_eq(str(care.call("state_id")), CareSteps.DRESS, "and the loop stays put")


# ── SC-E04-P0-22 leaving mid-stage abandons and releases (T-E04-06) ──────────


func test_leaving_during_rinse_abandons_the_step_and_releases_the_devices() -> void:
	var care: Node = get_node("/root/CareLoopManager")
	care.call("begin_step", CareSteps.FEED)
	care.call("complete_step", CareSteps.FEED)
	care.call("begin_step", CareSteps.BATH)

	scene = _mount(Vector2i(1920, 1080))
	await wait_frames(3)
	_reach_rinse()
	_scrub_body(scene.shower, 3)

	(scene.get_node("HomeButton") as TapButton).tapped.emit()

	assert_eq(str(care.call("state_id")), CareSteps.IDLE, "the step is abandoned, not credited")
	assert_eq(scene.shower.state_id(), "REST", "the device let go of the finger")
	assert_false(scene.credited)


func test_the_bath_voice_line_is_a_file_that_exists() -> void:
	# BUG-059: the constant was written from the event name (`banho_…`) while the family's
	# clip ships as `bath_…`. `_play_stream` degrades silently, so the room was simply mute.
	var path: String = VoiceKeyResolver.path_for_key(BathScene.VOICE_KEY)
	assert_true(ResourceLoader.exists(path), "voice key must resolve: %s" % path)
