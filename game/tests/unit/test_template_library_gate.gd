# story: e16s04
extends GutTest

const SLOTS: Array[String] = [
	"t0_title",
	"t3_skip_beat",
	"t20_drag_snap",
	"t21_touch_each",
	"t22_play_beat",
	"t23_erase",
	"t25_map",
	"t26_ride",
	"t27_memory",
	"t32_reward",
	"t34_rub_reveal",
	"t37_tap_moving",
	"t38_peekaboo",
	"t40_draw_fill",
	"t41_float_pop",
	"t42_slice_cut",
	"t43_color_fill",
	"t44_paint",
	"t45_dress_decorate",
	"t46_cups",
	"t47_drag_release",
	"t48_serve",
	"t49_progress_holder",
	"t50_lanes",
	"t51_prize_pick",
	"t52_groom",
	"t53_outro",
	"t55_find",
]
const SKIPPED: Array[String] = ["t3_skip_beat", "t22_play_beat"]
const RESERVED_NUMBERS: Array[String] = [
	"1", "2", "4", "24", "28", "29", "30", "31", "33", "35", "36", "56", "57", "58"
]
const RETIRED: Array[String] = ["t39", "t54"]


func test_library_has_twenty_eight_ruled_slots() -> void:
	assert_eq(SLOTS.size(), 28, "the frozen library is 28 slots")
	var table: String = _table()
	for template_id: String in SLOTS:
		assert_true(table.contains("| %s |" % template_id), template_id)
		_assert_slot(template_id)


func test_reserved_numbers_have_no_script_or_registry_row() -> void:
	for name: String in _template_files():
		assert_false(RESERVED_NUMBERS.has(_slot_number(name)), name)
	for template_id: String in TemplateCatalog.SCRIPT_FOR_ID.keys():
		assert_false(RESERVED_NUMBERS.has(_slot_number(str(template_id))), template_id)


func test_retired_ad_templates_stay_absent() -> void:
	for id: String in RETIRED:
		assert_false(TemplateCatalog.is_known(id))
		assert_false(ResourceLoader.exists("res://scripts/templates/%s.gd" % id))
		for name: String in _template_files():
			assert_false(_slot_number(name) == id.trim_prefix("t"), name)


func test_t47_drag_release_is_the_t20_fold_not_a_second_script() -> void:
	assert_false(ResourceLoader.exists("res://scripts/templates/t47_drag_release.gd"))
	assert_false(TemplateCatalog.is_known("t47_drag_release"))
	assert_true(ResourceLoader.exists("res://tests/unit/test_t20_drag_release_fold.gd"))


func test_custom_slots_are_outside_the_twenty_eight() -> void:
	assert_false(SLOTS.has("t_rhythm_pose"))
	assert_false(SLOTS.has("t_album"))
	assert_true(TemplateCatalog.is_known("t_rhythm_pose"))
	assert_true(TemplateCatalog.is_known("t_album"))


func _assert_slot(template_id: String) -> void:
	if SKIPPED.has(template_id):
		assert_false(ResourceLoader.exists("res://scripts/templates/%s.gd" % template_id), template_id)
		return
	if template_id == "t47_drag_release":
		assert_true(ResourceLoader.exists("res://tests/unit/test_t20_drag_release_fold.gd"))
		return
	assert_true(TemplateCatalog.is_known(template_id), template_id)
	assert_true(ResourceLoader.exists("res://scripts/templates/%s.gd" % template_id), template_id)
	assert_true(ResourceLoader.exists("res://tests/unit/test_%s.gd" % template_id), template_id)


func _table() -> String:
	var game_dir: String = ProjectSettings.globalize_path("res://")
	return FileAccess.get_file_as_string(game_dir.path_join("../specs/product/TEMPLATE_TABLE.md"))


func _slot_number(name: String) -> String:
	var body: String = name.trim_prefix("t").trim_suffix(".gd")
	var cut: int = body.find("_")
	return body.substr(0, cut) if cut > 0 else ""


func _template_files() -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open("res://scripts/templates")
	if dir == null:
		return found
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while not name.is_empty():
		if name.ends_with(".gd"):
			found.append(name)
		name = dir.get_next()
	return found
