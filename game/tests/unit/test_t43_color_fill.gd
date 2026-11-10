# story: e15s01
extends GutTest

const BANNED: PackedStringArray = [
	"TakePhoto",
	"SaveToFile",
	"LoadPhotos",
	"DisplayPhotos",
	"ShowOrHidePhotoGallery",
	"PhotoGallery",
]


func test_wrong_color_does_not_fill() -> void:
	var tpl: RefCounted = _mount()
	assert_almost_eq(float(tpl.call("progress")), 0.0, 0.001)
	tpl.call("teardown")


func test_gallery_verbs_are_absent() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t43_color_fill.gd")
	for verb: String in BANNED:
		assert_false(body.contains(verb), verb)


func _mount() -> RefCounted:
	var tpl: RefCounted = TemplateCatalog.instantiate("t43_color_fill")
	var step: StepDef = StepDef.new()
	step.template_id = "t43_color_fill"
	step.item_ids = PackedStringArray(["paint_red", "paint_blue"])
	step.slot_ids = PackedStringArray(["area_left", "area_right"])
	step.category_ids = PackedStringArray(["paint_red", "paint_blue"])
	var host: Control = Control.new()
	add_child_autofree(host)
	var tray: Control = Control.new()
	add_child_autofree(tray)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.host = host
	ctx.tray = tray
	ctx.nodes = PlayerNodeTable.new()
	tpl.call("setup", ctx)
	return tpl
