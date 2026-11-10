# story: e14s02
extends PlayerTestCase
## SC-e14s02-P0-03 — recycling pays once per session on the player.


func before_each() -> void:
	TestReset.reset_all()


func test_recycle_pays_one_coin_once_on_the_player() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("village")
	var player: ScenePlayer = await mount(def)
	await _finish_map(player)
	var progress: Node = get_node("/root/ProgressManager")
	assert_eq(int(progress.call("get_coins")), 0)
	var bag: TouchDraggable = _recycle_bag(player)
	var bin: Control = player.find_child("RecycleBin", true, false) as Control
	assert_not_null(bag)
	assert_not_null(bin)
	var to: Vector2 = bin.get_global_rect().get_center()
	send(bag, touch(bag.get_global_rect().get_center(), true))
	send(bag, drag(to))
	send(bag, touch(to, false))
	for _tick: int in range(8):
		player.advance(0.15)
	await wait_process_frames(2)
	assert_eq(int(progress.call("get_coins")), 1)
	var again: TouchDraggable = _recycle_bag(player)
	if again != null and again.enabled:
		send(again, touch(again.get_global_rect().get_center(), true))
		send(again, drag(to))
		send(again, touch(to, false))
		for _tick: int in range(6):
			player.advance(0.15)
	assert_eq(int(progress.call("get_coins")), 1)


func _finish_map(player: ScenePlayer) -> void:
	var pad: TouchPad = player.get_node("MapPad") as TouchPad
	var start: Vector2 = Vector2(120.0, 200.0)
	send(pad, touch(start, true))
	send(pad, drag(start + Vector2(80.0, 0.0)))
	send(pad, touch(start + Vector2(80.0, 0.0), false))
	for _tick: int in range(12):
		player.advance(0.2)
	await wait_process_frames(3)
	assert_eq(player.runner.step_index, 1, "recycle step is live")


func _recycle_bag(player: ScenePlayer) -> TouchDraggable:
	for child: Node in player.get_node("TrayZone").get_children():
		if child is TouchDraggable and not child.is_queued_for_deletion():
			return child as TouchDraggable
	return null
