# story: e14s03
class_name ChildCanPlayVillageFlows
extends RefCounted
## Village-room play scripts for the child-can-play gate — split to honor the 300-line bar.


static func play_market(case: PlayerTestCase, player: ScenePlayer) -> void:
	var progress: Node = case.get_node("/root/ProgressManager")
	progress.call("add_coins", 100)
	for tap: TapButton in case.tray_taps(player):
		case.finger_tap(player, tap)
		player.advance(0.1)
	await case._settle(player)


static func play_playhouse(case: PlayerTestCase, player: ScenePlayer) -> void:
	var progress: Node = case.get_node("/root/ProgressManager")
	progress.call("add_coins", 100)
	for fid: String in ["cadeira", "mesa", "tapete", "abajur", "vaso_planta"]:
		progress.call("buy_furniture", fid, 1)
	for _place: int in range(5):
		var piece: TapButton = first_dress_tap(player.get_node("TrayZone/DressStrip"))
		if piece != null:
			case.finger_tap(player, piece)
		player.advance(0.2)
	await case._settle(player)


static func play_bear(case: PlayerTestCase, player: ScenePlayer) -> void:
	for slot_index: int in range(4):
		var recv: Control = player.get_node_or_null("slot_%d" % slot_index) as Control
		if recv == null:
			recv = player.find_child("slot_%d" % slot_index, true, false) as Control
		var items: Array[TouchDraggable] = player.template_draggables()
		if recv == null or items.is_empty():
			continue
		var item: TouchDraggable = items[0]
		var to: Vector2 = recv.get_global_rect().get_center()
		case.send(item, case.touch(item.get_global_rect().get_center(), true))
		case.send(item, case.drag(to))
		case.send(item, case.touch(to, false))
		for _tick: int in range(6):
			player.advance(0.2)
	await case._settle(player)


static func play_duck(case: PlayerTestCase, player: ScenePlayer) -> void:
	for _round: int in range(6):
		var tpl: RefCounted = player.get("_template") as RefCounted
		if tpl == null:
			break
		var pose: String = str(tpl.call("pose_id"))
		for pad_name: String in ["left", "centre", "right"]:
			var pad: TapButton = player.find_child(pad_name, true, false) as TapButton
			if pad != null and pad_name == pose:
				case.finger_tap(player, pad)
				break
		for _tick: int in range(4):
			player.advance(0.2)
		if player.runner.template_progress() >= 1.0:
			break
	await case._settle(player)


static func play_album(case: PlayerTestCase, player: ScenePlayer) -> void:
	for tap: TapButton in case.tray_taps(player):
		case.finger_tap(player, tap)
	await case._settle(player)


static func play_party(case: PlayerTestCase, player: ScenePlayer) -> void:
	for tap: TapButton in case.tray_taps(player):
		case.finger_tap(player, tap)
		player.advance(0.1)
	await case._settle(player)


static func play_village(case: PlayerTestCase, player: ScenePlayer) -> void:
	var pad: TouchPad = player.get_node("MapPad") as TouchPad
	var start: Vector2 = Vector2(120.0, 200.0)
	case.send(pad, case.touch(start, true))
	case.send(pad, case.drag(start + Vector2(80.0, 0.0)))
	case.send(pad, case.touch(start + Vector2(80.0, 0.0), false))
	for _tick: int in range(16):
		player.advance(0.2)
	await case.wait_process_frames(3)
	if VilaScene.recycled_this_session or player.runner.step_index >= player.loaded_def.steps.size():
		await case._settle(player)
		return
	var bag: TouchDraggable = case.rub_tool(player)
	var bin: Control = player.find_child("RecycleBin", true, false) as Control
	if bag == null:
		await case._settle(player)
		return
	var to: Vector2 = bin.get_global_rect().get_center()
	case.send(bag, case.touch(bag.get_global_rect().get_center(), true))
	case.send(bag, case.drag(to))
	case.send(bag, case.touch(to, false))
	await case._settle(player)


static func first_dress_tap(strip: Control) -> TapButton:
	var found: Array[TapButton] = []
	_collect_taps(strip, found)
	for button: TapButton in found:
		if not button.visible or button.name.begins_with("tab_"):
			continue
		return button
	return null


static func _collect_taps(node: Node, into: Array[TapButton]) -> void:
	for child: Node in node.get_children():
		if child is TapButton and child.is_in_group("hit_target"):
			into.append(child as TapButton)
		_collect_taps(child, into)
