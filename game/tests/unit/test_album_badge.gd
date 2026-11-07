# story: e10s04
extends GutTest
## SC-E10-P0-20, SC-E10-P0-21, SC-E10-P1-23 — DoorBadge rules & AlbumScene unit tests:
## stars rule vs placed rule, clamping, empty save, and live refresh.

const LOCK_ART: String = "res://assets/art/ui/cadeado.png"
const STAR_ART: String = "res://assets/art/ui/estrela.png"


func before_each() -> void:
	TestReset.reset_all()


func after_each() -> void:
	TestReset.delete_test_save()


# SC-E10-P1-23
func test_door_badge_placed_rule_defaults_and_behaves_as_before() -> void:
	var badge: DoorBadge = DoorBadge.new()
	badge.rule = "placed"
	badge.required_placed = 5
	badge.locked_art = LOCK_ART
	badge.unlocked_art = STAR_ART
	add_child_autofree(badge)

	var progress: Node = get_node("/root/ProgressManager")
	assert_false(badge.unlocked(), "initially locked with 0 placed")
	assert_eq(badge.current_art_path(), LOCK_ART)

	# Place 5 pieces
	var save: SaveData = progress.get("data") as SaveData
	for i: int in range(5):
		save.placed_furniture.append({"id": "abajur_estrela", "x": 0.5, "y": 0.5})
	badge.refresh()

	assert_true(badge.unlocked(), "unlocked once 5 pieces placed")
	assert_eq(badge.current_art_path(), STAR_ART)


# SC-E10-P1-23
func test_door_badge_stars_rule_unlocks_at_required_stars() -> void:
	var badge: DoorBadge = DoorBadge.new()
	badge.rule = "stars"
	badge.required_stars = 1
	badge.locked_art = LOCK_ART
	badge.unlocked_art = STAR_ART
	add_child_autofree(badge)

	var progress: Node = get_node("/root/ProgressManager")
	assert_false(badge.unlocked(), "locked with 0 total stars")
	assert_eq(badge.current_art_path(), LOCK_ART)

	# Add 1 star to pato
	progress.call("add_star", "pato")
	badge.refresh()

	assert_true(badge.unlocked(), "unlocked with 1 star")
	assert_eq(badge.current_art_path(), STAR_ART)


# SC-E10-P0-20 + P0-21
func test_album_total_stars_and_lit_stars_clamp_reads() -> void:
	var progress: Node = get_node("/root/ProgressManager")
	assert_eq(int(progress.call("stars_of", "pato")), 0, "fresh save has 0 stars")

	var scene: AlbumScene = AlbumScene.new()
	add_child_autofree(scene)
	assert_eq(scene.total_stars(), 0, "empty save has 0 total stars")
	assert_eq(scene.lit_stars("pato"), 0)
	assert_eq(scene.lit_stars("urso"), 0)
	assert_eq(scene.lit_stars("pinguim"), 0)

	# Add stars
	progress.call("add_star", "urso")
	progress.call("add_star", "urso")
	progress.call("add_star", "pinguim")
	assert_eq(scene.total_stars(), 3)
	assert_eq(scene.lit_stars("urso"), 2)
	assert_eq(scene.lit_stars("pinguim"), 1)
	assert_eq(scene.lit_stars("pato"), 0)

	# Tampered save clamping
	var save: SaveData = progress.get("data") as SaveData
	save.friend_stars["urso"] = 99
	save.friend_stars["pato"] = -10
	assert_eq(scene.lit_stars("urso"), 5, "clamped max 5")
	assert_eq(scene.lit_stars("pato"), 0, "clamped min 0")
