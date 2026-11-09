# story: e13s09
class_name TemplateTableGate
extends RefCounted
## The wave-1 coverage gate. It reads the template table, adds up the built rows and compares the
## sum with the share the scope states. It returns problems as text, so a test can also prove that
## a bad table fails. Nothing here is a constant that always agrees with itself.

const ID: int = 0
const STATUS: int = 1
const SCENE: int = 4
const TEST: int = 5
const SCENES: int = 6
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
	var built_ids: Array[String] = []
	var built_sum: int = 0
	for cells: PackedStringArray in table_rows:
		if cells.size() <= SCENES or not cells[SCENES].is_valid_int():
			bad.append("row has no scene count: %s" % (cells[ID] if not cells.is_empty() else "?"))
			continue
		if cells[STATUS] != "built":
			if catalog_ids.has(cells[ID]):
				bad.append("%s is %s but is in the catalog" % [cells[ID], cells[STATUS]])
			continue
		built_ids.append(cells[ID])
		built_sum += cells[SCENES].to_int()
		bad.append_array(_consumer_problems(cells))
	for id: String in catalog_ids:
		if id != "t_stub" and not built_ids.has(id):
			bad.append("%s is in the catalog and has no built row" % id)
	for id: String in built_ids:
		if not catalog_ids.has(id):
			bad.append("%s has a built row and is not in the catalog" % id)
	bad.append_array(_scope_problems(scope, built_ids.size(), built_sum))
	return bad


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
