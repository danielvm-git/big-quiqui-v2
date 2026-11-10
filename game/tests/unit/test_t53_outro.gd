# story: e16s03
extends GutTest


func test_outro_uses_scene_nav() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t53_outro.gd")
	assert_true(body.contains("SceneNav.open"))
