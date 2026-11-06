# story: e02s03
extends SceneTree


# Headless measurement probe: box vs painted rect on both shipped scenes.
func _initialize() -> void:
	_go()


func _go() -> void:
	var root: Node = get_root()
	for scene_path: String in ["res://scenes/casa.tscn", "res://scenes/titulo.tscn", "res://scenes/cozinha.tscn"]:
		for vp: Vector2i in [Vector2i(1920, 1080), Vector2i(1920, 1440), Vector2i(2048, 1536)]:
			await _measure(root, scene_path, vp)
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null:
		audio.call("reset")
	quit(0)


func _measure(root: Node, scene_path: String, vp: Vector2i) -> void:
	var holder: SubViewport = SubViewport.new()
	holder.size = vp
	holder.disable_3d = true
	holder.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(holder)
	var inst: Control = (load(scene_path) as PackedScene).instantiate() as Control
	holder.add_child(inst)
	for _i: int in range(3):
		await process_frame
	var rig: Control = inst.get_node_or_null("QuiQuiRig") as Control
	rig.set("manual_step", true)
	(rig.get("pivot") as Node2D).scale = Vector2.ONE
	rig.call("_refit")
	_print_row(scene_path, vp, rig.get_global_rect(), rig.call("get_visual_global_rect") as Rect2)
	holder.free()


func _print_row(scene_path: String, vp: Vector2i, box: Rect2, painted: Rect2) -> void:
	var h: float = float(vp.y)
	var fmt: String = "%s %dx%d box_h=%.3f box_feet=%.3f painted_h=%.3f painted_feet=%.3f"
	print(
		fmt % [scene_path.get_file(), vp.x, vp.y, box.size.y / h, box.end.y / h, painted.size.y / h, painted.end.y / h]
	)
