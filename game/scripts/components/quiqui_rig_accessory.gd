# story: e05s01
class_name QuiQuiRigAccessory
extends RefCounted

const ART_ROOT: String = "res://assets/art/items/"
var rig: QuiQuiRig = null


func _init(owner: QuiQuiRig) -> void:
	rig = owner


func set_slot(slot: String, id: String) -> bool:
	var sprite: Sprite2D = _sprite(slot)
	if sprite == null:
		LogSink.emit_from(rig, "rig.invalid_slot", {"slot": "invalid"})
		return false
	if id.is_empty():
		_clear(sprite, slot)
		return true
	return _equip(sprite, slot, id)


func clear_all() -> void:
	for slot: String in AccessorySlots.NAMES:
		set_slot(slot, "")


func id_for(slot: String) -> String:
	return str(rig.accessory_ids.get(slot, ""))


func _equip(sprite: Sprite2D, slot: String, id: String) -> bool:
	if not Ids.is_valid(id):
		LogSink.emit_from(rig, "rig.invalid_accessory", {"slot": slot, "accessory": "invalid"})
		return false
	var texture: Texture2D = _load(id)
	if texture == null:
		LogSink.emit_from(rig, "rig.missing_art", {"accessory": id})
		return false
	sprite.texture = texture
	sprite.visible = true
	rig.accessory_ids[slot] = id
	_place(sprite, slot)
	LogSink.emit_from(rig, "rig.accessory_on", {"slot": slot, "accessory": id})
	return true


func _clear(sprite: Sprite2D, slot: String) -> void:
	sprite.visible = false
	sprite.texture = null
	rig.accessory_ids.erase(slot)
	LogSink.emit_from(rig, "rig.accessory_off", {"slot": slot})


func _place(sprite: Sprite2D, slot: String) -> void:
	if sprite == null or sprite.texture == null or rig.mouth_zone == null:
		return
	var character: float = rig.size.y if rig.size.y > 1.0 else 620.0
	var art: Vector2 = sprite.texture.get_size()
	var factor: float = AccessorySlots.scale_for(slot, art.x, character)
	sprite.scale = Vector2.ONE * factor
	sprite.position = AccessorySlots.position_for(slot, art, factor, character, rig.size.y - rig.mouth_zone.position.y)


func _sprite(slot: String) -> Sprite2D:
	match slot:
		AccessorySlots.SLOT_HEAD:
			return rig.headwear
		AccessorySlots.SLOT_NECK:
			return rig.neck
		AccessorySlots.SLOT_EYES:
			return rig.glasses
		_:
			return null


func _load(id: String) -> Texture2D:
	var path: String = "%s%s.png" % [ART_ROOT, id]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
