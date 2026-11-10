# story: e13s05
class_name OutfitLedger
extends RefCounted
## The outfit-slot half of the save, extracted from `ProgressManager` so the save owner stays
## under the 300-line bar and keeps its rationale comments. Pure functions over `SaveData`: they
## validate and mutate the slot map, but never save and never emit. The owner decides both.


static func set_slot(data: SaveData, slot: String, id: String) -> bool:
	if data == null or not Ids.is_valid(slot) or not Ids.is_valid(id):
		return false
	data.equipped_outfits[slot] = id
	return true


static func get_slot(data: SaveData, slot: String) -> String:
	if data == null:
		return ""
	return str(data.equipped_outfits.get(slot, ""))


## True when a slot was worn and now is not. `equip` rejects an empty id, so clearing is its own call.
static func clear(data: SaveData, slot: String) -> bool:
	if data == null or not Ids.is_valid(slot) or not data.equipped_outfits.has(slot):
		return false
	data.equipped_outfits.erase(slot)
	return true


static func dress(data: SaveData, rig: Node) -> void:
	if data == null or rig == null or not is_instance_valid(rig):
		return
	var outfit: String = get_slot(data, SaveData.SLOT_BODY)
	if not outfit.is_empty():
		rig.call("set_outfit", outfit)
	for slot: String in [SaveData.SLOT_HEAD, SaveData.SLOT_NECK, SaveData.SLOT_EYES]:
		var id: String = get_slot(data, slot)
		if not id.is_empty():
			rig.call("set_accessory", slot, id)
