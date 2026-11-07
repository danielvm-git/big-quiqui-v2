# story: e11s03
extends GutTest
## DevConsole is inert in non-debug exports (FIX-07).


func test_dev_console_autoload_exists() -> void:
	var layer: Node = get_node_or_null("/root/DevConsole")
	assert_not_null(layer)
	if OS.is_debug_build():
		assert_true(layer.call("is_active"))
	else:
		assert_false(layer.call("is_active"))
