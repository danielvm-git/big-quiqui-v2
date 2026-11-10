# story: e12s02
# story: e13s01
# story: e13s02
# story: e13s03
# story: e13s04
# story: e13s05
# story: e13s08
# story: e13s09
# story: e14s03
# story: e15s01
# story: e16s01
class_name TemplateCatalog
extends RefCounted
## Closed registry from template id to script — defs name ids only (F-2).

const SCRIPT_FOR_ID: Dictionary = {
	"t_stub": "res://scripts/templates/t_stub.gd",
	"t20_drag_snap": "res://scripts/templates/t20_drag_snap.gd",
	"t34_rub_reveal": "res://scripts/templates/t34_rub_reveal.gd",
	"t21_touch_each": "res://scripts/templates/t21_touch_each.gd",
	"t25_map": "res://scripts/templates/t25_map.gd",
	"t40_draw_fill": "res://scripts/templates/t40_draw_fill.gd",
	"t23_erase": "res://scripts/templates/t23_erase.gd",
	"t45_dress_decorate": "res://scripts/templates/t45_dress_decorate.gd",
	"t0_title": "res://scripts/templates/t0_title.gd",
	"t32_reward": "res://scripts/templates/t32_reward.gd",
	"t50_lanes": "res://scripts/templates/t50_lanes.gd",
	"t51_prize_pick": "res://scripts/templates/t51_prize_pick.gd",
	"t_rhythm_pose": "res://scripts/templates/t_rhythm_pose.gd",
	"t_album": "res://scripts/templates/t_album.gd",
	"t43_color_fill": "res://scripts/templates/t43_color_fill.gd",
	"t44_paint": "res://scripts/templates/t44_paint.gd",
	"t55_find": "res://scripts/templates/t55_find.gd",
	"t27_memory": "res://scripts/templates/t27_memory.gd",
	"t38_peekaboo": "res://scripts/templates/t38_peekaboo.gd",
	"t37_tap_moving": "res://scripts/templates/t37_tap_moving.gd",
	"t26_ride": "res://scripts/templates/t26_ride.gd",
	"t41_float_pop": "res://scripts/templates/t41_float_pop.gd",
	"t42_slice_cut": "res://scripts/templates/t42_slice_cut.gd",
	"t46_cups": "res://scripts/templates/t46_cups.gd",
	"t48_serve": "res://scripts/templates/t48_serve.gd",
	"t52_groom": "res://scripts/templates/t52_groom.gd",
	"t53_outro": "res://scripts/templates/t53_outro.gd",
	"t49_progress_holder": "res://scripts/templates/t49_progress_holder.gd",
}


static func is_known(template_id: String) -> bool:
	return SCRIPT_FOR_ID.has(template_id)


static func script_path(template_id: String) -> String:
	var found: Variant = SCRIPT_FOR_ID.get(template_id, "")
	return str(found)


static func instantiate(template_id: String) -> RefCounted:
	var path: String = script_path(template_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var script: Script = load(path) as Script
	if script == null:
		return null
	return script.new() as RefCounted
