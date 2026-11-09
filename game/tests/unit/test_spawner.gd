# story: e13s08
extends GutTest
## SC-e13s08-P0-02, P2-01. The same seed replays. A second caller uses it as-is.


func test_the_same_seed_replays() -> void:
	var first: PackedStringArray = _run(4)
	var second: PackedStringArray = _run(4)
	assert_eq(first, second, "SC-e13s08-P0-02")
	assert_gt(first.size(), 0)


func test_a_second_consumer_uses_the_same_spawner() -> void:
	var stub: Spawner = Spawner.new()
	stub.rng_seed = 9
	stub.items = PackedStringArray(["cup"])
	stub.cadence = 1
	stub.lifetime = 3
	stub.lane_count = 1
	stub.start()
	stub.tick()
	assert_eq(stub.live_count(), 1, "SC-e13s08-P2-01")
	assert_eq(stub.first_lane(), 0)
	stub.stop()
	assert_eq(stub.live_count(), 0)


func test_live_rows_report_age_and_misses_are_read_only() -> void:
	var spawner: Spawner = Spawner.new()
	spawner.rng_seed = 2
	spawner.items = PackedStringArray(["cup"])
	spawner.cadence = 1
	spawner.lifetime = 2
	spawner.lane_count = 1
	spawner.start()
	spawner.tick()
	spawner.tick()
	var rows: Array[Dictionary] = spawner.live_rows()
	assert_eq(rows.size(), 2)
	assert_eq(int(rows[0]["age"]), 1, "the first row has aged one tick")
	rows[0]["age"] = 99
	assert_eq(int(spawner.live_rows()[0]["age"]), 1, "the rows are copies")
	spawner.tick()
	spawner.tick()
	assert_gt(spawner.misses(), 0, "a row that ran out of life is a quiet miss")


func _run(seed_value: int) -> PackedStringArray:
	var spawner: Spawner = Spawner.new()
	spawner.rng_seed = seed_value
	spawner.items = PackedStringArray(["fish", "berry"])
	spawner.cadence = 1
	spawner.lifetime = 5
	spawner.lane_count = 3
	spawner.start()
	for _i: int in range(12):
		spawner.tick()
	return spawner.sequence()
