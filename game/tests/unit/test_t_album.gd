# story: e14s03
extends GutTest
## SC-e14s03-P0-05 — stars only, no image write.


func before_each() -> void:
	TestReset.reset_all()


func test_album_is_registry_backed_and_writes_no_image() -> void:
	assert_true(TemplateCatalog.is_known("t_album"), "SC-e14s03-P1-02")
	var body: String = SourceScanner.text("res://scripts/templates/t_album.gd")
	assert_false(body.to_lower().contains("savetofile"))
	assert_false(body.to_lower().contains("photo_gallery"))


func test_taps_reveal_saved_stars() -> void:
	var progress: Node = get_node("/root/ProgressManager")
	progress.call("add_star", "pato")
	var tpl: RefCounted = _mount()
	tpl.call("press", "pato")
	assert_gte(int(tpl.call("stars_for", "pato")), 1)
	assert_almost_eq(float(tpl.call("progress")), 1.0 / 3.0, 0.01)


func _mount() -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t_album"
	step.item_ids = FriendCatalog.FRIEND_IDS
	var tray: Control = Control.new()
	tray.size = Vector2(900.0, 160.0)
	add_child_autofree(tray)
	var tpl: RefCounted = TemplateCatalog.instantiate("t_album")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	return tpl
