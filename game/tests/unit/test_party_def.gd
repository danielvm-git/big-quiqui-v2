# story: e14s03
extends GutTest
## SC-e14s03-P1-01 — party uses the D3 skip and catalog friend doors.


func before_each() -> void:
	TestReset.reset_all()


func test_party_def_skips_t22_and_names_arcade_friends() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("party")
	assert_not_null(def)
	for step: Resource in def.steps:
		assert_ne((step as StepDef).template_id, "t22_play_beat", "SC-e14s03-P1-01 D3 skip")
	var friends: StepDef = def.steps[0] as StepDef
	assert_eq(friends.mode, "arcade")
	assert_eq(friends.destination_scenes, PackedStringArray(["duck_dance", "bear_puzzle", "penguin_lanes"]))


func test_locked_party_points_at_playhouse() -> void:
	_place_four()
	var tpl: RefCounted = _mount_party()
	tpl.call("press", "pato")
	assert_eq(str(tpl.call("last_open_id")), "playhouse", "SC-e14s03-P1-01 locked redirect")


func test_unlocked_party_opens_friend_games_by_id() -> void:
	_place_five()
	var tpl: RefCounted = _mount_party()
	tpl.call("press", "urso")
	assert_eq(str(tpl.call("last_open_id")), "bear_puzzle")


func _mount_party() -> RefCounted:
	var def: SceneDef = SceneDefLoader.load_by_id("party")
	var step: StepDef = def.steps[0] as StepDef
	var tray: Control = Control.new()
	tray.size = Vector2(900.0, 160.0)
	add_child_autofree(tray)
	var tpl: RefCounted = TemplateCatalog.instantiate("t21_touch_each")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	return tpl


func _place_four() -> void:
	var pm: Node = get_node("/root/ProgressManager")
	for id: String in ["mesa", "cadeira", "tapete", "abajur"]:
		pm.call("buy_furniture", id, 0)
		pm.call("place_furniture", id, 0.5, 0.5)


func _place_five() -> void:
	_place_four()
	var pm: Node = get_node("/root/ProgressManager")
	pm.call("buy_furniture", "vaso_planta", 0)
	pm.call("place_furniture", "vaso_planta", 0.5, 0.5)
