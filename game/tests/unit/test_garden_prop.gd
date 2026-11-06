# story: e06s01
extends GutTest
## A garden toy moves when tapped and then rests. The rest state is the contract: a
## prop that never settles is a screen a child cannot leave calmly (T-E06-04).

var hits: Array[String] = []


func before_each() -> void:
	hits = []


func _prop(kind: GardenProp.Kind, interaction: String) -> GardenProp:
	var prop: GardenProp = GardenProp.new()
	prop.kind = kind
	prop.interaction = interaction
	prop.size = Vector2(148.0, 148.0)
	add_child_autofree(prop)
	prop.interacted.connect(func(id: String) -> void: hits.append(id))
	return prop


func _tap(prop: GardenProp) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.position = prop.get_global_rect().get_center()
	touch.pressed = true
	prop._gui_input(touch)


func test_a_fresh_prop_is_at_rest() -> void:
	for kind: GardenProp.Kind in [GardenProp.Kind.BOUNCE, GardenProp.Kind.SPIN, GardenProp.Kind.SQUEEZE]:
		var prop: GardenProp = _prop(kind, "x")
		assert_true(prop.is_idle(), "kind %d starts at rest" % kind)


func test_a_tap_starts_the_motion_and_reports_the_interaction() -> void:
	var prop: GardenProp = _prop(GardenProp.Kind.BOUNCE, "ball")

	_tap(prop)

	assert_false(prop.is_idle(), "the ball moved")
	assert_eq(hits, ["ball"], "and reported which toy was played with")


func test_every_motion_settles_within_its_budget() -> void:
	var cases: Array[Array] = [
		[GardenProp.Kind.BOUNCE, "ball", GardenProp.BOUNCE_SEC],
		[GardenProp.Kind.SPIN, "pinwheel", GardenProp.SPIN_SEC],
		[GardenProp.Kind.SQUEEZE, "plush", GardenProp.SQUEEZE_SEC],
	]
	for entry: Array in cases:
		var prop: GardenProp = _prop(entry[0] as GardenProp.Kind, str(entry[1]))
		var budget: float = float(entry[2])
		prop.trigger()
		prop.advance(budget * 0.5)
		assert_false(prop.is_idle(), "%s is still moving halfway" % entry[1])
		prop.advance(budget)
		assert_true(prop.is_idle(), "%s settled inside its budget" % entry[1])
		assert_eq(prop.rotation, 0.0, "%s ends unrotated" % entry[1])
		assert_eq(prop.scale, Vector2.ONE, "%s ends unscaled" % entry[1])


func test_a_resting_prop_does_not_drift_when_advanced() -> void:
	var prop: GardenProp = _prop(GardenProp.Kind.BOUNCE, "ball")
	var home: Vector2 = prop.position

	prop.advance(5.0)

	assert_eq(prop.position, home, "advancing an idle prop is a no-op")


func test_the_mouse_echo_does_not_double_fire() -> void:
	var prop: GardenProp = _prop(GardenProp.Kind.SPIN, "pinwheel")
	var echo: InputEventMouseButton = InputEventMouseButton.new()
	echo.device = -1
	echo.button_index = MOUSE_BUTTON_LEFT
	echo.pressed = true
	echo.position = prop.get_global_rect().get_center()

	prop._gui_input(echo)

	assert_eq(hits, [], "the synthesized mouse echo is ignored")
	assert_true(prop.is_idle())


func test_a_retap_re_aims_the_motion_without_stacking() -> void:
	var prop: GardenProp = _prop(GardenProp.Kind.BOUNCE, "ball")
	prop.trigger()
	prop.advance(GardenProp.BOUNCE_SEC * 0.9)

	prop.trigger()

	assert_false(prop.is_idle(), "still moving")
	prop.advance(GardenProp.BOUNCE_SEC)
	assert_true(prop.is_idle(), "and still settles in one budget, not two")
	assert_eq(hits.size(), 2, "two taps, two reports")
