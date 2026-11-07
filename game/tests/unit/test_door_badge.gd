# story: e09s03
extends GutTest
## SC-E09-P1-06 — the Vila's party badge reads the same threshold the party does.

const LOCKED_ART: String = "res://assets/art/ui/bolinha_progresso_vazia.png"
const UNLOCKED_ART: String = "res://assets/art/ui/estrela.png"

var badge: DoorBadge = null
var pm: Node = null


func before_each() -> void:
	TestReset.reset_all()
	pm = get_node("/root/ProgressManager")
	badge = DoorBadge.new()
	badge.required_placed = 5
	badge.locked_art = LOCKED_ART
	badge.unlocked_art = UNLOCKED_ART
	badge.size = Vector2(48.0, 48.0)
	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	badge.add_child(art)
	add_child_autofree(badge)


func after_each() -> void:
	TestReset.delete_test_save()


func _place_pieces(count: int) -> void:
	pm.add_coins(1000)
	var owned: int = 0
	for id: String in FurnitureCatalog.FURNITURE_IDS:
		if owned >= count:
			return
		if not bool(pm.call("buy_furniture", id, 1)):
			continue
		assert_true(bool(pm.call("place_furniture", id, 0.5, 0.5)), id)
		owned += 1


func test_a_fresh_village_shows_the_locked_badge() -> void:
	assert_false(badge.unlocked())
	assert_eq(badge.current_art_path(), LOCKED_ART)
	var art: TextureRect = badge.get_node("Art") as TextureRect
	assert_not_null(art.texture)
	assert_eq(str(art.get_meta("door_badge_path")), LOCKED_ART)


func test_the_badge_swaps_once_five_pieces_are_placed() -> void:
	_place_pieces(4)
	await wait_process_frames(1)
	assert_false(badge.unlocked(), "four is not five")

	_place_pieces(5)
	await wait_process_frames(1)

	assert_true(badge.unlocked(), "the fifth piece unlocks it")
	assert_eq(badge.current_art_path(), UNLOCKED_ART, "and the badge follows progress_changed")
	var art: TextureRect = badge.get_node("Art") as TextureRect
	assert_eq(str(art.get_meta("door_badge_path")), UNLOCKED_ART)


func test_the_badge_re_locks_when_the_room_empties() -> void:
	_place_pieces(5)
	await wait_process_frames(1)
	assert_true(badge.unlocked())

	for id: String in FurnitureCatalog.FURNITURE_IDS:
		pm.call("remove_furniture", id)
	await wait_process_frames(1)

	assert_false(badge.unlocked())
	assert_eq(badge.current_art_path(), LOCKED_ART)
	var art: TextureRect = badge.get_node("Art") as TextureRect
	assert_eq(str(art.get_meta("door_badge_path")), LOCKED_ART)
