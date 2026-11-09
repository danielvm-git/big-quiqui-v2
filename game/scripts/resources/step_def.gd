# story: e12s02
class_name StepDef
extends Resource
## One step in a data-driven scene: a template id and typed parameters only — never paths or scripts.

@export var template_id: String = ""
@export var param_int: int = 0
@export var item_ids: PackedStringArray = PackedStringArray()
