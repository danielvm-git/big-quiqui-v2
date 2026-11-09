# story: e11s03
# story: e14s05
extends PlayerTestCase
## INV-10 — no control the child must find may be drawn behind the hero (BUG-060).

const BURIAL_THRESHOLD: float = 0.10
const ASPECTS: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(2048, 1536),
]
const ALLOWED: Dictionary = {
	"closet_door": "wide closet tray scroll; door is off-canvas until the parent pans",
	"tab_accessory": "closet tabs scroll off-screen beside the accessory rail",
	"LanePad": "full-width lane track, readable through her feet",
}
const ALLOWED_PREFIXES: Array[String] = ["Item", "tab_"]


func test_no_scene_buries_a_control_under_the_hero() -> void:
	var findings: Array[String] = []
	for scene_id: String in SceneCatalog.all_shipped_ids():
		var def: SceneDef = SceneDefLoader.load_by_id(scene_id)
		for size: Vector2i in ASPECTS:
			var player: ScenePlayer = await mount(def, size)
			findings.append_array(_audit_player(player, size, scene_id))
			player.queue_free()
	assert_eq(findings, [] as Array[String], "a child cannot tap what she cannot see")


func test_the_gate_can_fail() -> void:
	var scene: Control = Control.new()
	scene.name = "Broken"
	scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(scene)
	var rig: Control = Control.new()
	rig.name = "QuiQuiRig"
	rig.add_to_group(GeometryOracle.RIG_GROUP, false)
	rig.mouse_filter = Control.MOUSE_FILTER_STOP
	rig.size = Vector2(400.0, 600.0)
	rig.position = Vector2(700.0, 200.0)
	scene.add_child(rig)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.z_index = 50
	rig.add_child(sprite)
	var button: Control = Control.new()
	button.name = "PlayButton"
	button.add_to_group(GeometryOracle.HIT_GROUP, false)
	button.size = Vector2(168.0, 168.0)
	button.position = Vector2(716.0, 600.0)
	scene.add_child(button)

	var findings: Array[String] = _buried(scene, Rect2(700.0, 200.0, 400.0, 600.0))
	assert_gt(findings.size(), 0, "a control at z 0 under a z 50 sprite is buried")
	assert_true(findings[0].contains("PlayButton"), findings[0])


func _audit_player(player: ScenePlayer, size: Vector2i, scene_id: String) -> Array[String]:
	var rig: Control = _rig_of(player)
	if rig == null:
		return [] as Array[String]
	return _buried(player, _painted(rig), scene_id, size)


func _buried(root: Node, painted: Rect2, scene_id: String = "", size: Vector2i = Vector2i.ZERO) -> Array[String]:
	var findings: Array[String] = []
	var top_z: int = _max_rig_z(root)
	var tray: Node = root.find_child("TrayZone", true, false)
	for node: Node in root.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if not control.is_in_group(GeometryOracle.HIT_GROUP) or not control.is_visible_in_tree():
			continue
		if tray != null and tray.is_ancestor_of(control):
			continue
		if scene_id == "village" and control.name.ends_with("_door"):
			continue
		var rect: Rect2 = control.get_global_rect()
		var burial: float = rect.intersection(painted).get_area() / maxf(rect.get_area(), 1.0)
		if burial < BURIAL_THRESHOLD or control.z_index > top_z:
			continue
		if ALLOWED.has(control.name):
			continue
		var prefixed: bool = false
		for prefix: String in ALLOWED_PREFIXES:
			if control.name.begins_with(prefix):
				prefixed = true
				break
		if prefixed:
			continue
		findings.append(
			(
				"%s @%s: %s is %.0f%% under the hero (z %d <= %d)"
				% [scene_id, size, control.name, burial * 100.0, control.z_index, top_z]
			)
		)
	return findings


func _rig_of(root: Node) -> Control:
	for node: Node in root.find_children("*", "Control", true, false):
		if (node as Control).is_in_group(GeometryOracle.RIG_GROUP):
			return node as Control
	return null


func _painted(rig: Control) -> Rect2:
	if not rig.has_method("get_visual_global_rect"):
		return rig.get_global_rect()
	return rig.call("get_visual_global_rect") as Rect2


func _max_rig_z(root: Node) -> int:
	var top: int = 0
	var rig: Control = _rig_of(root)
	if rig == null:
		return 0
	for node: Node in rig.find_children("*", "Node2D", true, false):
		top = maxi(top, (node as Node2D).z_index)
	return top
