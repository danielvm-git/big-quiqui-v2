# story: e02s03
extends GutTest
## The hub's layout and inventory on their own: `casa.tscn` boots with a rig, a
## bubble, dots, the HUD and six doors; `GeometryOracle` passes on all three
## aspects, the painted character keeps the design height, and the wish bubble
## never covers her face. Input and the care-loop coupling live in
## `test_casa_scene.gd` (split at the 300-line guideline, e07 post-epic).

const SCENE_PATH: String = "res://scenes/casa.tscn"

var scene: CasaScene = null


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()


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
		await wait_process_frames(3)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(stage, size, GeometryOracle.CARE_ROOM_SPEC)
		assert_true(findings.is_empty(), "%dx%d: %s" % [size.x, size.y, oracle.summary()])
		stage.get_parent().queue_free()


# SC-E02-P1-15
func test_the_hub_exposes_rig_bubble_dots_hud_and_six_doors() -> void:
	scene = _mount(GeometryOracle.DESKTOP_16_9) as CasaScene
	await wait_process_frames(3)
	assert_not_null(scene.rig, "QuiQui lives in the hub")
	assert_true(scene.rig.get_visual_global_rect().has_area(), "QuiQui is visible")
	assert_not_null(scene.bubble)
	assert_not_null(scene.dots)
	assert_not_null(scene.hud)
	for step: String in ["FEED", "BATH", "DRESS", "PLAY", "SLEEP", "VILA"]:
		var door: TapButton = scene.door(step)
		assert_not_null(door, "the %s door must exist" % step)
		assert_true(door.is_in_group(GeometryOracle.HIT_GROUP))
		var box: Rect2 = door.get_global_rect()
		assert_true(box.size.x >= 120.0 and box.size.y >= 120.0, "%s door is %s" % [step, box.size])


# BUG-013: the layout gate must measure the character the child sees, and the
# scene must actually declare the groups the spec asserts.
func test_the_hub_declares_every_group_its_spec_asserts() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		var stage: Control = _mount(size)
		await wait_process_frames(3)

		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(stage, size, GeometryOracle.CARE_ROOM_SPEC)
		assert_true(findings.is_empty(), "%dx%d: %s" % [size.x, size.y, oracle.summary()])

		stage.get_parent().queue_free()


func test_the_painted_character_keeps_the_design_height_on_ipad() -> void:
	scene = _mount(GeometryOracle.IPAD_4_3) as CasaScene
	await wait_process_frames(3)

	var painted: Rect2 = scene.rig.get_visual_global_rect()
	var canvas: Vector2 = Vector2(GeometryOracle.IPAD_4_3)
	var height_ratio: float = painted.size.y / canvas.y
	var feet_ratio: float = painted.end.y / canvas.y

	assert_between(height_ratio, 0.55, 0.65, "DESIGN §3: 55-65 % of the viewport height, not 42 %")
	assert_almost_eq(feet_ratio, 0.78, 0.02, "and the feet stay on the 78 % line")
	assert_almost_eq(scene.rig.size.y, painted.size.y, painted.size.y * 0.03, "box matches character")


# Round 3 (BUG-013): the bubble hangs above the head line without covering the face.
func test_the_bubble_never_covers_the_character_on_either_aspect() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		scene = _mount(size) as CasaScene
		await wait_process_frames(3)
		scene.bubble.show_wish(scene.WISH_ICONS["FEED"])
		await wait_process_frames(2)

		var head: float = scene.rig.get_visual_global_rect().position.y
		var bubble_bottom: float = scene.bubble.get_global_rect().end.y
		assert_true(bubble_bottom <= head + 1.0, "%dx%d: bubble <= head" % [size.x, size.y])
		scene.bubble.hide_wish()
		scene.get_parent().queue_free()
		scene = null
