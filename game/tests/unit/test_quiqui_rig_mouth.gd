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


class RigWithoutOpenMouth:
	extends QuiQuiRig

	func _load_art(id: String) -> Texture2D:
		return null if id == ANTICIPATION_EXPRESSION else super(id)


func _rig_without_open_mouth() -> QuiQuiRig:
	var broken: QuiQuiRig = RigWithoutOpenMouth.new()
	broken.size = Vector2(400.0, 600.0)
	broken.manual_step = true
	add_child_autofree(broken)
	return broken


func test_missing_mouth_art_logs_once_over_thirty_near_motions() -> void:
	var broken: QuiQuiRig = _rig_without_open_mouth()
	var near: Vector2 = broken.mouth_global_center() + Vector2(100.0, 0.0)
	var diary: Node = get_node("/root/Log")
	var before: int = diary.call("write_count")

	for motion: int in range(30):
		broken.update_food_proximity(near)

	assert_eq(diary.call("write_count") - before, 1, "one rig.missing_art, not one per motion")
	assert_eq(broken.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION, "she keeps her face")


func test_missing_mouth_art_is_retried_on_the_next_approach_and_keeps_her_face() -> void:
	var broken: QuiQuiRig = _rig_without_open_mouth()
	var near: Vector2 = broken.mouth_global_center() + Vector2(100.0, 0.0)
	var diary: Node = get_node("/root/Log")
	var before: int = diary.call("write_count")

	broken.update_food_proximity(near)
	broken.clear_food_proximity()
	broken.update_food_proximity(near)

	assert_eq(diary.call("write_count") - before, 2, "one line per approach")
	assert_eq(broken.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION)


func test_a_point_under_the_threshold_opens_the_mouth_on_that_call() -> void:
	rig.update_food_proximity(_point_at(219.99))

	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION)


func test_a_point_exactly_on_the_threshold_does_not_open_the_mouth() -> void:
	rig.update_food_proximity(_point_at(QuiQuiRig.MOUTH_ANTICIPATION_PX))

	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION)


func test_a_point_past_the_threshold_does_not_open_the_mouth() -> void:
	rig.update_food_proximity(_point_at(220.01))

	assert_eq(rig.expression_id, QuiQuiRig.NEUTRAL_EXPRESSION)


func test_the_mouth_centre_follows_the_rig_on_screen() -> void:
	var before: Vector2 = rig.mouth_global_center()
	rig.position += Vector2(300.0, 40.0)

	assert_eq(rig.mouth_global_center(), before + Vector2(300.0, 40.0))
	assert_eq(rig.mouth_global_center(), rig.mouth_zone.get_global_rect().get_center())


func test_moving_away_restores_the_face_shown_before() -> void:
	assert_true(rig.set_expression("needy"))

	rig.update_food_proximity(_point_at(10.0))
	assert_eq(rig.expression_id, QuiQuiRig.ANTICIPATION_EXPRESSION)

	rig.update_food_proximity(_point_at(400.0))
	assert_eq(rig.expression_id, "needy", "not always base")


func test_clearing_restores_the_face_shown_before() -> void:
	assert_true(rig.set_expression("needy"))
	rig.update_food_proximity(_point_at(10.0))

	rig.clear_food_proximity()

	assert_eq(rig.expression_id, "needy")


func test_repeated_calls_while_close_do_not_re_emit() -> void:
	var faces: Array[String] = _record_faces()

	rig.update_food_proximity(_point_at(100.0))
	rig.update_food_proximity(_point_at(90.0))
	rig.update_food_proximity(_point_at(80.0))

	assert_eq(faces, [QuiQuiRig.ANTICIPATION_EXPRESSION] as Array[String])


func test_repeated_calls_while_close_keep_the_face_to_restore() -> void:
	assert_true(rig.set_expression("needy"))

	rig.update_food_proximity(_point_at(100.0))
	rig.update_food_proximity(_point_at(90.0))
	rig.update_food_proximity(_point_at(400.0))

	assert_eq(rig.expression_id, "needy", "the mouth never stays stuck open")


func test_a_second_approach_still_restores_the_original_face() -> void:
	assert_true(rig.set_expression("needy"))

	rig.update_food_proximity(_point_at(10.0))
	rig.update_food_proximity(_point_at(400.0))
	rig.update_food_proximity(_point_at(10.0))
	rig.clear_food_proximity()

	assert_eq(rig.expression_id, "needy")


func test_clearing_without_anticipation_changes_nothing() -> void:
	assert_true(rig.set_expression("needy"))
	var faces: Array[String] = _record_faces()
	rig.clear_food_proximity()
	rig.update_food_proximity(_point_at(400.0))
	assert_eq(rig.expression_id, "needy")
	assert_eq(faces.size(), 0, "no signal without a change")


func _point_at(distance: float) -> Vector2:
	return rig.mouth_global_center() + Vector2(distance, 0.0)


func _record_faces() -> Array[String]:
	var faces: Array[String] = []
	rig.expression_changed.connect(func(id: String) -> void: faces.append(id))
	return faces
