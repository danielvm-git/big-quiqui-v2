# story: e09s02
# story: e10s01
class_name FurnitureLedger
extends RefCounted
## The placement half of the furniture ledger, extracted from `ProgressManager` at
## e10s01 so the save owner stays under the 300-line bar. Pure functions over
## `SaveData`: they validate and mutate the arrays, but never save and never emit —
## the owner decides persistence and telemetry.


## `{}` when the piece was bought, else `{"ev": ..., "data": ...}` for the refusal. Every refusal
## happens before the first mutation, so a refused tap can never take coins without the piece.
static func buy(data: SaveData, id: String, price: int) -> Dictionary:
	if data == null or not Ids.is_valid(id) or price < 0:
		return {"ev": "furniture.invalid", "data": {"item": "invalid"}}
	if data.owned_furniture.has(id):
		return {"ev": "furniture.already_owned", "data": {"item": id}}
	if data.coins < price:
		return {"ev": "furniture.denied", "data": {"item": id, "reason": "coins"}}
	data.coins = clampi(data.coins - price, 0, SaveData.MAX_COINS)
	data.owned_furniture.append(id)
	return {}


static func upsert(data: SaveData, id: String, nx: float, ny: float) -> bool:
	if data == null or not Ids.is_valid(id) or not data.owned_furniture.has(id):
		return false
	var entry: Dictionary = {"id": id, "x": clampf(nx, 0.0, 1.0), "y": clampf(ny, 0.0, 1.0)}
	data.placed_furniture = without(data, id)
	data.placed_furniture.append(entry)
	return true


static func drop(data: SaveData, id: String) -> bool:
	if data == null or not contains(data, id):
		return false
	data.placed_furniture = without(data, id)
	return true


static func copies(data: SaveData) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if data == null:
		return entries
	for entry: Dictionary in data.placed_furniture:
		entries.append(entry.duplicate(true))
	return entries


static func owned_copy(data: SaveData) -> Array[String]:
	var ids: Array[String] = []
	if data != null:
		ids.assign(data.owned_furniture)
	return ids


static func count(data: SaveData) -> int:
	return 0 if data == null else data.placed_furniture.size()


static func contains(data: SaveData, id: String) -> bool:
	if data == null:
		return false
	for entry: Dictionary in data.placed_furniture:
		if str(entry.get("id", "")) == id:
			return true
	return false


static func without(data: SaveData, id: String) -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	if data == null:
		return kept
	for entry: Dictionary in data.placed_furniture:
		if str(entry.get("id", "")) != id:
			kept.append(entry.duplicate(true))
	return kept
