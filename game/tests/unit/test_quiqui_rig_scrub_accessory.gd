# story: e01s04
extends GutTest

var rig: QuiQuiRig = null


func before_each() -> void:
	rig = QuiQuiRig.new()
	rig.name = "QuiQuiRig"
	rig.size = Vector2(400.0, 600.0)
	rig.manual_step = true
	add_child_autofree(rig)


func after_each() -> void:
	rig.reset()


func test_the_hull_follows_the_opaque_rect_on_every_canvas() -> void:
	for canvas: Vector2i in [Vector2i(1920, 1080), Vector2i(1920, 1440), Vector2i(2048, 1536)]:
		var viewport: SubViewport = SubViewport.new()
		viewport.size = canvas
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child_autofree(viewport)
		var stage: Control = Control.new()
		stage.set_anchors_preset(Control.PRESET_FULL_RECT)
		viewport.add_child(stage)

		var mounted: QuiQuiRig = QuiQuiRig.new()
		mounted.manual_step = true
		mounted.anchor_left = 0.5
		mounted.anchor_right = 0.5
		mounted.anchor_top = 0.78 - 620.0 / 1080.0
		mounted.anchor_bottom = 0.78
		mounted.offset_left = -320.0
		mounted.offset_right = 320.0
		stage.add_child(mounted)
		await wait_frames(2)

		var hull: PackedVector2Array = mounted.scrub_hull_global()
		var painted: Rect2 = mounted.get_visual_global_rect()
		assert_eq(hull.size(), QuiQuiRig.SCRUB_HULL_POINTS, "%s: hull vertex count" % canvas)

		var box: Rect2 = Rect2(hull[0], Vector2.ZERO)
		for point: Vector2 in hull:
			box = box.expand(point)

		assert_true(painted.grow(1.0).encloses(box), "%s: hull %s must live inside the art %s" % [canvas, box, painted])
		assert_almost_eq(
			box.size.y,
			painted.size.y - QuiQuiRig.SCRUB_HULL_INSET * 2.0,
			4.0,
			"%s: hull follows the art height" % canvas
		)
		assert_almost_eq(box.get_center().x, float(canvas.x) * 0.5, 3.0, "%s: and stays centred" % canvas)
		assert_gt(box.size.y / float(canvas.y), 0.5, "%s: the hull is the body, not a button" % canvas)

		viewport.queue_free()
		await wait_frames(1)


func test_the_hull_contains_the_body_and_not_the_transparent_margin() -> void:
	var painted: Rect2 = rig.get_visual_global_rect()
	var hull: PackedVector2Array = rig.scrub_hull_global()

	assert_gt(hull.size(), 2, "a polygon, not a point list")
	var box: Rect2 = Rect2(hull[0], Vector2.ZERO)
	for point: Vector2 in hull:
		box = box.expand(point)
	assert_lt(box.size.y, painted.size.y, "the hull is inset inside the opaque art")
	assert_gt(box.size.y, painted.size.y * 0.8, "but not so far in that the body is unreachable")


func test_the_expression_layer_sits_above_outfit_and_accessories() -> void:
	assert_true(rig.set_outfit("floral_dress"), "the outfit loads")
	assert_true(rig.set_accessory("head", "flower_tiara"))
	assert_true(rig.set_accessory("eyes", "heart_glasses"))
	rig.set_expression("base")

	assert_gt(rig.expression.z_index, rig.outfit.z_index, "the face is above the dress")
	assert_true(rig.expression.visible, "and visible")
	var mouth: Vector2 = rig.mouth_global_center()
	for slot: String in ["head", "eyes"]:
		var sprite: Sprite2D = rig.headwear if slot == "head" else rig.glasses
		assert_false(
			_art_rect(sprite).has_point(mouth),
			"%s art must not cover the mouth zone at %s" % [slot, mouth],
		)


func _art_rect(sprite: Sprite2D) -> Rect2:
	return Rect2(
		sprite.global_position - sprite.texture.get_size() * 0.5 * sprite.global_scale,
		sprite.texture.get_size() * sprite.global_scale
	)


func test_a_second_accessory_replaces_the_first_in_its_slot() -> void:
	assert_true(rig.set_accessory("head", "flower_tiara"))
	assert_true(rig.set_accessory("head", "crown"))
	assert_eq(rig.accessory_id("head"), "crown", "the newest hat wins")
	assert_eq(rig.accessory_id("eyes"), "", "and other slots are untouched")


func test_an_invalid_accessory_is_refused_and_changes_nothing() -> void:
	for bad: String in ["../etc/passwd", "TIARA", "a".repeat(65), "id.with.dot"]:
		assert_false(rig.set_accessory("head", bad), bad)
	assert_eq(rig.accessory_id("head"), "", "nothing was equipped")


func test_an_unknown_slot_is_refused_loudly_enough_to_debug() -> void:
	assert_false(rig.set_accessory("tail", "flower_tiara"))
	assert_true(rig.get_visual_global_rect().has_area(), "and the rig still renders")
