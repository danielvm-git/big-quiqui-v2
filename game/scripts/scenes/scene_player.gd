# story: e12s02
# story: e12s03
class_name ScenePlayer
extends Control
## Data-scene host: chrome, StepRunner, templates, hints.

var def_override: SceneDef = null
var loaded_def: SceneDef = null
var manual_step: bool = false

var runner: StepRunner = null
var _reactions: ReactionExecutor = null
var _hint: HintLayer = null
var _nodes: PlayerNodeTable = null
var _template: RefCounted = null
var _exited: bool = false
var _booted: bool = false
var _fsm_prev: String = ""
var _active_step: int = -1
var _step_credited: bool = false

@onready var _rig: QuiQuiRig = get_node_or_null("QuiQuiRig") as QuiQuiRig
@onready var _tray: Control = get_node_or_null("TrayZone") as Control
@onready var _dots: CareDotsBar = get_node_or_null("StepDots") as CareDotsBar
@onready var _home: TapButton = get_node_or_null("HomeButton") as TapButton
@onready var _hint_mgr: HintManager = get_node_or_null("HintManager") as HintManager
@onready var _drag_hint: DragHint = get_node_or_null("DragHint") as DragHint


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	runner = StepRunner.new()
	runner.manual_step = manual_step
	_reactions = ReactionExecutor.new()
	_hint = HintLayer.new()
	_nodes = PlayerNodeTable.new()
	_wire_buttons()
	call_deferred("boot_from_manager")


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	if runner == null:
		return
	runner.advance(delta)
	_tick_template(delta)
	_tick_hint(delta)
	_sync_fsm()
	_sync_dots()


func boot_from_manager() -> void:
	if _booted:
		return
	var def: SceneDef = _load_def()
	if def == null:
		return
	_booted = true
	loaded_def = def
	_apply_media(def)
	_register_nodes()
	runner.reset(def.steps.size())
	_fsm_prev = runner.fsm.state
	LogSink.emit_from(self, "scene.loaded", {"scene": "scene.%s" % def.id})
	_maybe_begin_care()
	runner.fsm.transition_to(StepRunner.STATE_INTRO)
	runner.finish_intro()
	_sync_fsm()
	_fsm_prev = runner.fsm.state


func _maybe_begin_care() -> void:
	var clm: Node = _care_loop()
	if clm == null or str(clm.call("state_id")) != CareSteps.IDLE:
		return
	var step: StepDef = loaded_def.steps[0] as StepDef
	if step.care_step_id == CareSteps.FEED and clm.has_method("begin_step"):
		clm.call("begin_step", CareSteps.FEED)


func _load_def() -> SceneDef:
	if def_override != null:
		return SceneDefLoader.validate(def_override)
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null and manager.has_method("consume_def"):
		var consumed: SceneDef = manager.call("consume_def") as SceneDef
		if consumed != null:
			return SceneDefLoader.validate(consumed)
	return null


func _apply_media(def: SceneDef) -> void:
	_apply_background(def.background_id)
	if not def.music_id.is_empty():
		var path: String = SceneMedia.music_path(def.music_id)
		if ResourceLoader.exists(path):
			var audio: Node = get_node_or_null("/root/AudioManager")
			if audio != null and audio.has_method("play_music"):
				audio.call("play_music", load(path) as AudioStream)
	if not def.intro_voice_key.is_empty():
		VoicePlayback.play_key(self, def.intro_voice_key)


func _apply_background(background_id: String) -> void:
	var path: String = SceneMedia.background_path(background_id)
	var node: TextureRect = get_node_or_null("Background") as TextureRect
	if node == null or path.is_empty():
		return
	node.texture = load(path) as Texture2D


func _wire_buttons() -> void:
	if _home != null:
		_home.tapped.connect(_on_home)
	if _rig != null:
		_rig.tapped.connect(_note_input)


func _on_home() -> void:
	_note_input()
	if runner == null:
		return
	runner.request_home()
	_exit_room()


func _exit_room() -> void:
	if _exited:
		return
	_exited = true
	_teardown_template()
	LogSink.emit_from(self, "scene.exited", {"scene": _scene_slug()})
	var target: String = "home"
	if loaded_def != null and not loaded_def.next_scene_id.is_empty():
		target = loaded_def.next_scene_id
	SceneNav.open(get_node_or_null("/root/SceneManager"), target)


func _sync_fsm() -> void:
	var state: String = runner.fsm.state
	if state == StepRunner.STATE_STEP and _active_step != runner.step_index:
		_begin_step(runner.step_index)
	if _fsm_prev == StepRunner.STATE_STEP and state != StepRunner.STATE_STEP and state != StepRunner.STATE_EXIT:
		_on_step_completed(_active_step)
	if state == StepRunner.STATE_EXIT:
		_exit_room()
	_fsm_prev = state


func _begin_step(index: int) -> void:
	if loaded_def == null or index < 0 or index >= loaded_def.steps.size():
		return
	_ensure_step_nodes()
	_active_step = index
	_step_credited = false
	_teardown_template()
	var step: StepDef = loaded_def.steps[index] as StepDef
	LogSink.emit_from(self, "step.started", {"index": index})
	_reactions.bind(self, _rig)
	_mount_template(step)


func _ensure_step_nodes() -> void:
	if _tray == null:
		_tray = get_node_or_null("TrayZone") as Control
	if _rig == null:
		_rig = get_node_or_null("QuiQuiRig") as QuiQuiRig


func _mount_template(step: StepDef) -> void:
	var ctx: TemplateContext = TemplateContext.new()
	ctx.host = self
	ctx.rig = _rig
	ctx.tray = _tray
	ctx.reactions = _reactions
	ctx.runner = runner
	ctx.nodes = _nodes
	ctx.step_def = step
	_template = TemplateCatalog.instantiate(step.template_id)
	if _template != null and _template.has_method("setup"):
		_template.call("setup", ctx)
	if _hint != null and _hint_mgr != null and _drag_hint != null:
		_hint.bind(_hint_mgr, _drag_hint, _nodes)
		_hint.begin_step(step)


func _on_step_completed(index: int) -> void:
	if _step_credited or loaded_def == null or index < 0 or index >= loaded_def.steps.size():
		return
	_step_credited = true
	LogSink.emit_from(self, "step.done", {"index": index})
	var step: StepDef = loaded_def.steps[index] as StepDef
	if not step.care_step_id.is_empty():
		var clm: Node = _care_loop()
		if clm != null and clm.has_method("complete_step"):
			clm.call("complete_step", step.care_step_id)


func _tick_template(delta: float) -> void:
	if _template == null or runner.fsm.state != StepRunner.STATE_STEP:
		return
	if _active_step != runner.step_index:
		return  # the runner moved on; the mounted template still belongs to the step before
	if _template.has_method("advance"):
		_template.call("advance", delta)
	if _template.has_method("progress"):
		runner.report_template_progress(float(_template.call("progress")))
	if runner.template_progress() >= 1.0 and not _step_credited:
		_on_step_completed(_active_step)


func _tick_hint(delta: float) -> void:
	if _hint == null or _hint_mgr == null:
		return
	runner.idle_sec = _hint.idle_sec
	_hint.advance(delta)
	_hint_mgr.advance(delta)


func _note_input() -> void:
	if runner != null:
		runner.note_input()
	if _hint != null:
		_hint.note_input()


func _sync_dots() -> void:
	if _dots == null or loaded_def == null or runner == null:
		return
	var done: int = runner.step_index
	if runner.fsm.state == StepRunner.STATE_STEP_DONE:
		done = runner.step_index + 1
	_dots.set_step_progress(done, loaded_def.steps.size())


func _register_nodes() -> void:
	if _rig != null and _rig.mouth_zone != null:
		_nodes.register("quiqui_mouth", _rig.mouth_zone)
	if _tray != null:
		_nodes.register("tray", _tray)
	if _home != null:
		_nodes.register("home", _home)


func _teardown_template() -> void:
	if _template != null and _template.has_method("teardown"):
		_template.call("teardown")
	_template = null


func _scene_slug() -> String:
	if loaded_def == null:
		return "scene.none"
	return "scene.%s" % loaded_def.id


func _care_loop() -> Node:
	return get_node_or_null("/root/CareLoopManager")


func template_draggables() -> Array[TouchDraggable]:
	if _template != null and _template.has_method("active_draggables"):
		return _template.call("active_draggables")
	return []
