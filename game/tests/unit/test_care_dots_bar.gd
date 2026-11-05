# story: e02s02
extends GutTest
## SC-E02-P1-07..09 — the dots bar mirrors cycle progress: five dots, exactly N
## filled, clamped to the cycle length, never interactive.

const FILLED_PATH: String = "res://assets/art/ui/bolinha_progresso.png"
const EMPTY_PATH: String = "res://assets/art/ui/bolinha_progresso_vazia.png"


func _mounted() -> CareDotsBar:
	var bar: CareDotsBar = CareDotsBar.new()
	bar.size = Vector2(456.0, 72.0)
	add_child_autofree(bar)
	return bar


func _filled_count(bar: CareDotsBar) -> int:
	var filled: int = 0
	for path: String in bar.dot_textures():
		if path == FILLED_PATH:
			filled += 1
	return filled


func test_has_five_dots_all_empty_to_start() -> void:
	var bar: CareDotsBar = _mounted()

	assert_eq(bar.dot_textures().size(), 5)
	assert_eq(bar.completed_steps(), 0)
	assert_eq(_filled_count(bar), 0, "a fresh cycle shows five empty dots")
	assert_eq(bar.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the bar is a status display, not a button")


func test_set_completed_steps_fills_exactly_n_dots_in_order() -> void:
	var bar: CareDotsBar = _mounted()

	bar.set_completed_steps(3)

	assert_eq(bar.completed_steps(), 3)
	var paths: Array[String] = bar.dot_textures()
	for index: int in range(5):
		var expected: String = FILLED_PATH if index < 3 else EMPTY_PATH
		assert_eq(paths[index], expected, "dot %d" % index)


func test_counts_clamp_into_the_cycle_range() -> void:
	var bar: CareDotsBar = _mounted()

	bar.set_completed_steps(-2)
	assert_eq(bar.completed_steps(), 0)

	bar.set_completed_steps(9)
	assert_eq(bar.completed_steps(), 5)
	assert_eq(_filled_count(bar), 5)


func test_every_dot_uses_only_the_two_declared_textures() -> void:
	var bar: CareDotsBar = _mounted()
	bar.set_completed_steps(2)

	for path: String in bar.dot_textures():
		assert_true(path == FILLED_PATH or path == EMPTY_PATH, "no third art state exists")
