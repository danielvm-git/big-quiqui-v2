# story: e10s01
# story: e14s05
extends GutTest
## SC-E10-P0-01 / P1-07 — the friend rails every minigame stands on: the catalog owns the
## id->art/scene/voice mapping (including the english-named intro lines), stars climb to
## the cap and refuse past it, and the coin table is data with floors.

var pm: Node = null


func before_each() -> void:
	pm = get_node_or_null("/root/ProgressManager")
	assert_not_null(pm, "ProgressManager must be an autoload")
	pm.set_test_mode(true)
	pm.reset()
	TestReset.delete_test_save()


func after_each() -> void:
	pm.reset()
	TestReset.delete_test_save()
	pm.set_test_mode(false)


# SC-E10-P1-07
func test_the_catalog_lists_exactly_the_three_friends() -> void:
	assert_eq(FriendCatalog.FRIEND_IDS, ["pato", "urso", "pinguim"])
	for id: String in FriendCatalog.FRIEND_IDS:
		assert_true(FriendCatalog.is_friend(id), "%s must be a friend" % id)


# SC-E10-P1-07
func test_the_catalog_maps_art_scene_and_voice_for_every_friend() -> void:
	assert_eq(FriendCatalog.art_path("pato"), "res://assets/art/friends/duck.png")
	assert_eq(FriendCatalog.scene_path("pato"), "duck_dance")
	assert_eq(FriendCatalog.scene_path("urso"), "bear_puzzle")
	assert_eq(FriendCatalog.scene_path("pinguim"), "penguin_lanes")
	# The intro lines were recorded with english names; the catalog owns that mismatch.
	assert_eq(FriendCatalog.voice_key("pato"), "vo.duck.intro")
	assert_eq(FriendCatalog.voice_path("pato"), "res://assets/audio/voice/pt_BR/duck_intro.ogg")
	assert_eq(FriendCatalog.voice_key("urso"), "vo.bear.intro")
	assert_eq(FriendCatalog.voice_path("urso"), "res://assets/audio/voice/pt_BR/bear_intro.ogg")
	assert_eq(FriendCatalog.voice_key("pinguim"), "vo.penguin.intro")
	assert_eq(FriendCatalog.voice_path("pinguim"), "res://assets/audio/voice/pt_BR/penguin_intro.ogg")
	for id: String in FriendCatalog.FRIEND_IDS:
		assert_true(ResourceLoader.exists(FriendCatalog.art_path(id)), "art for %s" % id)
		assert_true(ResourceLoader.exists(FriendCatalog.voice_path(id)), "voice for %s" % id)


# SC-E10-P1-07
func test_the_catalog_rejects_non_friend_and_unsafe_ids() -> void:
	var bad_ids: Array[String] = ["", "../../etc/passwd", "Pato", "pato ", "x".repeat(65), "pato/../urso"]
	for bad: String in bad_ids:
		assert_false(FriendCatalog.is_friend(bad), "must refuse %s" % bad)


# SC-E10-P0-01
func test_add_star_climbs_zero_to_five_and_refuses_the_sixth() -> void:
	for expected: int in range(1, 6):
		assert_true(pm.call("add_star", "pato"), "star %d must be granted" % expected)
		assert_eq(int(pm.call("stars_of", "pato")), expected)
	assert_false(pm.call("add_star", "pato"), "the cap refuses the sixth star")
	assert_eq(int(pm.call("stars_of", "pato")), 5, "the refusal mutated nothing")


# SC-E10-P0-01
func test_add_star_refuses_unknown_ids_without_muting_or_writing() -> void:
	var writes_before: int = int(pm.write_count)
	assert_false(pm.call("add_star", "../../etc"))
	assert_false(pm.call("add_star", ""))
	assert_eq(pm.data.friend_stars, {}, "a refused star never reaches the save model")
	assert_eq(int(pm.write_count), writes_before, "a refused star never writes")


# SC-E10-P0-01
func test_stars_survive_a_reload() -> void:
	assert_true(pm.call("add_star", "urso"))
	assert_true(pm.call("add_star", "urso"))
	pm.data = SaveData.new()
	pm.load_or_default()
	assert_eq(int(pm.call("stars_of", "urso")), 2, "stars live on disk, not in RAM")


# SC-E10-P0-01
func test_stars_of_reads_zero_for_unknown_friends() -> void:
	assert_eq(int(pm.call("stars_of", "ninguem")), 0)
	assert_eq(int(pm.call("stars_of", "pato")), 0)


# SC-E10-P0-02 (table half — the payout half lives in the scene tests)
func test_the_minigame_coin_table_pays_every_friend_and_floors_at_zero() -> void:
	var economy: EconomyData = EconomyData.new()
	for id: String in FriendCatalog.FRIEND_IDS:
		assert_gt(FriendCatalog.coins_of(id, economy), 0, "%s must pay coins" % id)
	economy.minigame_coins = {"pato": -9}
	assert_eq(FriendCatalog.coins_of("pato", economy), 0, "a negative payout must not mint debt")
	economy.minigame_coins = {}
	assert_eq(FriendCatalog.coins_of("pato", economy), 0, "a missing payout is not free money")
