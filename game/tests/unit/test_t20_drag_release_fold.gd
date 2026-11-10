# story: e16s03
extends GutTest


func test_t47_has_no_template_script() -> void:
	assert_false(ResourceLoader.exists("res://scripts/templates/t47_drag_release.gd"))
	assert_false(TemplateCatalog.is_known("t47_drag_release"))


func test_touch_draggable_line_count_stays_grandfathered() -> void:
	var path: String = "res://scripts/components/touch_draggable.gd"
	var body: String = SourceScanner.text(path)
	var lines: int = body.split("\n").size()
	assert_lte(lines, 326)
