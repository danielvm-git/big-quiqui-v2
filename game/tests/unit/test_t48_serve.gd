# story: e16s02
extends GutTest


func test_serve_wraps_give_primitive() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t48_serve.gd")
	assert_true(body.contains("GiveReceivePrimitive"))
