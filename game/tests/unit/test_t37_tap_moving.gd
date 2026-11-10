# story: e16s01
extends GutTest


func test_source_has_no_life_or_shake() -> void:
	var body: String = SourceScanner.text("res://scripts/templates/t37_tap_moving.gd").to_lower()
	assert_false(body.contains("decreaselife"))
	assert_false(body.contains("shakescreen"))
