# story: e12s02
extends GutTest
## SC-e12s02-P0-01..04, P0-08 — SceneDef validation and the no-code data contract.

const REJECT_EV: String = "scene.def_rejected"


func before_each() -> void:
	TestReset.reset_all()


func test_a_valid_def_loads_and_exposes_typed_steps() -> void:
	var def: SceneDef = SceneDefLoader.validate(SceneDefFactory.valid())
	assert_not_null(def, "a well-formed def passes validation")
	assert_eq(def.steps.size(), 1)
	var step: StepDef = def.steps[0] as StepDef
	assert_eq(step.template_id, "t_stub")
	assert_eq(step.param_int, 1)


func test_an_unknown_template_id_is_rejected_with_a_reason() -> void:
	var def: SceneDef = SceneDefLoader.validate(SceneDefFactory.broken("unknown_template"))
	assert_null(def, "unknown template must not pass")
	var line: Dictionary = _last_event(REJECT_EV)
	assert_eq(line.get("ev", ""), REJECT_EV)
	assert_eq(str(line.get("reason", "")), "unknown_template")


func test_an_invalid_scene_id_is_rejected_before_any_path_is_built() -> void:
	assert_eq(SceneDefLoader.def_tres_path("../kitchen"), "")
	assert_eq(SceneDefLoader.def_tres_path(""), "")
	var loaded: SceneDef = SceneDefLoader.load_by_id("../kitchen")
	assert_null(loaded)
	var line: Dictionary = _last_event(REJECT_EV)
	assert_eq(line.get("ev", ""), REJECT_EV)
	assert_eq(str(line.get("reason", "")), "invalid_id")


func test_a_missing_background_is_rejected() -> void:
	var def: SceneDef = SceneDefLoader.validate(SceneDefFactory.broken("missing_background"))
	assert_null(def)
	var line: Dictionary = _last_event(REJECT_EV)
	assert_eq(str(line.get("reason", "")), "missing_background")


func test_an_empty_step_list_is_rejected() -> void:
	var def: SceneDef = SceneDefLoader.validate(SceneDefFactory.broken("empty_steps"))
	assert_null(def)
	var line: Dictionary = _last_event(REJECT_EV)
	assert_eq(str(line.get("reason", "")), "empty_steps")


func test_neither_def_nor_step_carries_a_path_or_script_field() -> void:
	var forbidden: Array[String] = []
	var scene_sample: SceneDef = SceneDef.new()
	for property: Dictionary in scene_sample.get_property_list():
		var name: String = str(property.get("name", ""))
		if name in ["script", "resource_path", "resource_name"]:
			continue
		if name.contains("path") or name.ends_with("_script"):
			forbidden.append("SceneDef.%s" % name)
	var step_sample: StepDef = StepDef.new()
	for property: Dictionary in step_sample.get_property_list():
		var name: String = str(property.get("name", ""))
		if name in ["script", "resource_path", "resource_name"]:
			continue
		if name.contains("path") or name.ends_with("_script"):
			forbidden.append("StepDef.%s" % name)
	assert_eq(forbidden, [] as Array[String], "defs must not carry path-shaped fields (F-2)")


func test_the_template_registry_is_a_closed_const_map() -> void:
	assert_true(TemplateCatalog.is_known("t_stub"))
	assert_false(TemplateCatalog.is_known("t99_missing"))
	assert_true(TemplateCatalog.SCRIPT_FOR_ID.is_empty() == false)


func test_dev_smoke_tres_loads_from_disk() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("dev_smoke")
	assert_not_null(def, "integration def must exist on disk")
	assert_eq(def.id, "dev_smoke")


func _last_event(ev_name: String) -> Dictionary:
	var log_node: Node = get_node_or_null("/root/Log")
	if log_node == null:
		return {}
	var file: FileAccess = FileAccess.open(str(log_node.get("log_path")), FileAccess.READ)
	if file == null:
		return {}
	var found: Dictionary = {}
	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary and str((parsed as Dictionary).get("ev", "")) == ev_name:
			found = parsed as Dictionary
	file.close()
	return found
