# story: e16s04
extends GutTest

const BUILT: Array[String] = [
	"t0_title",
	"t20_drag_snap",
	"t21_touch_each",
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
	"t48_serve",
	"t49_progress_holder",
	"t50_lanes",
	"t51_prize_pick",
	"t52_groom",
	"t53_outro",
	"t55_find",
]
const RESERVED_NUMBERS: Array[String] = [
	"1", "2", "4", "24", "28", "29", "30", "31", "33", "35", "36", "56", "57", "58"
]
const RETIRED: Array[String] = ["t39", "t54"]


func test_every_built_slot_has_script_and_catalog_entry() -> void:
	for template_id: String in BUILT:
		assert_true(TemplateCatalog.is_known(template_id), template_id)
		assert_true(ResourceLoader.exists("res://scripts/templates/%s.gd" % template_id), template_id)


func test_reserved_numbers_stay_unbuilt() -> void:
	for number: String in RESERVED_NUMBERS:
		var id: String = "t%s_fake" % number
		assert_false(TemplateCatalog.is_known(id))


func test_retired_ad_templates_stay_absent() -> void:
	for id: String in RETIRED:
		assert_false(TemplateCatalog.is_known(id))
		assert_false(ResourceLoader.exists("res://scripts/templates/%s.gd" % id))


func test_t47_drag_release_is_the_t20_fold_not_a_second_script() -> void:
	assert_false(ResourceLoader.exists("res://scripts/templates/t47_drag_release.gd"))
	assert_false(TemplateCatalog.is_known("t47_drag_release"))
	assert_true(ResourceLoader.exists("res://tests/unit/test_t20_drag_release_fold.gd"))
