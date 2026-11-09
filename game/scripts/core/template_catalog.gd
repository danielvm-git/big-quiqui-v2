# story: e12s02
# story: e13s01
# story: e13s02
class_name TemplateCatalog
extends RefCounted
## Closed registry from template id to script — defs name ids only (F-2).

const SCRIPT_FOR_ID: Dictionary = {
	"t_stub": "res://scripts/templates/t_stub.gd",
	"t20_drag_snap": "res://scripts/templates/t20_drag_snap.gd",
	"t34_rub_reveal": "res://scripts/templates/t34_rub_reveal.gd",
	"t21_touch_each": "res://scripts/templates/t21_touch_each.gd",
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
