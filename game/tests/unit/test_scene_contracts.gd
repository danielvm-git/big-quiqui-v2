# story: e11s01
# story: e12s02
extends GutTest
## INV-07 — every shipped scene honours the house contract, read from the artifact.
##
## BUG-001/002/013 lineage. Each scene test verifies that *its* scene is correct; nothing
## verified the rule over the whole folder, so a scene added without a `Control` root or
## with a lettered label would only be caught by a reviewer who happened to open it (ADR-002).

const ROOT_TYPES: Array[String] = [
	"Control", "Panel", "PanelContainer", "MarginContainer", "HBoxContainer", "VBoxContainer"
]
# TextureRect.StretchMode.STRETCH_KEEP_ASPECT_COVERED and ExpandMode.EXPAND_IGNORE_SIZE.
const COVERED: int = 6
const EXPAND_IGNORE_SIZE: int = 1


func test_is_shipped_accepts_a_legacy_path_and_a_scene_id() -> void:
	assert_true(SceneCatalog.is_shipped("res://scenes/cozinha.tscn"))
	assert_true(SceneCatalog.is_shipped("kitchen"))
	assert_false(SceneCatalog.is_shipped("not_a_room"))


func test_every_scene_has_a_control_root_that_spans_the_canvas() -> void:
	var scenes: Array[String] = SourceScanner.scenes()
	assert_gte(scenes.size(), 13, "the scanner must see every scene, not a subset")
	for path: String in scenes:
		var root: String = _root_block(path)
		assert_ne(root, "", "%s has no root node" % path)
		assert_true(_has_control_type(root), "%s root is not a Control (ADR-002)" % path)
		assert_true(_spans_canvas(root), "%s root does not fill the canvas" % path)


func test_every_background_covers_the_canvas() -> void:
	for path: String in SourceScanner.scenes():
		for block: String in _blocks_of_type(path, "TextureRect"):
			if not block.contains('groups=["background"]'):
				continue
			assert_eq(_int_prop(block, "stretch_mode"), COVERED, "%s background letterboxes" % path)
			assert_eq(_int_prop(block, "expand_mode"), EXPAND_IGNORE_SIZE, "%s background is fixed" % path)
			assert_true(_spans_canvas(block), "%s background does not fill the canvas" % path)


func test_no_label_carries_a_word() -> void:
	## No reading required (CONVENTIONS §3.4): numerals are allowed where the game shows a
	## price or a count (the store's `Price` labels) because a pre-reader never has to parse
	## them — the coin icon and the sold badge carry the meaning. Letters are not.
	var pattern: RegEx = RegEx.new()
	pattern.compile("[A-Za-zÀ-ÿ]")
	var offenders: Array[String] = []
	for path: String in SourceScanner.scenes():
		for text: String in _label_texts(path):
			if pattern.search(text) != null:
				offenders.append("%s: %r" % [path, text])
	assert_eq(offenders, [] as Array[String], "a word on screen is a reading requirement")


func test_every_scene_is_built_by_a_tool_not_by_hand() -> void:
	## "NEVER hand-edit generated files" (AGENTS.md). Every scene must be reproducible
	## from `game/tools/build_*_scene.gd`.
	var builders: Array[String] = []
	for path: String in SourceScanner.tool_scripts():
		if path.get_file().begins_with("build_"):
			var body: String = SourceScanner.text(path)
			for scene: String in SourceScanner.scenes():
				if body.contains(scene.get_file()):
					builders.append(scene.get_file())
	for path: String in SourceScanner.scenes():
		assert_true(
			builders.has(path.get_file()), "%s has no builder in game/tools (hand-edited or orphaned)" % path.get_file()
		)


func test_no_scene_reaches_outside_its_own_bundle() -> void:
	for path: String in SourceScanner.scenes():
		assert_false(SourceScanner.text(path).contains("res://../"), "%s escapes res://" % path)


# ── text helpers over the .tscn format ───────────────────────────────────────


func _root_block(path: String) -> String:
	var body: String = SourceScanner.text(path)
	var start: int = body.find("[node name=")
	if start < 0:
		return ""
	var end: int = body.find("\n\n[node", start)
	if end < 0:
		end = body.length()
	return body.substr(start, end - start)


func _blocks_of_type(path: String, type_name: String) -> Array[String]:
	var marker: String = 'type="%s"' % type_name
	var body: String = SourceScanner.text(path)
	var blocks: Array[String] = []
	var at: int = body.find(marker)
	while at >= 0:
		var start: int = body.rfind("[node", at)
		var end: int = body.find("\n\n[node", at)
		if end < 0:
			end = body.length()
		blocks.append(body.substr(start, end - start))
		at = body.find(marker, end)
	return blocks


func _label_texts(path: String) -> Array[String]:
	var texts: Array[String] = []
	for block: String in _blocks_of_type(path, "Label"):
		var pattern: RegEx = RegEx.new()
		pattern.compile('text = "([^"]*)"')
		var found: RegExMatch = pattern.search(block)
		if found != null and not found.get_string(1).is_empty():
			texts.append(found.get_string(1))
	return texts


func _has_control_type(block: String) -> bool:
	for type_name: String in ROOT_TYPES:
		if block.contains('type="%s"' % type_name):
			return true
	return false


func _spans_canvas(block: String) -> bool:
	if _int_prop(block, "anchors_preset") == 15:
		return true
	return (
		block.contains("anchor_right = 1.0")
		and block.contains("anchor_bottom = 1.0")
		and block.contains("anchor_left = 0.0") == false
	)


func _int_prop(block: String, key: String) -> int:
	var pattern: RegEx = RegEx.new()
	pattern.compile("%s = (-?[0-9]+)" % key)
	var found: RegExMatch = pattern.search(block)
	return 0 if found == null else int(found.get_string(1))
