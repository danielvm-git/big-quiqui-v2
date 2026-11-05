# story: e03s04
extends GutTest
## SC-E03-P0-22..P1-26: the whole FEED journey from the Casa door and back, with the
## real autoloads. Every gesture is a TouchSim list with its mouse echo, delivered to
## `_gui_input`. SceneManager's loader swaps the scenes, so the test follows the same
## requests the game does. Real GUI dispatch is out of reach headless (see test_touch_sim).

const CASA_PATH: String = "res://scenes/casa.tscn"
const COZINHA_PATH: String = "res://scenes/cozinha.tscn"
const FIXED_SEED: int = 20261105
## Longer than either reaction, so one `advance` always ends the current one.
const STEP_SEC: float = 1.0
const SCENE_STEP_SEC: float = 0.1
const SCENE_STEPS: int = 30
const AWAY_FROM_MOUTH: Vector2 = Vector2(150.0, 300.0)
const FOOD_COUNT: int = 3
const SECOND_FINGER: int = 1
## TouchSim ends a drag with the touch release and its mouse echo.
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
## SceneManager refuses a repeat, so `requested` alone cannot prove the scene asked once.
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
	# Connect once: the autoload outlives the test.
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


# ── the journey ──────────────────────────────────────────────────────────────


## SceneManager's loader: what the game's scene swap does, with the timelines handed
## to the test and the tray seed fixed before the scene enters the tree.
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
	await wait_frames(3)
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


## Returns the gesture, so a test can play it again.
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


# ── the diary ────────────────────────────────────────────────────────────────


## The lines this test wrote: the session file also holds every earlier test.
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


## Runs the real auditor over a copy of `lines`: the file holds only this journey.
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


# ── SC-E03-P0-22 full journey, both aspects ──────────────────────────────────


func test_full_journey_at_16_9() -> void:
	await _assert_full_journey(GeometryOracle.DESKTOP_16_9)


func test_full_journey_at_4_3() -> void:
	await _assert_full_journey(GeometryOracle.IPAD_4_3)


func test_full_journey_at_the_real_4_3_canvas() -> void:
	await _assert_full_journey(GeometryOracle.CANVAS_4_3)


func _assert_full_journey(size: Vector2i) -> void:
	await _open_casa(size)
	var door: TapButton = (stage as CasaScene).door(CareSteps.FEED)
	_deliver(door, TouchSim.tap_events(door, true))

	assert_eq(door.taps, 1, "one tap on the door")
	assert_eq(requested, [COZINHA_PATH], "the door asks for the kitchen")

	await _follow_the_request()

	assert_true(stage is KitchenScene, "the kitchen is on stage")
	assert_eq(clm.state_id(), "FEED", "entering from IDLE begins the step")
	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, size, GeometryOracle.STEP_ROOM_SPEC)
	assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])

	for index: int in range(FOOD_COUNT):
		_feed(index)
		assert_eq(_kitchen().bites, index + 1, "%s: one drag, one bite" % size)
		_finish_reactions()

	assert_eq(clm.state_id(), "BATH", "BATH is next")
	assert_eq(clm.completed_steps(), 1, "the first dot fills")
	assert_eq(requested, [COZINHA_PATH, CASA_PATH], "the Casa is requested exactly once")
	assert_eq(refused_requests, [], "nothing asked twice")

	await _follow_the_request()

	assert_true(stage is CasaScene, "back at the Casa")
	assert_eq(clm.next_step(), "BATH", "the hub now asks for the bath")
	assert_eq(sm.current_scene, CASA_PATH)
	assert_false(sm.is_busy())
	assert_eq(sm.production_swap_path, "", "T-E03-04")
	_assert_probes_clean()


# ── SC-E03-P0-23 double drop (T-E03-02) ──────────────────────────────────────


func test_replaying_a_drag_on_a_consumed_food_changes_nothing() -> void:
	await _open_casa()
	await _enter_kitchen()
	var sfx_before: int = am.sfx_cursor()

	var gesture: Array[InputEvent] = _feed(0)
	_replay(0, gesture)

	assert_eq(_kitchen().bites, 1, "while she chews")
	assert_eq(_kitchen().fsm.state, "CHEWING")

	_finish_reactions()
	_replay(0, gesture)

	assert_eq(_kitchen().bites, 1, "and once she is ready again")
	assert_eq(_kitchen().fsm.state, "READY")
	assert_false(_kitchen().food(0).visible, "the eaten food stays gone")
	assert_eq(am.sfx_cursor(), sfx_before + 1, "one nhami")
	assert_eq(_diary_count("kitchen.bite"), 1)
	_assert_probes_clean()


func test_replaying_the_last_bite_credits_feed_once() -> void:
	await _open_casa()
	await _enter_kitchen()
	var sfx_before: int = am.sfx_cursor()
	_feed(0)
	_finish_reactions()
	_feed(1)
	_finish_reactions()

	var gesture: Array[InputEvent] = _feed(2)
	_replay(2, gesture)
	_finish_reactions()
	_replay(2, gesture)
	_finish_reactions()

	assert_eq(_kitchen().bites, 3)
	assert_eq(am.sfx_cursor(), sfx_before + 3, "one nhami per bite")
	assert_eq(_diary_count("care.complete"), 1, "one care.complete")
	assert_eq(loop_probe.transitions, ["IDLE->FEED", "FEED->BATH"])
	assert_eq(requested, [COZINHA_PATH, CASA_PATH])
	assert_eq(refused_requests, [])
	_assert_probes_clean()


# ── SC-E03-P1-24 miss, then eat ──────────────────────────────────────────────


func test_a_miss_returns_the_food_and_the_same_food_can_then_be_eaten() -> void:
	await _open_casa()
	await _enter_kitchen()
	var food: TouchDraggable = _kitchen().food(0)
	var rest_position: Vector2 = food.position

	_deliver(food, TouchSim.drag_events(food, AWAY_FROM_MOUTH))

	assert_eq(food.state_id(), "RETURNING")
	assert_eq(_kitchen().bites, 0, "no bite")
	assert_eq(_kitchen().fsm.state, "READY")
	assert_eq(clm.state_id(), "FEED", "no care transition")

	food.advance(TouchDraggable.RETURN_SEC)

	assert_eq(food.state_id(), "REST")
	assert_true(food.position.is_equal_approx(rest_position), "back in its place")

	_feed(0)

	assert_eq(_kitchen().bites, 1)
	assert_eq(food.state_id(), "CONSUMED")
	assert_eq(loop_probe.transitions, ["IDLE->FEED"])
	_assert_probes_clean()


# ── SC-E03-P1-25 second finger ───────────────────────────────────────────────


func test_a_second_finger_on_another_food_during_a_drag_moves_nothing() -> void:
	await _open_casa()
	await _enter_kitchen()
	var mouth: Vector2 = _kitchen().rig.mouth_global_center()
	var held: TouchDraggable = _kitchen().food(0)
	var other: TouchDraggable = _kitchen().food(1)
	var other_at: Vector2 = other.global_position
	var gesture: Array[InputEvent] = TouchSim.drag_events(held, mouth)
	var halfway: int = gesture.size() / 2

	_deliver(held, gesture.slice(0, halfway))
	var held_at: Vector2 = held.global_position
	_deliver(other, _as_finger(TouchSim.drag_events(other, mouth), SECOND_FINGER))

	assert_eq(other.state_id(), "REST", "the second finger picks up nothing")
	assert_eq(other.global_position, other_at)
	assert_eq(held.state_id(), "DRAGGING", "the first finger still holds its food")
	assert_eq(held.global_position, held_at)
	assert_eq(_kitchen().bites, 0)

	_deliver(held, gesture.slice(halfway))

	assert_eq(held.state_id(), "CONSUMED", "the first finger finishes its drag")
	assert_eq(other.state_id(), "REST")
	assert_eq(_kitchen().bites, 1)
	_assert_probes_clean()


# ── SC-E03-P1-26 second visit (T-E03-03) ─────────────────────────────────────


func test_feeding_again_after_feed_keeps_the_loop_in_bath() -> void:
	await _open_casa()
	await _enter_kitchen()
	_feed_all()
	await _follow_the_request()
	var transitions_after_first_visit: Array[String] = loop_probe.transitions.duplicate()

	await _enter_kitchen()

	assert_true(stage is KitchenScene, "the door stays open after FEED")
	assert_eq(clm.state_id(), "BATH", "entering credits nothing")

	_feed_all()

	assert_eq(_kitchen().bites, 3, "she still eats")
	assert_eq(clm.state_id(), "BATH")
	assert_eq(clm.completed_steps(), 1)

	await _follow_the_request()

	assert_true(stage is CasaScene)
	assert_eq(loop_probe.transitions, transitions_after_first_visit, "the second visit walks nothing")
	assert_eq(requested, [COZINHA_PATH, CASA_PATH, COZINHA_PATH, CASA_PATH])
	assert_eq(refused_requests, [])
	assert_eq(kitchen_probes.size(), 2, "two visits, two machines")
	_assert_probes_clean()


# ── probes and diary across the journey ──────────────────────────────────────


func test_the_journey_leaves_a_clean_diary() -> void:
	await _open_casa()
	await _enter_kitchen()
	_feed_all()
	await _follow_the_request()
	await _enter_kitchen()
	_feed_all()
	await _follow_the_request()

	assert_eq(_diary_count("kitchen.bite"), 6, "the diary saw both visits")
	assert_eq(_diary_count("fsm.illegal_transition"), 0)
	assert_eq(_diary_count("fsm.stale_transition"), 0)
	assert_eq(_diary_count("fsm.dwell_timeout"), 0)
	_assert_probes_clean()
	var lines: PackedStringArray = _diary_lines()
	assert_eq(_audit_exit_code(lines), 0, "logs.sh audit passes every line")
	lines.append(BAD_DIARY_LINE)
	assert_ne(_audit_exit_code(lines), 0, "the same audit fails a bad line")
