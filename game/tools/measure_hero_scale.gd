# story: e02s03
# story: e14s05
extends SceneTree


func _initialize() -> void:
	_go()


func _go() -> void:
	var root: Node = get_root()
	var ids: PackedStringArray = PackedStringArray(["home", "title", "kitchen"])
	for scene_id: String in ids:
		for vp: Vector2i in [Vector2i(1920, 1080), Vector2i(1920, 1440), Vector2i(2048, 1536)]:
			await _measure(root, scene_id, vp)
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null:
		audio.call("reset")
	quit(0)


func _measure(root: Node, scene_id: String, vp: Vector2i) -> void:
	var holder: SubViewport = SubViewport.new()
	holder.size = vp
	holder.disable_3d = true
	holder.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(holder)
	var packed: PackedScene = load("res://scenes/scene_player.tscn") as PackedScene
	var inst: ScenePlayer = packed.instantiate() as ScenePlayer
	inst.manual_step = true
	inst.def_override = SceneDefLoader.load_by_id(scene_id)
	holder.add_child(inst)
	for _i: int in range(10):
		await process_frame
	var rig: Control = inst.get_node_or_null("QuiQuiRig") as Control
	if rig == null:
		print("%s %s rig missing" % [scene_id, vp])
		holder.queue_free()
		return
	var box: Rect2 = rig.get_global_rect()
	var painted: Rect2 = rig.call("get_visual_global_rect") as Rect2
	var canvas_h: float = float(vp.y)
	var box_h: float = box.size.y / canvas_h
	var painted_h: float = painted.size.y / canvas_h
	var feet: float = (painted.end.y) / canvas_h
	print("%s %s box_h=%.3f painted_h=%.3f feet=%.3f" % [scene_id, vp, box_h, painted_h, feet])
	holder.queue_free()
