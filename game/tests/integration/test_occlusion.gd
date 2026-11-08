# story: e11s03
extends GutTest
## INV-10 — no control the child must find may be drawn behind the hero (BUG-060).
##
## The rig is layered art: its `Sprite2D` children carry `z_index` 0–50 (ADR-003, so outfits
## never hide the face). A scene-level `Control` defaults to `z_index` 0, so **the hero draws
## over it** wherever they overlap. The title screen's Play button was 95 % buried at 16:9 and
## the child had no visible way to start the game — on a Mac, not in the suite, because every
## existing assertion asked about a *rect* and none asked about *paint order*.
##
## This gate mounts every scene on both aspects and asks the question the child asks: can I
## see and reach this thing?
##
## Allowlisted overlaps are deliberate, not forgotten:
##   - `TickleZone` (jardim) is *on* her by design — tapping her is the verb.
##   - `IceLane` (pinguim) is a full-width track; it is 11–15 % under her feet and readable.
##   - `Draggable` (pinguim) is the basket she drags; its 50 % burial is **BUG-061**, open,
##     because moving it changes how the minigame plays and that is a design call.

const BURIAL_THRESHOLD: float = 0.10
const ASPECTS: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(2048, 1536),
]
const ALLOWED: Dictionary = {
	"jardim.tscn/TickleZone": "tapping the hero is the verb",
	"pinguim_jogo.tscn/IceLane": "full-width track, readable through her feet",
	"pinguim_jogo.tscn/Draggable": "BUG-061 — moving it changes how the minigame plays",
}


func test_no_scene_buries_a_control_under_the_hero() -> void:
	var findings: Array[String] = []
	for scene_path: String in SourceScanner.scenes():
		for size: Vector2i in ASPECTS:
			findings.append_array(await _audit(scene_path, size))
	assert_eq(findings, [] as Array[String], "a child cannot tap what she cannot see")


func test_the_gate_can_fail() -> void:
	## A gate that cannot fail is decoration (BUG-040's lesson): the title screen's old
	## layout is reproduced here and must be reported.
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


# ── machinery ────────────────────────────────────────────────────────────────


func _audit(scene_path: String, size: Vector2i) -> Array[String]:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var instance: Node = (load(scene_path) as PackedScene).instantiate()
	viewport.add_child(instance)
	await wait_process_frames(2)
	var findings: Array[String] = []
	var rig: Control = _rig_of(instance)
	if rig != null:
		findings = _buried(instance, _painted(rig), scene_path.get_file(), size)
	viewport.queue_free()
	return findings


func _buried(root: Node, painted: Rect2, file: String = "", size: Vector2i = Vector2i.ZERO) -> Array[String]:
	var findings: Array[String] = []
	var top_z: int = _max_rig_z(root)
	for node: Node in root.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if not control.is_in_group(GeometryOracle.HIT_GROUP) or not control.is_visible_in_tree():
			continue
		var rect: Rect2 = control.get_global_rect()
		var burial: float = rect.intersection(painted).get_area() / maxf(rect.get_area(), 1.0)
		if burial < BURIAL_THRESHOLD or control.z_index > top_z:
			continue
		var key: String = "%s/%s" % [file, control.name] if not file.is_empty() else "PlayButton"
		if ALLOWED.has(key):
			continue
		findings.append(
			(
				"%s @%s: %s is %.0f%% under the hero (z %d <= %d)"
				% [file, size, control.name, burial * 100.0, control.z_index, top_z]
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
