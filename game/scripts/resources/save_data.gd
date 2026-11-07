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

## The slots an outfit choice can fill. Kept here because the save is what has to stay
## compatible; the rig mirrors them as its layer names.
const SLOT_BODY: String = "body"
const SLOT_HEAD: String = "head"
const SLOT_NECK: String = "neck"
const SLOT_EYES: String = "eyes"
const SLOTS: Array[String] = [SLOT_BODY, SLOT_HEAD, SLOT_NECK, SLOT_EYES]

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
##
## **Total by contract:** any Dictionary in, a legal `SaveData` out. The JSON parser hands us
## `Variant`s and GDScript's `int(null)` is a runtime error, not a zero, so every scalar goes
## through `_int_of` (BUG-055).
static func from_dictionary(raw: Dictionary) -> SaveData:
	var data: SaveData = SaveData.new()
	data.version = maxi(_int_of(raw.get("version", 1), 1), 1)
	data.coins = clampi(_int_of(raw.get("coins", 0), 0), 0, MAX_COINS)
	data.tickets = clampi(_int_of(raw.get("tickets", 0), 0), 0, MAX_TICKETS)
	data.completed_cycles = clampi(_int_of(raw.get("completed_cycles", 0), 0), 0, MAX_CYCLES)
	data.equipped_outfits = _clean_id_map(raw.get("equipped_outfits", {}))
	data.owned_furniture = _clean_id_array(raw.get("owned_furniture", []))
	data.placed_furniture = _clean_placement(raw.get("placed_furniture", []), data.owned_furniture)
	data.friend_stars = _clean_stars(raw.get("friend_stars", {}))
	return data


func clamp_to_rules() -> void:
	coins = clampi(coins, 0, MAX_COINS)
	tickets = clampi(tickets, 0, MAX_TICKETS)
	completed_cycles = clampi(completed_cycles, 0, MAX_CYCLES)
	equipped_outfits = _clean_id_map(equipped_outfits)
	owned_furniture = _clean_id_array(owned_furniture)
	# Ownership first: a placement can only be judged once we know what she owns (BUG-056).
	placed_furniture = _clean_placement(placed_furniture, owned_furniture)
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


static func _clean_placement(raw: Variant, owned: Array[String] = []) -> Array[Dictionary]:
	var clean: Array[Dictionary] = []
	if not raw is Array:
		return clean
	var seen: Dictionary = {}
	for item: Variant in raw as Array:
		if not item is Dictionary:
			continue
		var entry: Dictionary = item as Dictionary
		var raw_id: Variant = entry.get("id", "")
		if not raw_id is String or not is_valid_id(raw_id as String):
			continue
		var id_str: String = raw_id as String
		# A placement she never bought cannot stand in the room (BUG-056), and a duplicate
		# id would let an edited file count one piece five times (BUG-048).
		if seen.has(id_str) or not owned.has(id_str):
			continue
		seen[id_str] = true
		var px: float = _ratio_of(entry.get("x", 0.5))
		var py: float = _ratio_of(entry.get("y", 0.5))
		clean.append({"id": id_str, "x": px, "y": py})
	return clean


## A ratio must be finite before it can be clamped: `clampf(NAN, 0, 1)` is NAN, because every
## comparison against NaN is false, and a NaN reaches a `Control.position` unchanged (BUG-057).
static func _ratio_of(value: Variant) -> float:
	var number: float = _float_of(value, 0.5)
	if not is_finite(number):
		return 0.5
	return clampf(number, 0.0, 1.0)


## JSON scalars only: an int, a finite float, a numeric string or a bool. Anything else —
## `null`, an array, a dictionary — is the declared default, never a runtime error.
static func _int_of(value: Variant, fallback: int) -> int:
	if value is int:
		return value as int
	if value is bool:
		return 1 if bool(value) else 0
	if value is float:
		var number: float = value as float
		return int(number) if is_finite(number) else fallback
	if value is String:
		return (value as String).strip_edges().to_int()
	return fallback


static func _float_of(value: Variant, fallback: float) -> float:
	if value is float:
		var number: float = value as float
		return number if is_finite(number) else fallback
	if value is int:
		return float(value as int)
	if value is bool:
		return 1.0 if bool(value) else 0.0
	if value is String:
		return (value as String).strip_edges().to_float()
	return fallback


static func _clean_stars(raw: Variant) -> Dictionary:
	var clean: Dictionary = {}
	if not raw is Dictionary:
		return clean
	for key: Variant in (raw as Dictionary).keys():
		var friend: String = str(key)
		if is_valid_id(friend):
			clean[friend] = clampi(_int_of((raw as Dictionary)[key], 0), 0, MAX_STARS)
	return clean
