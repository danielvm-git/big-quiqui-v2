# story: e12s02
class_name TemplateCatalog
extends RefCounted
## Closed registry from template id to script — defs name ids only (F-2).

const SCRIPT_FOR_ID: Dictionary = {
	"t_stub": "res://scripts/templates/t_stub.gd",
}


static func is_known(template_id: String) -> bool:
	return SCRIPT_FOR_ID.has(template_id)
