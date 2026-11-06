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
