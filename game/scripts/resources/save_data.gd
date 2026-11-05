# story: e01s03
class_name SaveData
extends Resource
## The typed save model (ADR-005). In memory it is a Resource with hard types;
## on disk it is JSON so a save file stays readable, diffable and version-tolerant.
## Every value that reaches disk is validated here first — the manager never
## trusts the file it loaded.

const MAX_COINS: int = 999_999
const MAX_TICKETS: int = 9_999
const MAX_CYCLES: int = 999_999
const MAX_STARS: int = 5

@export var version: int = 1
@export var coins: int = 0
@export var tickets: int = 0
@export var completed_cycles: int = 0
@export var equipped_outfits: Dictionary = {}
@export var owned_furniture: Array[String] = []
@export var placed_furniture: Array[Dictionary] = []
@export var friend_stars: Dictionary = {}


## Ids come from the one owner (`Ids`), never from a local pattern.
static func is_valid_id(value: String) -> bool:
	return Ids.is_valid(value)


func to_dictionary() -> Dictionary:
	return {
		"version": version,
		"coins": coins,
		"tickets": tickets,
		"completed_cycles": completed_cycles,
		"equipped_outfits": equipped_outfits.duplicate(true),
		"owned_furniture": owned_furniture.duplicate(),
		"placed_furniture": placed_furniture.duplicate(true),
		"friend_stars": friend_stars.duplicate(true),
	}


## Rebuilds from an untrusted dictionary, dropping anything malformed.
static func from_dictionary(raw: Dictionary) -> SaveData:
	var data: SaveData = SaveData.new()
	data.version = maxi(int(raw.get("version", 1)), 1)
	data.coins = clampi(int(raw.get("coins", 0)), 0, MAX_COINS)
	data.tickets = clampi(int(raw.get("tickets", 0)), 0, MAX_TICKETS)
	data.completed_cycles = clampi(int(raw.get("completed_cycles", 0)), 0, MAX_CYCLES)
	data.equipped_outfits = _clean_id_map(raw.get("equipped_outfits", {}))
	data.owned_furniture = _clean_id_array(raw.get("owned_furniture", []))
	data.placed_furniture = _clean_placement(raw.get("placed_furniture", []))
	data.friend_stars = _clean_stars(raw.get("friend_stars", {}))
	return data


func clamp_to_rules() -> void:
	coins = clampi(coins, 0, MAX_COINS)
	tickets = clampi(tickets, 0, MAX_TICKETS)
	completed_cycles = clampi(completed_cycles, 0, MAX_CYCLES)
	equipped_outfits = _clean_id_map(equipped_outfits)
	owned_furniture = _clean_id_array(owned_furniture)
	placed_furniture = _clean_placement(placed_furniture)
	friend_stars = _clean_stars(friend_stars)


static func _clean_id_map(raw: Variant) -> Dictionary:
	var clean: Dictionary = {}
	if not raw is Dictionary:
		return clean
	for key: Variant in (raw as Dictionary).keys():
		var slot: String = str(key)
		var value: Variant = (raw as Dictionary)[key]
		if not value is String:
			continue
		if is_valid_id(slot) and is_valid_id(value):
			clean[slot] = value as String
	return clean


static func _clean_id_array(raw: Variant) -> Array[String]:
	var clean: Array[String] = []
	if not raw is Array:
		return clean
	for item: Variant in raw as Array:
		# Structured data must arrive as a string; a number would stringify into a
		# plausible-looking id and slip past the pattern.
		if not item is String:
			continue
		var value: String = item as String
		if is_valid_id(value) and not clean.has(value):
			clean.append(value)
	return clean


static func _clean_placement(raw: Variant) -> Array[Dictionary]:
	var clean: Array[Dictionary] = []
	if not raw is Array:
		return clean
	for item: Variant in raw as Array:
		if not item is Dictionary:
			continue
		var entry: Dictionary = item as Dictionary
		var raw_id: Variant = entry.get("id", "")
		if not raw_id is String:
			continue
		var id: String = raw_id as String
		if not is_valid_id(id):
			continue
		(
			clean
			. append(
				{
					"id": id,
					"x": clampf(float(entry.get("x", 0.5)), 0.0, 1.0),
					"y": clampf(float(entry.get("y", 0.5)), 0.0, 1.0),
				}
			)
		)
	return clean


static func _clean_stars(raw: Variant) -> Dictionary:
	var clean: Dictionary = {}
	if not raw is Dictionary:
		return clean
	for key: Variant in (raw as Dictionary).keys():
		var friend: String = str(key)
		if is_valid_id(friend):
			clean[friend] = clampi(int((raw as Dictionary)[key]), 0, MAX_STARS)
	return clean
