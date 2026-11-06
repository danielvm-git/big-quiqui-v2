# story: e03s04
class_name FeedE2eTestCase
extends GutTest
## Shared fixture for the Casa -> Cozinha -> Casa end-to-end journey tests.

const CASA_PATH: String = "res://scenes/casa.tscn"
const COZINHA_PATH: String = "res://scenes/cozinha.tscn"
const FIXED_SEED: int = 20261105
const STEP_SEC: float = 1.0
const SCENE_STEP_SEC: float = 0.1
const SCENE_STEPS: int = 30
const AWAY_FROM_MOUTH: Vector2 = Vector2(150.0, 300.0)
const FOOD_COUNT: int = 3
const SECOND_FINGER: int = 1
const RELEASE_EVENTS: int = -2
const AUDIT_DIR: String = "user://test_e2e_diary"
const AUDIT_FILE: String = "quiqui-e2e.jsonl"
const AUDIT_TOOL: String = "../scripts/logs.sh"
const BAD_DIARY_LINE: String = '{"ts":"bad","session":"bad","lvl":"info","ev":"x","item":"Maria Clara"}'

var clm: Node = null
var sm: Node = null
var am: Node = null
var diary: Node = null

var viewport: SubViewport = null
var stage: Control = null
var requested: Array[String] = []
var refused_requests: Array[String] = []
var loop_probe: FsmProbe = null
var scene_probe: FsmProbe = null
var kitchen_probes: Array[FsmProbe] = []
var diary_start: int = 0


func before_all() -> void:
	clm = get_node("/root/CareLoopManager")
	sm = get_node("/root/SceneManager")
	am = get_node("/root/AudioManager")
	diary = get_node("/root/Log")
	sm.scene_requested.connect(_on_scene_requested)
	sm.transition_rejected.connect(_on_transition_rejected)


func before_each() -> void:
	TestReset.reset_all()
	stage = null
	requested = []
	refused_requests = []
	kitchen_probes = []
	sm.manual_step = true
	sm.loader = _swap
	loop_probe = FsmProbe.new().attach(clm.fsm)
	scene_probe = FsmProbe.new().attach(sm.fsm)
	diary_start = diary.write_count()


func after_each() -> void:
	sm.loader = Callable()
	sm.manual_step = false
	am.reset()
	stage = null


func _on_scene_requested(path: String, _queued: bool) -> void:
	requested.append(path)


func _on_transition_rejected(path: String, _reason: String) -> void:
	refused_requests.append(path)


func _swap(path: String) -> void:
	if stage != null:
		stage.free()
	stage = (load(path) as PackedScene).instantiate() as Control
	stage.set("manual_step", true)
	if stage is KitchenScene:
		(stage as KitchenScene).seed_value = FIXED_SEED
	viewport.add_child(stage)
	if stage is KitchenScene:
		kitchen_probes.append(FsmProbe.new().attach((stage as KitchenScene).fsm))


func _settle() -> void:
	await wait_process_frames(3)
	(stage.get_node("QuiQuiRig") as QuiQuiRig).manual_step = true
	if stage is KitchenScene:
		for index: int in range(FOOD_COUNT):
			_kitchen().food(index).manual_step = true


func _open_casa(size: Vector2i = GeometryOracle.DESKTOP_16_9) -> void:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	_swap(CASA_PATH)
	await _settle()


func _follow_the_request() -> void:
	for step: int in range(SCENE_STEPS):
		sm.advance(SCENE_STEP_SEC)
	await _settle()


func _enter_kitchen() -> void:
	var door: TapButton = (stage as CasaScene).door(CareSteps.FEED)
	_deliver(door, TouchSim.tap_events(door, true))
	await _follow_the_request()


func _kitchen() -> KitchenScene:
	return stage as KitchenScene


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _feed(index: int) -> Array[InputEvent]:
	var food: TouchDraggable = _kitchen().food(index)
	var gesture: Array[InputEvent] = TouchSim.drag_events(food, _kitchen().rig.mouth_global_center())
	_deliver(food, gesture)
	return gesture


func _finish_reactions() -> void:
	_kitchen().advance(STEP_SEC)
	_kitchen().advance(STEP_SEC)


func _feed_all() -> void:
	for index: int in range(FOOD_COUNT):
		_feed(index)
		_finish_reactions()


func _replay(index: int, gesture: Array[InputEvent]) -> void:
	var food: TouchDraggable = _kitchen().food(index)
	_deliver(food, gesture.slice(RELEASE_EVENTS))
	_deliver(food, gesture)


func _as_finger(events: Array[InputEvent], finger: int) -> Array[InputEvent]:
	for event: InputEvent in events:
		if event is InputEventScreenTouch:
			(event as InputEventScreenTouch).index = finger
		elif event is InputEventScreenDrag:
			(event as InputEventScreenDrag).index = finger
	return events


func _assert_probes_clean() -> void:
	assert_true(loop_probe.is_clean(), "care_loop: %s" % loop_probe.summary())
	assert_true(scene_probe.is_clean(), "scene: %s" % scene_probe.summary())
	assert_false(kitchen_probes.is_empty(), "the kitchen machine was watched")
	for probe: FsmProbe in kitchen_probes:
		assert_true(probe.is_clean(), "kitchen_feed: %s" % probe.summary())


func _diary_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	var text: String = FileAccess.get_file_as_string(str(diary.get("log_path")))
	for raw: String in text.strip_edges().split("\n"):
		if int((JSON.parse_string(raw) as Dictionary).get("seq", -1)) >= diary_start:
			lines.append(raw)
	return lines


func _diary_count(ev: String) -> int:
	var count: int = 0
	for raw: String in _diary_lines():
		if str((JSON.parse_string(raw) as Dictionary).get("ev", "")) == ev:
			count += 1
	return count


func _audit_exit_code(lines: PackedStringArray) -> int:
	DirAccess.make_dir_recursive_absolute(AUDIT_DIR)
	var path: String = AUDIT_DIR.path_join(AUDIT_FILE)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	var tool_path: String = ProjectSettings.globalize_path("res://").path_join(AUDIT_TOOL)
	var directory: String = ProjectSettings.globalize_path(AUDIT_DIR)
	var code: int = OS.execute("bash", [tool_path, "--dir", directory, "audit"])
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(AUDIT_DIR)
	return code
