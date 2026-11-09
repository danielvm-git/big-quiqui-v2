# story: e13s01
# story: e13s02
# story: e13s05
class_name TemplateKit
extends RefCounted
## Helpers every template shares, so the context stays the one door to the player and the
## templates stop repeating the same reaction batch, hull lookup and autoload fetch.

const HELD_META: String = "template_kit_filter"
## QuiQui's sprites draw at z 0..50 (`QuiQuiRig.Z_*`), whatever the tree order says. Rub layers draw above her
## and every tap target, tool and pad layer a template builds draws above them, so what a finger can reach is
## also what the child can see.
const LAYER_Z: int = QuiQuiRig.Z_GLASSES + 10
const SURFACE_Z: int = QuiQuiRig.Z_GLASSES + 50


static func autoload(node_name: String) -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(node_name)


static func mode_or(ctx: TemplateContext, fallback: String) -> String:
	if ctx == null or ctx.step_def == null or ctx.step_def.mode.is_empty():
		return fallback
	return ctx.step_def.mode


static func hull_target(ctx: TemplateContext) -> Control:
	if ctx == null:
		return null
	if ctx.nodes != null:
		var named: Control = ctx.nodes.resolve("scrub_target")
		if named != null:
			return named
	return ctx.rig


## `index` picks the item's own pose from `hit_poses`; -1 or an empty entry uses `on_hit_pose`.
static func play_hit(ctx: TemplateContext, diary_ev: String, data: Dictionary, index: int = -1) -> void:
	if ctx == null or ctx.reactions == null or ctx.step_def == null:
		return
	var batch: Array = []
	var pose: String = pose_for(ctx.step_def, index)
	if not pose.is_empty():
		batch.append({"kind": ReactionExecutor.KIND_POSE, "id": pose})
	if not ctx.step_def.on_hit_sfx_id.is_empty():
		batch.append({"kind": ReactionExecutor.KIND_SFX, "id": ctx.step_def.on_hit_sfx_id})
	ctx.reactions.execute(batch)
	LogSink.emit_to_diary(diary_ev, data)


static func pose_for(step: StepDef, index: int) -> String:
	if index >= 0 and index < step.hit_poses.size() and not step.hit_poses[index].is_empty():
		return step.hit_poses[index]
	return step.on_hit_pose


static func play_miss(ctx: TemplateContext) -> void:
	if ctx == null or ctx.reactions == null or ctx.step_def == null:
		return
	var sfx: String = ctx.step_def.on_miss_sfx_id
	if sfx.is_empty():
		return
	ctx.reactions.execute([{"kind": ReactionExecutor.KIND_SFX, "id": sfx}])


## A tap target with the picture of `art_id`. The art sits on `Visual`, so the squash moves the
## picture and never the 120 px hit rect.
static func tap_button(art_id: String, at: Vector2) -> TapButton:
	var button: TapButton = TapButton.new()
	button.name = art_id
	button.size = TapButton.MIN_HIT_SIZE
	button.position = at
	button.add_to_group("hit_target", true)
	button.z_index = SURFACE_Z
	var visual: Control = Control.new()
	visual.name = "Visual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual.add_child(ItemArt.icon(art_id, TapButton.MIN_HIT_SIZE.x))
	button.visual = visual
	button.add_child(visual)
	return button


## QuiQui stops touches. A template whose pad covers the stage lets them through while it is mounted
## and hands back the old filter to restore. Returns -1 when there was no rig to quiet.
static func quiet_rig(ctx: TemplateContext) -> int:
	if ctx == null or ctx.rig == null:
		return -1
	var before: int = ctx.rig.mouse_filter
	ctx.rig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return before


static func restore_rig(ctx: TemplateContext, before: int) -> void:
	if ctx != null and ctx.rig != null and is_instance_valid(ctx.rig) and before >= 0:
		ctx.rig.mouse_filter = before as Control.MouseFilter


## While a gesture owns the screen the other tray children ignore touches. They stay visible.
static func hold_tray(tray: Control, keep: Control) -> void:
	if tray == null:
		return
	for child: Node in tray.get_children():
		if not child is Control or child == keep or child.has_meta(HELD_META):
			continue
		child.set_meta(HELD_META, (child as Control).mouse_filter)
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


static func release_tray(tray: Control) -> void:
	if tray == null:
		return
	for child: Node in tray.get_children():
		if child is Control and child.has_meta(HELD_META):
			(child as Control).mouse_filter = int(child.get_meta(HELD_META)) as Control.MouseFilter
			child.remove_meta(HELD_META)


## Puts a touch pad and the layer it moves just above the backdrop, below every button the player owns,
## and wires the pad to the three handlers. One place for the order every pad template needs.
static func mount_pad(host: Control, pad: TouchPad, layer: Control, handlers: Array[Callable]) -> void:
	var backdrop: Node = host.get_node_or_null("Background")
	var slot: int = 0 if backdrop == null else backdrop.get_index() + 1
	host.add_child(pad)
	host.add_child(layer)
	host.move_child(pad, slot)
	host.move_child(layer, slot + 1)
	pad.pressed.connect(handlers[0])
	pad.moved.connect(handlers[1])
	pad.released.connect(handlers[2])
