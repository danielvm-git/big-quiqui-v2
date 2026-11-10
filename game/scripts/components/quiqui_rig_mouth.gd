# story: e03s02
class_name QuiQuiRigMouth
extends RefCounted


static func global_center(rig: QuiQuiRig) -> Vector2:
	return rig.global_position if rig.mouth_zone == null else rig.mouth_zone.get_global_rect().get_center()


static func update_food_proximity(rig: QuiQuiRig, global_point: Vector2) -> void:
	if global_point.distance_to(global_center(rig)) >= QuiQuiRig.MOUTH_ANTICIPATION_PX:
		clear_food_proximity(rig)
	elif rig._face_before_anticipation.is_empty():
		var face: String = (
			QuiQuiRig.NEUTRAL_EXPRESSION if rig.expression_id == QuiQuiRig.BLINK_EXPRESSION else rig.expression_id
		)
		rig._face_before_anticipation = face
		rig.set_expression(QuiQuiRig.ANTICIPATION_EXPRESSION)


static func clear_food_proximity(rig: QuiQuiRig) -> void:
	var face: String = rig._face_before_anticipation
	rig._face_before_anticipation = ""
	if not face.is_empty() and rig.expression_id == QuiQuiRig.ANTICIPATION_EXPRESSION:
		rig.set_expression(face)
