# story: e09s01
extends GutTest
## SC-E09-P0-01/02 — the Lote-6 catalog: 12 typed pieces, no path ever built from outside text.

const EXPECTED_IDS: Array[String] = [
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


func test_catalog_lists_the_twelve_lote_six_pieces() -> void:
	var ids: Array[String] = []
	for item: FurnitureData in FurnitureCatalog.all():
		ids.append(item.id)
	assert_eq(ids.size(), EXPECTED_IDS.size(), "twelve pieces shipped with Lote-6")
	for id: String in EXPECTED_IDS:
		assert_has(ids, id)


func test_every_item_loads_a_texture_from_the_lote_six_art() -> void:
	var items: Array[FurnitureData] = FurnitureCatalog.all()
	assert_eq(items.size(), 12, "all() must not silently drop a missing .tres")
	for item: FurnitureData in items:
		assert_not_null(item, "item %s" % item.id)
		assert_eq(item.art_path, "res://assets/art/moveis/%s.png" % item.id)
		assert_not_null(item.texture(), "art for %s must load" % item.id)


func test_every_item_has_a_positive_price_in_the_economy_table() -> void:
	var economy: EconomyData = EconomyData.new()
	for item: FurnitureData in FurnitureCatalog.all():
		assert_gt(FurnitureCatalog.price_of(item.id, economy), 0, item.id)


func test_price_of_floors_an_unpriced_or_negative_piece_at_not_sellable() -> void:
	# BUG-058: both cases used to return 0, which the store charged — a free gift. The
	# sentinel is -1, which `MercadoScene.try_buy` already refuses.
	var economy: EconomyData = EconomyData.new()
	economy.furniture_prices = {"mesa": -4}
	assert_eq(FurnitureCatalog.price_of("mesa", economy), FurnitureCatalog.NOT_SELLABLE)
	economy.furniture_prices = {}
	assert_eq(FurnitureCatalog.price_of("mesa", economy), FurnitureCatalog.NOT_SELLABLE)


func test_unknown_and_unsafe_ids_are_rejected() -> void:
	var bad_ids: Array[String] = ["", "../../etc/passwd", "Mesa", "mesa ", "x".repeat(65), "mesa/../cama"]
	for bad: String in bad_ids:
		assert_null(FurnitureCatalog.get_item(bad), "must refuse %s" % bad)
		assert_null(FurnitureCatalog.get_item(bad, "res://resources/furniture/"), bad)


func test_a_missing_resource_degrades_to_null() -> void:
	assert_null(FurnitureCatalog.get_item("mesa", "res://resources/does_not_exist/"))
