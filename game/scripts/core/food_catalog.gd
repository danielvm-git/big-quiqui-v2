# story: e03s02
class_name FoodCatalog
extends RefCounted
## The foods the kitchen can serve. Ids come from this const list, so no outside
## text ever reaches a `res://` path.

const FOODS_DIR: String = "res://resources/foods/"
const FOOD_IDS: Array[String] = [
	"cenoura",
	"macarrao_cenoura",
	"molho_cenoura",
	"cenoura_quiqui",
	"maca",
	"banana",
	"morango",
	"melancia",
	"uva",
	"cupcake",
]


static func all() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for id: String in FOOD_IDS:
		var item: ItemData = get_item(id)
		if item != null:
			items.append(item)
	return items


static func get_item(id: String) -> ItemData:
	if not FOOD_IDS.has(id):
		LogSink.emit_to_diary("item.unknown", {"item": "invalid"})
		return null
	var path: String = "%s%s.tres" % [FOODS_DIR, id]
	if not ResourceLoader.exists(path):
		LogSink.emit_to_diary("item.missing_data", {"item": id})
		return null
	return load(path) as ItemData


## A seeded Fisher-Yates: `Array.shuffle` reads the global RNG, not this one.
static func pick_tray(rng: RandomNumberGenerator, count: int) -> Array[ItemData]:
	var pool: Array[ItemData] = all()
	for index: int in range(pool.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var held: ItemData = pool[index]
		pool[index] = pool[other]
		pool[other] = held
	pool.resize(clampi(count, 0, pool.size()))
	return pool
