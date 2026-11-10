# story: e11s01
class_name SaveCorpus
extends RefCounted
## INV-01/INV-02 — adversarial save corpus and the invariant checker.
##
## `SaveData.from_dictionary` is the only place an untrusted file becomes game state
## (ADR-005). It must be *total*: any Dictionary in, a legal SaveData out. The corpus
## below is the hostile half of that contract — wrong types, absurd magnitudes,
## duplicate and unowned placements, unknown keys — and `violations()` is the oracle,
## written once so every test asserts the same eight invariants.

const ABSURD: int = 9_999_999_999


## Every hostile dictionary the loader must survive. Plain data, so a failure names
## one entry instead of hiding inside a generator.
static func entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for group: Array[Dictionary] in [_number_cases(), _outfit_cases(), _furniture_cases(), _prize_and_star_cases()]:
		entries.append_array(group)
	return entries


static func _number_cases() -> Array[Dictionary]:
	return [
		{},
		{"coins": -1, "tickets": -1, "completed_cycles": -1},
		{"coins": ABSURD, "tickets": ABSURD, "completed_cycles": ABSURD},
		{"coins": "lots", "tickets": "many", "completed_cycles": "few"},
		{"coins": 1.7, "tickets": 2.9, "completed_cycles": NAN},
		{"coins": null, "tickets": null, "completed_cycles": null},
		{"unknown_key": {"deep": [1, 2, 3]}, "version": -9},
		{"version": "two"},
	]


static func _outfit_cases() -> Array[Dictionary]:
	return [
		{"equipped_outfits": "not a dictionary"},
		{"equipped_outfits": {"body": 3, "head": null, "neck": ["x"], "eyes": "vestido_flor"}},
		{"equipped_outfits": {"../etc/passwd": "mesa", "body": "a/b"}},
		{"equipped_outfits": {"body": "x".repeat(65)}},
	]


static func _furniture_cases() -> Array[Dictionary]:
	return [
		{"owned_furniture": "not an array"},
		{"owned_furniture": [1, 2, true, null, ["mesa"]]},
		{"owned_furniture": ["mesa", "mesa", "MESA", "mesa\n"]},
		{"owned_furniture": ["../../bad", "x".repeat(65), ""]},
		{"placed_furniture": "not an array"},
		{"placed_furniture": [1, "mesa", null, true]},
		{"placed_furniture": [{"id": "mesa"}, {"id": "mesa"}, {"id": "mesa"}]},
		{"placed_furniture": [{"id": 42}, {"id": null}, {"noid": "mesa"}]},
		{"placed_furniture": [{"id": "mesa", "x": -5.0, "y": 8.0}]},
		{"placed_furniture": [{"id": "mesa", "x": NAN, "y": INF}]},
		{"placed_furniture": [{"id": "mesa", "x": "nan", "y": "inf"}]},
	]


static func _prize_and_star_cases() -> Array[Dictionary]:
	return [
		{"picked_prize": 7, "prize_cycle": "two"},
		{"picked_prize": "../x", "prize_cycle": -5},
		{"picked_prize": "x".repeat(70), "prize_cycle": ABSURD},
		{"picked_prize": null, "prize_cycle": NAN},
		{"friend_stars": "not a dictionary"},
		{"friend_stars": {"pato": -3, "urso": 99, "../x": 4}},
		{"friend_stars": {"pato": "muitas"}},
	]


## A placement that names an id the child never bought. The room must not honour it.
static func unowned_placements(owned: Array[String], ids: Array[String]) -> Dictionary:
	var placed: Array[Dictionary] = []
	for id: String in ids:
		if not owned.has(id):
			placed.append({"id": id, "x": 0.5, "y": 0.5})
	return {"owned_furniture": owned, "placed_furniture": placed}


## A seeded random dictionary that stays inside the JSON type system, so it exercises
## the cleaner rather than the JSON parser.
static func random_entry(rng: RandomNumberGenerator) -> Dictionary:
	var entry: Dictionary = {}
	if rng.randi_range(0, 1) == 1:
		entry["coins"] = rng.randi_range(-50, SaveData.MAX_COINS + 50)
	if rng.randi_range(0, 1) == 1:
		entry["tickets"] = rng.randi_range(-50, SaveData.MAX_TICKETS + 50)
	if rng.randi_range(0, 1) == 1:
		entry["completed_cycles"] = rng.randi_range(-5, SaveData.MAX_CYCLES + 5)
	entry["owned_furniture"] = random_ids(rng)
	entry["placed_furniture"] = random_placements(rng, entry["owned_furniture"])
	entry["equipped_outfits"] = random_id_map(rng)
	entry["friend_stars"] = random_stars(rng)
	return entry


static func random_ids(rng: RandomNumberGenerator) -> Array:
	var pool: Array[String] = FurnitureCatalog.FURNITURE_IDS.duplicate()
	pool.append_array(["bad id", "../x", "", "MESA"])
	var out: Array = []
	for _i: int in range(rng.randi_range(0, 6)):
		out.append(pool[rng.randi_range(0, pool.size() - 1)])
	return out


static func random_placements(rng: RandomNumberGenerator, owned: Array) -> Array:
	var out: Array = []
	for _i: int in range(rng.randi_range(0, 5)):
		var id: Variant = owned[rng.randi_range(0, maxi(owned.size() - 1, 0))] if owned.size() > 0 else "mesa"
		out.append({"id": id, "x": rng.randf_range(-2.0, 2.0), "y": rng.randf_range(-2.0, 2.0)})
	return out


static func random_id_map(rng: RandomNumberGenerator) -> Dictionary:
	var out: Dictionary = {}
	var slots: Array[String] = ["body", "head", "neck", "eyes", "bad slot"]
	for _i: int in range(rng.randi_range(0, 4)):
		out[slots[rng.randi_range(0, slots.size() - 1)]] = "vestido_flor" if rng.randi_range(0, 3) > 0 else 7
	return out


static func random_stars(rng: RandomNumberGenerator) -> Dictionary:
	var out: Dictionary = {}
	var friends: Array[String] = ["pato", "urso", "pinguim", "bad friend"]
	for _i: int in range(rng.randi_range(0, 3)):
		out[friends[rng.randi_range(0, friends.size() - 1)]] = rng.randi_range(-2, 9)
	return out


## The eight invariants of INV-01. Empty array == clean.
static func violations(data: SaveData) -> Array[String]:
	var found: Array[String] = []
	found.append_array(_scalar_violations(data))
	found.append_array(_id_violations(data))
	found.append_array(_placement_violations(data))
	found.append_array(_star_violations(data))
	return found


static func _scalar_violations(data: SaveData) -> Array[String]:
	var found: Array[String] = []
	if data.coins < 0 or data.coins > SaveData.MAX_COINS:
		found.append("coins out of range: %d" % data.coins)
	if data.tickets < 0 or data.tickets > SaveData.MAX_TICKETS:
		found.append("tickets out of range: %d" % data.tickets)
	if data.completed_cycles < 0 or data.completed_cycles > SaveData.MAX_CYCLES:
		found.append("cycles out of range: %d" % data.completed_cycles)
	return found


static func _id_violations(data: SaveData) -> Array[String]:
	var found: Array[String] = []
	for slot: Variant in data.equipped_outfits.keys():
		var value: Variant = data.equipped_outfits[slot]
		if not Ids.is_valid(str(slot)):
			found.append("invalid outfit slot survived: %s" % str(slot))
		if not value is String or not Ids.is_valid(str(value)):
			found.append("invalid outfit id survived: %s" % str(value))
	var seen: Dictionary = {}
	for id: String in data.owned_furniture:
		if not Ids.is_valid(id):
			found.append("invalid owned id survived: %s" % id)
		if seen.has(id):
			found.append("duplicate owned id: %s" % id)
		seen[id] = true
	return found


static func _placement_violations(data: SaveData) -> Array[String]:
	var found: Array[String] = []
	var seen: Dictionary = {}
	for entry: Dictionary in data.placed_furniture:
		var id: String = str(entry.get("id", ""))
		if not Ids.is_valid(id):
			found.append("invalid placed id survived: %s" % id)
		if seen.has(id):
			found.append("duplicate placement: %s" % id)
		seen[id] = true
		if not data.owned_furniture.has(id):
			found.append("placed but never owned: %s" % id)
		for axis: String in ["x", "y"]:
			var value: float = float(entry.get(axis, 0.0))
			if is_nan(value) or value < 0.0 or value > 1.0:
				found.append("placement %s out of range on %s: %s" % [id, axis, str(value)])
	return found


static func _star_violations(data: SaveData) -> Array[String]:
	var found: Array[String] = []
	for friend: Variant in data.friend_stars.keys():
		if not Ids.is_valid(str(friend)):
			found.append("invalid friend id survived: %s" % str(friend))
		var stars: int = int(data.friend_stars[friend])
		if stars < 0 or stars > SaveData.MAX_STARS:
			found.append("stars out of range for %s: %d" % [str(friend), stars])
	return found
