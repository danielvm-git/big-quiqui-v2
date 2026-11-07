# story: e09s01
class_name FurnitureCatalog
extends RefCounted
## The twelve Lote-6 furniture pieces. Ids come from this const list, so no outside
## text ever reaches a `res://` path (CONVENTIONS §4).

const FURNITURE_DIR: String = "res://resources/furniture/"
## `MercadoScene.try_buy` refuses a negative price, so this is the "not for sale" sentinel.
const NOT_SELLABLE: int = -1
const FURNITURE_IDS: Array[String] = [
	"abajur",
	"armario",
	"beliche",
	"cadeira",
	"cama",
	"escada",
	"estante",
	"mesa",
	"porta",
	"sofa",
	"tapete",
	"vaso_planta",
]


static func all() -> Array[FurnitureData]:
	var items: Array[FurnitureData] = []
	for id: String in FURNITURE_IDS:
		var item: FurnitureData = get_item(id)
		if item != null:
			items.append(item)
	return items


static func get_item(id: String, dir: String = FURNITURE_DIR) -> FurnitureData:
	if not FURNITURE_IDS.has(id):
		LogSink.emit_to_diary("item.unknown", {"item": "invalid"})
		return null
	var path: String = "%s%s.tres" % [dir, id]
	if not ResourceLoader.exists(path):
		LogSink.emit_to_diary("item.missing_data", {"item": id})
		return null
	return load(path) as FurnitureData


## FIX-05: the price table is tuning data, so it lives in `EconomyData`. A missing or
## negative entry is **not sellable** (`-1`), never `0`: a zero price is a free gift, and
## `MercadoScene` already treats a negative price as "do not charge" (BUG-058).
static func price_of(id: String, economy: EconomyData) -> int:
	if economy == null or not economy.furniture_prices.has(id):
		return NOT_SELLABLE
	return maxi(int(economy.furniture_prices[id]), NOT_SELLABLE)
