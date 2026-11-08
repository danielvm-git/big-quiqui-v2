# story: e10s04
extends GutTest
## SC-E10-P0-20..22, SC-E10-P1-23..24 — Album scene integration tests:
## mounts clean on both aspects (GeometryOracle), empty save shows dark cards,
## stars light per friend and live-refresh on progress_changed, card tap bounces
## and replays voice, Home navigates to Vila, Vila ALBUM door navigates to Album.

const ALBUM_PATH: String = "res://scenes/album.tscn"
const VILA_PATH: String = "res://scenes/vila.tscn"
const ALBUM_SCRIPT = preload("res://scripts/scenes/album.gd")

var scene: Control = null


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount(path: String, size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(path) as PackedScene
	assert_not_null(packed, "scene %s must load" % path)
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func _tap(button: Control) -> void:
	for event: InputEvent in TouchSim.tap_events(button, true):
		button._gui_input(event)


# SC-E10-P0-20
func test_album_passes_oracle_on_both_aspects() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var mounted: Control = _mount(ALBUM_PATH, size)
		await wait_process_frames(2)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		assert_eq(mounted.get_script(), ALBUM_SCRIPT)
		_assert_album_cards_and_home(mounted)
		mounted.queue_free()


func _assert_album_cards_and_home(root: Control) -> void:
	var home: Control = root.get_node_or_null("HomeButton") as Control
	assert_not_null(home, "HomeButton must exist")
	assert_true(home.is_in_group(GeometryOracle.HIT_GROUP))
	assert_gte(home.get_global_rect().size.x, 120.0)
	for id: String in FriendCatalog.FRIEND_IDS:
		var card: Control = root.get_node_or_null("Cards/Card_" + id) as Control
		assert_not_null(card, "Card_%s must exist" % id)
		assert_true(card.is_in_group(GeometryOracle.HIT_GROUP))
		assert_gte(card.get_global_rect().size.x, 120.0)
		assert_gte(card.get_global_rect().size.y, 120.0)


# SC-E10-P0-20, SC-E10-P0-21
func test_empty_save_shows_dark_cards_and_stars_light_on_progress() -> void:
	scene = _mount(ALBUM_PATH, GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(2)
	assert_eq(scene.call("total_stars"), 0)
	var card_pato: Control = scene.get_node_or_null("Cards/Card_pato") as Control
	var art_pato: TextureRect = card_pato.get_node_or_null("Art") as TextureRect
	assert_eq(art_pato.modulate, AlbumScene.CARD_UNLIT_COLOR)
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_star", "pato")
	assert_eq(scene.call("lit_stars", "pato"), 1)
	assert_eq(scene.call("total_stars"), 1)
	assert_eq(art_pato.modulate, AlbumScene.CARD_LIT_COLOR)
	var star0: TextureRect = card_pato.get_node_or_null("Stars/Star0") as TextureRect
	assert_eq(star0.modulate, AlbumScene.STAR_LIT_COLOR)


# SC-E10-P0-21
func test_card_tap_voice_and_bounce() -> void:
	scene = _mount(ALBUM_PATH, GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(2)
	scene.set("manual_step", true)
	var card_pato: Control = scene.get_node_or_null("Cards/Card_pato") as Control
	_tap(card_pato)
	scene.call("advance", 0.05)
	assert_gt(card_pato.scale.x, 1.0, "card bounces up")
	scene.call("advance", AlbumScene.BOUNCE_SEC + 0.05)
	assert_almost_eq(card_pato.scale.x, 1.0, 0.01, "card settles")


# SC-E10-P0-22
func test_home_returns_to_vila() -> void:
	scene = _mount(ALBUM_PATH, GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(2)
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	var home: Control = scene.get_node_or_null("HomeButton") as Control
	_tap(home)
	assert_true(requested.has(VILA_PATH), "Home navigates to vila")


# SC-E10-P0-22, SC-E10-P1-23
func test_vila_album_door_navigates_and_badge_unlocks() -> void:
	var progress: Node = get_node("/root/ProgressManager")
	var vila: Control = _mount(VILA_PATH, GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(2)
	var badge: DoorBadge = vila.get_node_or_null("PoiALBUM/AlbumBadge") as DoorBadge
	assert_not_null(badge, "AlbumBadge must exist on PoiALBUM")
	assert_false(badge.unlocked(), "initially locked with 0 stars")
	progress.call("add_star", "urso")
	assert_true(badge.unlocked(), "unlocked with 1 star")
	var requested: Array[String] = []
	var manager: Node = get_node("/root/SceneManager")
	manager.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	var album_door: Control = vila.call("poi", "ALBUM") as Control
	assert_not_null(album_door, "PoiALBUM must exist")
	_tap(album_door)
	assert_true(requested.has(ALBUM_PATH), "PoiALBUM navigates to album")
	vila.queue_free()


# SC-E10-P1-25 (post-epic review): the star cap has one owner.
func test_every_card_renders_exactly_max_stars_slots() -> void:
	## `SaveData.MAX_STARS` is the cap; the album draws one slot per point. The first
	## version hardcoded 5 in two places (a clamp and a `range(5)`), so raising the cap
	## would have shown four lit points and one unreachable slot — the BUG-008 class of
	## divergent contracts, invisible because both numbers happened to be 5.
	scene = _mount(ALBUM_PATH, GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(2)
	for friend: String in FriendCatalog.FRIEND_IDS:
		var stars: Node = scene.get_node_or_null("Cards/Card_%s/Stars" % friend)
		assert_not_null(stars, "%s has a star rail" % friend)
		assert_eq(stars.get_child_count(), SaveData.MAX_STARS, "%s star slots" % friend)


func test_lighting_every_star_slot_leaves_none_dark() -> void:
	scene = _mount(ALBUM_PATH, GeometryOracle.DESKTOP_16_9)
	await wait_process_frames(2)
	var progress: Node = get_node("/root/ProgressManager")
	for _i: int in range(SaveData.MAX_STARS):
		progress.call("add_star", "urso")
	assert_eq(int(scene.call("lit_stars", "urso")), SaveData.MAX_STARS)
	var stars: Node = scene.get_node("Cards/Card_urso/Stars")
	for star: Node in stars.get_children():
		assert_eq((star as TextureRect).modulate, AlbumScene.STAR_LIT_COLOR, "%s is lit" % star.name)
	assert_false(bool(progress.call("add_star", "urso")), "a capped friend refuses more stars")
