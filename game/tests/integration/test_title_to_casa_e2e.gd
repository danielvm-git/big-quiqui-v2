# story: e02s04
extends GutTest
## SC-E02-P0-11/12 — the payoff of the e01 guard: with casa.tscn present, one
## echo-filtered tap on Play drives the real SceneManager from titulo to casa
## through its whole declared machine, and the destination scene is playable on
## both aspects.

const CASA_PATH: String = "res://scenes/casa.tscn"
const TITULO_PATH: String = "res://scenes/titulo.tscn"

var sm: Node = null
var requested: Array[String] = []
var changed: Array[String] = []
var loaded_by_injected_loader: Array[String] = []


func before_all() -> void:
	sm = get_node_or_null("/root/SceneManager")
	assert_not_null(sm, "SceneManager must be an autoload")
	sm.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	sm.scene_changed.connect(func(path: String) -> void: changed.append(path))


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/AudioManager").reset()
	requested = []
	changed = []
	loaded_by_injected_loader = []


func after_each() -> void:
	sm.loader = Callable()
	sm.manual_step = false


func _mount(path: String, size: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)

	var packed: PackedScene = load(path) as PackedScene
	assert_not_null(packed, "%s must load" % path)
	var instance: Node = packed.instantiate()
	viewport.add_child(instance)
	return instance as Control


func _drive_to_idle(seconds: float = 3.0) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds and sm.is_busy():
		sm.advance(0.1)
		elapsed += 0.1


# SC-E02-P0-11
func test_one_play_tap_drives_the_full_transition_to_casa() -> void:
	var stage: TituloScene = _mount(TITULO_PATH, GeometryOracle.DESKTOP_16_9) as TituloScene
	await wait_frames(3)
	var probe: FsmProbe = FsmProbe.new().attach(sm.fsm)

	# Deterministic navigation: the test owns SceneManager's timeline.
	sm.manual_step = true
	sm.loader = func(path: String) -> void: loaded_by_injected_loader.append(path)

	for event: InputEvent in TouchSim.tap_events(stage.play_button, true):
		stage.play_button._gui_input(event)

	assert_eq(stage.play_presses, 1, "one tap despite the mouse echo")
	assert_eq(requested, [CASA_PATH], "Play asks for casa the moment it exists")

	_drive_to_idle()

	assert_true(probe.is_clean(), "the transition is fully legal: %s" % probe.summary())
	assert_eq(loaded_by_injected_loader, [CASA_PATH], "the swap sees casa.tscn")
	assert_eq(changed, [CASA_PATH], "scene_changed fires for casa")
	assert_eq(sm.fsm.state, "IDLE", "the machine parks after the swap")
	probe.detach()

	stage.get_parent().queue_free()


# SC-E02-P0-12 — the destination of the transition is a playable scene
func test_the_navigation_target_passes_the_geometry_oracle_on_both_aspects() -> void:
	for size: Vector2i in GeometryOracle.ASPECTS:
		var stage: Control = _mount(CASA_PATH, size)
		await wait_frames(3)

		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(stage, size)
		assert_true(findings.is_empty(), "%dx%d: %s" % [size.x, size.y, oracle.summary()])

		stage.get_parent().queue_free()
