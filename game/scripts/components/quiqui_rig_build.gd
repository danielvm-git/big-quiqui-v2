# story: e01s04
class_name QuiQuiRigBuild
extends RefCounted


static func assemble(rig: QuiQuiRig) -> void:
	rig.pivot = Node2D.new()
	rig.pivot.name = "Pivot"
	rig.pivot.position = Vector2(rig.size.x * 0.5, rig.size.y)
	rig.add_child(rig.pivot)
	rig.body = _sprite(rig, "Body", QuiQuiRig.Z_BODY)
	rig.outfit = _sprite(rig, "Outfit", QuiQuiRig.Z_OUTFIT)
	rig.expression = _sprite(rig, "Expression", QuiQuiRig.Z_EXPRESSION)
	rig.headwear = _sprite(rig, "Headwear", QuiQuiRig.Z_HEADWEAR)
	rig.neck = _sprite(rig, "Neck", QuiQuiRig.Z_NECK)
	rig.glasses = _sprite(rig, "Glasses", QuiQuiRig.Z_GLASSES)
	for layer: Sprite2D in [rig.outfit, rig.headwear, rig.neck, rig.glasses]:
		layer.visible = false
	rig.mouth_zone = Control.new()
	rig.mouth_zone.name = "MouthZone"
	rig.mouth_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rig.add_child(rig.mouth_zone)


static func _sprite(rig: QuiQuiRig, sprite_name: String, layer: int) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = sprite_name
	sprite.z_index = layer
	sprite.centered = true
	rig.pivot.add_child(sprite)
	return sprite
