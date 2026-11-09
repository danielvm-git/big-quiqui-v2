# story: e13s09
class_name TemplateTableGate
extends RefCounted
## The wave-1 coverage gate. It reads the template table, adds up the built rows and compares the
## sum with the share the scope states. It returns problems as text, so a test can also prove that
## a bad table fails. Nothing here is a constant that always agrees with itself.

const ID: int = 0
const STATUS: int = 1
const RULE: int = 2
const PARAMETERS: int = 3
const SCENE: int = 4
const TEST: int = 5
const SCENES: int = 6
const EVIDENCE: int = 7
const COLUMNS: Array[String] = ["id", "status", "rule", "parameters", "scene", "test", "scenes", "evidence"]
const STATUSES: Array[String] = ["built", "skip"]
const TOTAL_PATTERN: String = "scenes_using_a_template:\\s*(\\d+)"
const SCOPE_HEAD: String = "wave_1_e12_e13:\\s*\\{templates:\\s*(\\d+),\\s*scenes:\\s*(\\d+),"
const SCOPE_TAIL: String = '\\s*share:\\s*"([\\d.]+)%"'


static func rows(table: String) -> Array[PackedStringArray]:
	var found: Array[PackedStringArray] = []
	for line: String in table.split("\n"):
		if not line.begins_with("| t"):
			continue
		var cells: PackedStringArray = PackedStringArray()
		for cell: String in line.strip_edges().trim_prefix("|").trim_suffix("|").split("|"):
			cells.append(cell.strip_edges())
		found.append(cells)
	return found


## Every problem found, or an empty list when the table, the catalog and the scope agree.
static func problems(table: String, scope: String, catalog_ids: Array) -> PackedStringArray:
	var bad: PackedStringArray = PackedStringArray()
	var table_rows: Array[PackedStringArray] = rows(table)
	var built: Array[PackedStringArray] = []
	bad.append_array(_duplicates(table_rows))
	for cells: PackedStringArray in table_rows:
		var shape: PackedStringArray = _shape_problems(cells)
		bad.append_array(shape)
		if not shape.is_empty():
			continue
		bad.append_array(_status_problems(cells, catalog_ids))
		if cells[STATUS] == "built":
			built.append(cells)
	bad.append_array(_catalog_problems(built, catalog_ids))
	bad.append_array(_scope_problems(scope, built.size(), _scene_sum(built)))
	return bad


## A row needs every column: no blank rule, parameters, scene, test or evidence, and a known status.
static func _shape_problems(cells: PackedStringArray) -> PackedStringArray:
	var bad: PackedStringArray = PackedStringArray()
	if cells.size() != COLUMNS.size():
		bad.append("row %s has %d cells, the table has %d" % [_name(cells), cells.size(), COLUMNS.size()])
		return bad
	for index: int in range(cells.size()):
		if cells[index].is_empty():
			bad.append("%s has an empty %s cell" % [cells[ID], COLUMNS[index]])
	if not STATUSES.has(cells[STATUS]):
		bad.append("%s has the unknown status %s" % [cells[ID], cells[STATUS]])
	if not cells[SCENES].is_valid_int():
		bad.append("%s has no scene count" % cells[ID])
	return bad


static func _duplicates(table_rows: Array[PackedStringArray]) -> PackedStringArray:
	var bad: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	for cells: PackedStringArray in table_rows:
		var id: String = _name(cells)
		if seen.has(id):
			bad.append("%s has two rows" % id)
		seen[id] = true
	return bad


static func _status_problems(cells: PackedStringArray, catalog_ids: Array) -> PackedStringArray:
	var bad: PackedStringArray = PackedStringArray()
	if cells[STATUS] == "built":
		return _consumer_problems(cells)
	if catalog_ids.has(cells[ID]):
		bad.append("%s is %s but is in the catalog" % [cells[ID], cells[STATUS]])
	return bad


static func _catalog_problems(built: Array[PackedStringArray], catalog_ids: Array) -> PackedStringArray:
	var bad: PackedStringArray = PackedStringArray()
	var built_ids: Array[String] = []
	for cells: PackedStringArray in built:
		built_ids.append(cells[ID])
		if not catalog_ids.has(cells[ID]):
			bad.append("%s has a built row and is not in the catalog" % cells[ID])
	for id: String in catalog_ids:
		if id != "t_stub" and not built_ids.has(id):
			bad.append("%s is in the catalog and has no built row" % id)
	return bad


static func _scene_sum(built: Array[PackedStringArray]) -> int:
	var sum: int = 0
	for cells: PackedStringArray in built:
		sum += cells[SCENES].to_int()
	return sum


static func _name(cells: PackedStringArray) -> String:
	return "?" if cells.is_empty() else cells[ID]


static func _scope_problems(scope: String, built: int, built_sum: int) -> PackedStringArray:
	var bad: PackedStringArray = PackedStringArray()
	var total: RegExMatch = RegEx.create_from_string(TOTAL_PATTERN).search(scope)
	var claim: RegExMatch = RegEx.create_from_string(SCOPE_HEAD + SCOPE_TAIL).search(scope)
	if total == null or claim == null:
		bad.append("the scope has no total or no wave_1_e12_e13 claim")
		return bad
	var share: String = "%.1f" % (100.0 * float(built_sum) / float(total.get_string(1).to_int()))
	if claim.get_string(1).to_int() != built:
		bad.append("scope claims %s templates, table has %d built" % [claim.get_string(1), built])
	if claim.get_string(2).to_int() != built_sum:
		bad.append("scope claims %s scenes, table adds up to %d" % [claim.get_string(2), built_sum])
	if claim.get_string(3) != share:
		bad.append("scope claims %s%%, table gives %s%%" % [claim.get_string(3), share])
	return bad


static func _consumer_problems(cells: PackedStringArray) -> PackedStringArray:
	var bad: PackedStringArray = PackedStringArray()
	var id: String = cells[ID]
	if not ResourceLoader.exists("res://scripts/templates/%s.gd" % id):
		bad.append("%s has no script" % id)
	if not ResourceLoader.exists("res://tests/unit/%s.gd" % cells[TEST]):
		bad.append("%s has no test %s" % [id, cells[TEST]])
	var def: SceneDef = SceneDefLoader.load_by_id(cells[SCENE])
	if def == null:
		bad.append("%s names scene %s, which does not load" % [id, cells[SCENE]])
		return bad
	var uses: bool = false
	for step: Resource in def.steps:
		uses = uses or (step as StepDef).template_id == id
	if not uses:
		bad.append("%s names scene %s, which has no %s step" % [id, cells[SCENE], id])
	return bad
